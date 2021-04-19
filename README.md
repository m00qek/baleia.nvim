baleia.nvim
===
[![Integration][integration-badge]][integration-runs]

Display text with ANSI escape sequences (8 or 16 colors)

## Install

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'm00qek/baleia.nvim', { 'tag': 'v0.0.2' }
```

## Setup

You need to configure it using 

```vim
let s:highlighter = luaeval("require('baleia').setup()")
command! BaleiaColorize call s:highlighter.once(bufnr('%'))
```

To highlight the current buffer:

```vim
:BaleiaColorize
```

## Automatically colorize on changes

To automatically colorize when something changes use

```vim
function! s:enable_colors() 
  if exists('b:baleia') && b:baleia == v:true 
    return
  endif
  let b:baleia = v:true

  call s:highlighter.automatically(bufnr('%'))
endfunction

autocmd! BufEnter my_buffer call s:highlighter.automatically(bufnr('%')))
```

where `my_buffer` is how you identify in which buffers it should run (please
read `:h autocmd`)

### Update strategies

A escape sequence is affected by previous sequences, in a stack model. Because
of this the safest way to colorize a buffer is to colorize all lines on every
change. That's what `baleia` does by default.

If you don' think you need that for your use case you may use one of the
following strategies:

|        strategy         |       description       |
| ----------------------- | ----------------------- |
| `all()`                 | all lines
| `moving_window(n)`      | start `n` lines before the changed one |
| `take_while(predicate)` | start in the last previous line where `predicate` is true |

you can configure it using

```vim
let s:highlighter = luaeval("require('baleia').setup(require('baleia.lines').moving_window(10))")
```

## Removing ANSI escape codes

By default plugin only adds colors to text accordingly to the ANSI sequences. If
you don't want to see those sequences you have two options

### Concealing

This will not delete sequences from the text, only _hide_ them. One downside of
this approach is that, because hidden sequences are still in the text, all
motions (W, B, E, etc.) will consider them.

Add to your config

```vim
syntax match BaleiaAnsiEscapeCodes /\%x1b\[[:;0-9]*m/ conceal

set conceallevel=2
set concealcursor=nvic
```

### Stripping 

Because this plugin is executed _while_ new lines are added to the buffer, it
cannot change its contents. You may schedule a find/replace to remove escape
sequences sometime _after_ the buffer is loaded with

```vim
function! s:remove_ansi(tid)
  let l:save = winsaveview()
  try | %s/\%x1b[[:;0-9]*m//g | catch 'E486' | endtry
  call winrestview(l:save)
endfunction

function! s:enable_colors() 
  "immediately hide all escape sequences
  syntax match BaleiaAnsiEscapeCodes /\%x1b\[[:;0-9]*m/ conceal
  setlocal conceallevel=2
  setlocal concealcursor=nvic

  " remove them after some time
  call timer_start(300, funcref('s:remove_ansi'))

  if exists('b:baleia') && b:baleia == v:true 
    return
  endif
  let b:baleia = v:true

  call s:highlighter.automatically(bufnr('%'))
endfunction

autocmd! BufEnter my_buffer call s:enable_colors()
```

## With Conjure

there is a config especially made to colorize Conjure buffers. To use it do

```vim
" tell Conjure to not strip ANSI sequences
let g:conjure#log#strip_ansi_escape_sequences_line_limit = 0

let s:highlighter = luaeval("require('baleia').setup(require('baleia.options').conjure())")
```

to automatically enable `baleia` for all Conjure log buffers use 

```vim
autocmd BufEnter conjure-log-* call s:enable_colors()
```

[integration-badge]: https://github.com/m00qek/baleia.nvim/actions/workflows/integration.yml/badge.svg
[integration-runs]:  https://github.com/m00qek/baleia.nvim/actions/workflows/integration.yml
