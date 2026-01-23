# baleia.nvim

[![Integration][integration-badge]][integration-runs]

Colorize text with ANSI escape sequences (8, 16, 256 or TrueColor).

**Requirements**: Neovim 0.9.0 or higher.


<img width="1213" height="745" alt="image" src="https://github.com/user-attachments/assets/3d581588-ecb0-48e4-b45c-533cfd06e3a9" />

## Install

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "m00qek/baleia.nvim",
  version = "*",
  config = function()
    vim.g.baleia = require("baleia").setup({ })

    -- Command to colorize the current buffer
    vim.api.nvim_create_user_command("BaleiaColorize", function()
      vim.g.baleia.once(vim.api.nvim_get_current_buf())
    end, { bang = true })

    -- Command to show logs 
    vim.api.nvim_create_user_command("BaleiaLogs", vim.cmd.messages, { bang = true })
  end,
}
```

## Usage & Configuration

Baleia exposes functions to colorize buffers. You can use them manually (commands) or automatically (autocmds).

### 1. Manual Colorization

The setup above creates a `:BaleiaColorize` command. Use this when you open a file with ANSI codes (like a log file) and want to colorize it once.

```lua
vim.g.baleia.once(vim.api.nvim_get_current_buf())
```

### 2. Automatic Colorization (Tailing Logs)

To automatically colorize lines as they are appended to a buffer (e.g., when tailing a log file), use `baleia.automatically`.

**Example: Colorize all `.log` files:**

```lua
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = "*.log",
  callback = function()
    vim.g.baleia.automatically(vim.api.nvim_get_current_buf())
  end,
})
```

**Example: Colorize Quickfix Window:**

```lua
vim.api.nvim_create_autocmd({ "BufReadPost" }, {
  pattern = "quickfix",
  callback = function()
    vim.api.nvim_set_option_value("modifiable", true, { buf = buffer })
    vim.g.baleia.automatically(vim.api.nvim_get_current_buf())
    vim.api.nvim_set_option_value("modified", false, { buf = buffer })
    vim.api.nvim_set_option_value("modifiable", false, { buf = buffer })
  end,
})
```

### Setup Options

Pass these options to `require("baleia").setup({...})`:

|      option      |  default value  |                        description                        |
| -----------------| --------------- | --------------------------------------------------------- |
| name             | "BaleiaColors"  | prefix used to name highlight groups                      |
| strip_ansi_codes | true            | remove ANSI color codes from text                         |
| line_starts_at   | 1 (one-indexed) | at which column start colorizing                          |
| colors           | [NR_8](lua/baleia/ansi.lua#L262) | table mapping 256 color codes to vim colors               |
| async            | true            | highlight asynchronously                                  |
| chunk_size       | 500             | number of lines to process per loop iteration (async)     |

## With Conjure

This can be used to colorize [Conjure][conjure] log buffer. To do it you **must**
tell conjure to not strip ANSI escape codes:

```lua
{
  "m00qek/baleia.nvim",
  version = "*",
  config = function()
    vim.g.conjure_baleia = require("baleia").setup({ line_starts_at = 3 })

    local augroup = vim.api.nvim_create_augroup("ConjureBaleia", { clear = true })

    vim.api.nvim_create_user_command("BaleiaColorize", function()
      vim.g.conjure_baleia.once(vim.api.nvim_get_current_buf())
    end, { bang = true })

    vim.api.nvim_create_user_command("BaleiaLogs", vim.cmd.messages, { bang = true })
  end,
},
{
  "Olical/conjure",
  ft = { "clojure", "fennel" },
  config = function()
    require("conjure.main").main()
    require("conjure.mapping")["on-filetype"]()
  end,
  init = function()
    -- Print color codes if baleia.nvim is available
    local colorize = require("lazyvim.util").has("baleia.nvim")
    vim.g["conjure#log#strip_ansi_escape_sequences_line_limit"] = colorize and 1 or nil

    -- Disable diagnostics in log buffer and colorize it
    vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
      pattern = "conjure-log-*",
      callback = function()
        local buffer = vim.api.nvim_get_current_buf()
        vim.diagnostic.enable(false, { bufnr = buffer })
        if colorize and vim.g.conjure_baleia then
          vim.g.conjure_baleia.automatically(buffer)
        end
      end,
    })
  end,
},
```

## Developer API

`baleia` provides two functions, `buf_set_lines` and `buf_set_text`, that have
the same interface as the default `vim.api.nvim_buf_set_lines` and
`vim.api.nvim_but_set_text`. Using those is very efficient because they do all
color detection and ANSI code stripping before writing anything to the buffer.

```lua
local new_lines = { '\x1b[32mHello \x1b[33mworld!' }

-- appending using Neovim standard API
local lastline = vim.api.nvim_buf_line_count(0)
vim.api.nvim_buf_set_lines(0, lastline, lastline, true, new_lines)

-- appending using Baleia API
local lastline = vim.api.nvim_buf_line_count(0)
local baleia = require('baleia').setup { }
baleia.buf_set_lines(0, lastline, lastline, true, new_lines)
```

[integration-badge]: https://github.com/m00qek/baleia.nvim/actions/workflows/integration.yml/badge.svg
[integration-runs]: https://github.com/m00qek/baleia.nvim/actions/workflows/integration.yml
[conjure]: https://github.com/Olical/conjure
## License

[MIT](./LICENSE)
