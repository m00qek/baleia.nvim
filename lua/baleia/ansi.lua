local ansi = {}

ansi.PATTERN = '\x1b[[:;0-9]*m'

ansi.foreground = {
  [30] = 'black',
  [31] = 'red',
  [32] = 'green',
  [33] = 'yellow',
  [34] = 'blue',
  [35] = 'magenta',
  [36] = 'cyan',
  [37] = 'white',
  [0]  = 'none',
}

ansi.background = {
  [40] = 'black',
  [41] = 'red',
  [42] = 'green',
  [43] = 'yellow',
  [44] = 'blue',
  [45] = 'magenta',
  [46] = 'cyan',
  [47] = 'white',
  [0]  = 'none',
}

ansi.modes = {
  [1] = 'bold',
  [3] = 'italic',
  [4] = 'underline'
}

return ansi
