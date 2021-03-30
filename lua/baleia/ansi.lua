local nvim = require('baleia.nvim')

local theme = nvim.theme_colors()

local ansi = {}

ansi.PATTERN = '\x1b[[:;0-9]*m' 

ansi.foreground = {
  [30] = { cterm = 'black',   gui = theme['black']   },
  [31] = { cterm = 'red',     gui = theme['red']     },
  [32] = { cterm = 'green',   gui = theme['green']   },
  [33] = { cterm = 'yellow',  gui = theme['yellow']  },
  [34] = { cterm = 'blue',    gui = theme['blue']    },
  [35] = { cterm = 'magenta', gui = theme['magenta'] },
  [36] = { cterm = 'cyan',    gui = theme['cyan']    },
  [37] = { cterm = 'white',   gui = theme['white']   },
  [0]  = { cterm = 'none',    gui = 'none'                  }
}

ansi.background = {
  [40] = { cterm = 'black',   gui = theme['black']   },
  [41] = { cterm = 'red',     gui = theme['red']     },    
  [42] = { cterm = 'green',   gui = theme['green']   }, 
  [43] = { cterm = 'yellow',  gui = theme['yellow']  },
  [44] = { cterm = 'blue',    gui = theme['blue']    },  
  [45] = { cterm = 'magenta', gui = theme['magenta'] },
  [46] = { cterm = 'cyan',    gui = theme['cyan']    },  
  [47] = { cterm = 'white',   gui = theme['white']   },
  [0]  = { cterm = 'none',    gui = 'none'                  }
}

ansi.modes = {
  [1] = 'bold',
  [3] = 'italic',
  [4] = 'underline'
}

return ansi
