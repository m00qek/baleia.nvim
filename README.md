# baleia.nvim

===

[![Integration][integration-badge]][integration-runs]

Colorize text with ANSI escape sequences (8, 16, 256 or TrueColor)

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
    vim.api.nvim_create_user_command("BaleiaLogs", vim.g.baleia.logger.show, { bang = true })
  end,
}
```

## Automatically colorize when lines are added to the buffer

To automatically colorize when a new line is added use

```lua
vim.g.baleia = require("baleia").setup({ })
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
  pattern = "*.txt",
  callback = function()
    vim.g.baleia.automatically(vim.api.nvim_get_current_buf())
  end,
})
```

This will register every buffer that matches `.txt` to be automatically
colorized.

## Automatically colorize text added to the quickfix window

To automatically colorize text added to the quickfix use `BufReadPost`

```lua
vim.g.baleia = require("baleia").setup({ })
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

### Setup options

When calling the `setup` function, the following options are available:

|      option      |  default value  |                        description                        |
| -----------------| --------------- | --------------------------------------------------------- |
| name             | "BaleiaColors"  | prefix used to name highlight groups                      |
| strip_ansi_codes | true            | remove ANSI color codes from text                         |
| line_starts_at   | 1 (one-indexed) | at which column start colorizing                          |
| colors           | [NR_8][nr_8]    | table mapping 256 color codes to vim colors               |
| async            | true            | highlight asynchronously                                  |
| log              | "ERROR"         | log level, possible values are ERROR, WARN, INFO or DEBUG |

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

    vim.api.nvim_create_user_command("BaleiaLogs", vim.g.conjure_baleia.logger.show, { bang = true })
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

## What to do if something looks wrong

Enable logs with

```lua
vim.g.baleia = require("baleia").setup({ log = 'DEBUG' })
vim.api.nvim_create_user_command("BaleiaLogs", vim.g.conjure_baleia.logger.show, { bang = true })
```

You can set the log level to `ERROR`, `WARN`, `INFO` or `DEBUG`. You can see
the logs using `BaleiaLogs`.

## Developer API

`baleia` provides two functions, `buf_set_lines` and `buf_set_text`, that have
the same interface as the default `vim.api.nvim_buf_set_lines` and
`vim.api.nvim_but_set_text`. Using those is very efficient because they do all
color detection and ANSI code stripping before writing anything to the buffer.
Example:

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
[nr_8]: ./lua/baleia/styles/themes.lua
