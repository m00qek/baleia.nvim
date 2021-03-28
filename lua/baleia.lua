local START_OF_LINE = 3
local END_OF_LINE = -1

local function get_theme_colors()
  ansi_colors = { 'black', 'red', 'green', 'yellow', 'blue', 'magenta', 'cyan', 'white' }  
  nvim_colors = {}
  for index, color in pairs(ansi_colors) do
    nvim_colors[color] = vim.g['terminal_color_' .. index - 1] or color
  end
  return nvim_colors
end

local theme_colors = get_theme_colors()

local ansi_foreground = {
  [30] = { cterm = 'black',   gui = theme_colors['black']   },
  [31] = { cterm = 'red',     gui = theme_colors['red']     },
  [32] = { cterm = 'green',   gui = theme_colors['green']   },
  [33] = { cterm = 'yellow',  gui = theme_colors['yellow']  },
  [34] = { cterm = 'blue',    gui = theme_colors['blue']    },
  [35] = { cterm = 'magenta', gui = theme_colors['magenta'] },
  [36] = { cterm = 'cyan',    gui = theme_colors['cyan']    },
  [37] = { cterm = 'white',   gui = theme_colors['white']   },
  [0]  = { cterm = 'none',    gui = 'none'                  }
}

local ansi_background = {
  [40] = { cterm = 'black',   gui = theme_colors['black']   },
  [41] = { cterm = 'red',     gui = theme_colors['red']     },    
  [42] = { cterm = 'green',   gui = theme_colors['green']   }, 
  [43] = { cterm = 'yellow',  gui = theme_colors['yellow']  },
  [44] = { cterm = 'blue',    gui = theme_colors['blue']    },  
  [45] = { cterm = 'magenta', gui = theme_colors['magenta'] },
  [46] = { cterm = 'cyan',    gui = theme_colors['cyan']    },  
  [47] = { cterm = 'white',   gui = theme_colors['white']   },
  [0]  = { cterm = 'none',    gui = 'none'                  }
}


local ansi_modes = {
  [1] = 'bold',
  [3] = 'italic',
  [4] = 'underline'
}

local function none() 
  return {
    foreground = { set = false, value = ansi_foreground[0]},
    background = { set = false, value = ansi_background[0]},
    modes = {
      bold =      { set = false, value = false }, 
      italic =    { set = false, value = false },
      underline = { set = false, value = false }
    },
  }
end

local function reset() 
  return {
    foreground = { set = true, value = ansi_foreground[0]},
    background = { set = true, value = ansi_background[0]},
    modes = {
      bold =      { set = true, value = false }, 
      italic =    { set = true, value = false },
      underline = { set = true, value = false }
    },
  }
end

local function extract_locations(lines, to_style) 
  local locations = {}
  for line, text in pairs(lines) do
    local position = 1
    for ansi_sequence in  text:gmatch('\x1b[[:;0-9]*m') do
      local column = text:find('\x1b[[:;0-9]*m', position) 

      table.insert(locations, {
        start = { column = column, line = line},
        style = to_style(ansi_sequence) 
      } )
      position = column + 1
    end
  end

  for i, location in ipairs(locations) do 
    local next_location = locations[i + 1]

    if next_location and next_location.start.column > 0 then 
      location['end'] = next_location.start
    elseif next_location then
      location['end'] = {
        line = next_location.start.line - 1,
        column = END_OF_LINE
      }
    else
      location['end'] = { line = location.start.line, column = END_OF_LINE }
    end
  end

  return locations
end

local function codes_to_style(codes)
  if #codes == 1 and codes[1] == 0 then
    return reset();
  end

  local style = none()
  for _,code in ipairs(codes) do
    if ansi_modes[code] then
      style.modes[ansi_modes[code]] = { set = true, value = true }
    elseif ansi_foreground[code] then
      style.foreground = { set = true, value = ansi_foreground[code] }
    elseif ansi_background[code] then
      style.background = { set = true, value = ansi_background[code] }
    end
  end

  return style
end

local function to_style(ansi_sequence)
  local codes = {}
  local i = 1;
  for code in ansi_sequence:gmatch('[0-9]+') do
    codes[i] = tonumber(code)
    i = i + 1
  end
 
  return codes_to_style(codes)
end 

local function to_group_name(style)
  local name = 'ConjureLogColor_'
  for mode, value in pairs(style.modes) do
    if value.set and value.value then
      name = name .. mode:sub(1,1)
    end
  end

 return name .. '_' 
   .. style.foreground.value.cterm
   .. '_' 
   .. style.background.value.cterm
end

local function to_group_attributes(style)
  local cterm=''
  for mode, value in pairs(style.modes) do
    if value.set and value.value then 
      cterm = cterm .. ',' .. mode
    end
  end

  if cterm == '' then
    cterm = 'cterm=none'
  else
    cterm = 'cterm=' .. cterm:sub(2,-1)
  end

  local foreground=''
  if style.foreground.set then
    foreground = 'ctermfg=' .. style.foreground.value.cterm .. ' guifg=' .. style.foreground.value.gui 
  end

  local background=''
  if style.background.set then
    background = 'ctermbg=' .. style.background.value.cterm .. ' guibg=' .. style.background.value.gui
  end

  return cterm .. ' ' .. foreground .. ' ' .. background
end 

local function highlight_position(buffer, ns, name, offset, line, start_column, end_column)
  if end_column ~= END_OF_LINE then
    end_column = end_column + offset.column - 1
  end

  -- vim.api.nvim_command('echom "' .. start_column .. ' ' .. end_column .. '"')
 
  vim.api.nvim_buf_add_highlight(buffer,
                                 ns,
                                 name,
                                 line + offset.line - 1,
                                 start_column + offset.column - 1,
                                 end_column)
end

local function highlight(buffer, ns, offset, lines) 
  local locations = extract_locations(lines, to_style)

  for _, location in pairs(locations) do
    local name = to_group_name(location.style)
    vim.api.nvim_command('highlight ' .. name .. ' ' .. to_group_attributes(location.style))

    if location.start.line == location['end'].line then
      highlight_position(
        buffer, ns, name, offset, location.start.line, location.start.column, location['end'].column)
    else
      highlight_position(
        buffer, ns, name, offset, location.start.line, location.start.column, END_OF_LINE)

      for line = location.start.line + 1, location['end'].line - 1 do
        highlight_position(
          buffer, ns, name, offset, line, START_OF_LINE, END_OF_LINE)
      end

      highlight_position(
        buffer, ns, name, offset, location['end'].line, START_OF_LINE, location['end'].column)
    end
  end
end

local function on_line_change(ns)
  return function (_, buffer, _, _firstline, _lastline, _, _, _, _)
   local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
   highlight(buffer, ns, { column = 0, line = 0 }, lines)   
  end
end

local function setup(options) 
  local ns = vim.api.nvim_create_namespace(options.name)
  local do_highlight = on_line_change(ns)

  return { 
    once = function(buffer)
             do_highlight(0, buffer, 0, 0, -1, 0, 0, 0, 0)
           end,
    automatically = function(buffer) 
                      do_highlight(0, buffer, 0, 0, -1, 0, 0, 0, 0)
                      vim.api.nvim_buf_attach(buffer, false, { on_lines = do_highlight })
                    end
  }
end

local M = {}
M.setup = setup
return M
