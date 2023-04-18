baleia.nvim
===
[![Integration][integration-badge]][integration-runs]

Colorize text with ANSI escape sequences (8, 16, 256 or TrueColor)

## Install

Using [vim-plug][vim-plug]:

```vim
Plug 'm00qek/baleia.nvim', { 'tag': 'v1.3.0' }
```

Using [packer.nvim][packer]:

```lua
use { 'm00qek/baleia.nvim', tag = 'v1.3.0' }
```

## Setup

`baleia` can colorize an entire buffer or/and apply colors every time a new line
is added to it. 

### Colorizing the entire buffer

The best approach is to create a command. In `vimscript`: 

```vim
let s:baleia = luaeval("require('baleia').setup { }")
command! BaleiaColorize call s:baleia.once(bufnr('%'))
```

To highlight the current buffer:

```vim
:BaleiaColorize
```

## Automatically colorize when lines are added to the buffer

To automatically colorize when a new line is added use

```vim
let s:baleia = luaeval("require('baleia').setup { }")
autocmd BufWinEnter my-buffer call s:baleia.automatically(bufnr('%'))
```

where `my_buffer` is how you identify in which buffers it should run (please
read `:h autocmd`)

## Automatically colorize text added to the quickfix window

To automatically colorize text added to the quickfix use `BufReadPost`

```vim
let s:baleia = luaeval("require('baleia').setup { }")
autocmd BufReadPost quickfix setlocal modifiable
  \ | silent call g:baleia.once(bufnr('%'))
  \ | setlocal nomodifiable
```

### Setup options

When calling the `setup` function, the following options are available:

|      option      |      default value     |
| -----------------| ---------------------- |
| name             | 'BaleiaColors'         |
| strip_ansi_codes | true                   |
| line_starts_at   | 1 (one-indexed)        |

#### name

By default `BaleiaColors`, this will be the name of the highlight namespace 
defined by `baleia` as well as a prefix in the name of all highlight groups
created by it.

#### strip_ansi_codes

By default `true`, indicates whether `baleia` should or not remove the ANSI 
escape sequence of the text after colorizing it.

#### line_starts_at

By default `1`, one-indexed, indicates in which column `baleia` should start 
colorizing lines.

## With Conjure

This can be used to colorize [Conjure][conjure] log buffer. To do it you must 
tell conjure to not strip ANSI escape codes:

```vim
" tell Conjure to not strip ANSI sequences
let g:conjure#log#strip_ansi_escape_sequences_line_limit = 0
```

To automatically enable `baleia` for all Conjure log buffers use 

```vim
let s:baleia = luaeval("require('baleia').setup { line_starts_at = 3 }")
autocmd BufWinEnter conjure-log-* call s:baleia.automatically(bufnr('%'))
```

## What to do if something looks wrong

Enable logs with

```vim
let s:baleia = luaeval("require('baleia').setup { log = 'DEBUG' }")
command! BaleiaLogs call s:baleia.logger.show()
```

You can set the log level to `ERROR`, `WARN`, `INFO` or `DEBUG`. You can see
the log using `BaleiaLogs`.

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
[vim-plug]: https://github.com/junegunn/vim-plug
[conjure]: https://github.com/Olical/conjure
[packer]: https://github.com/wbthomason/packer.nvim
