# baleia.nvim

Display text with ANSI escape sequences (8 or 16 colors)

## Install

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'm00qek/baleia.nvim'
```

## Setup

You need to configure it using 

```vim
let s:highlighter = luaeval("require('baleia').setup { name = 'MyANSIHighlighter' }")
```

To highlight the current buffer:

```vim
call s:highlighter.once(bufnr('%'))
```

to configure it to highlight a buffer automatically on changes do 

```vim
call s:highlighter.automatically(bufnr('%'))
```

## With Conjure

```vim
let g:conjure#log#strip_ansi_escape_sequences_line_limit = 0

let s:highlighter = luaeval("require('baleia').setup { name = 'ConjureLogColors' }")

function! s:enable_colors() 
  syntax match ConjureLogColorCode /\%x1b\[[:;0-9]*m/ conceal

  setlocal conceallevel=2
  setlocal concealcursor=nvic

  call s:highlighter.automatically(bufnr('%'))
endfunction

augroup ConjureLogColors
  autocmd!
  autocmd BufEnter conjure-log-* call s:enable_colors()
augroup END
```
