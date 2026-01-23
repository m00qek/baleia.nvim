local inspector = require("baleia.inspector")

describe("baleia.inspector", function()
  local buffer
  local namespace

  before_each(function()
    buffer = vim.api.nvim_create_buf(false, true)
    namespace = vim.api.nvim_create_namespace("baleia_test")
    
    -- Mock highlighting
    -- We must actually set a highlight group because inspector relies on nvim_get_hl
    vim.api.nvim_set_hl(0, "TestHL_Red", { fg = "#ff0000", ctermfg = 196, bold = true })
    vim.api.nvim_set_hl(0, "TestHL_Blue", { fg = "#0000ff", ctermfg = 21, italic = true })
    
    -- Add text so columns 0-10 are valid
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "123456789012345" })
  end)

  describe("style_at_end_of_line", function()
    it("returns empty table if no marks", function()
      local style = inspector.style_at_end_of_line(buffer, namespace, 0)
      assert.combinators.match({}, style)
    end)

    it("returns style of the last mark", function()
      -- Add a mark
      vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 0, {
        end_col = 5,
        hl_group = "TestHL_Red",
      })
      
      local style = inspector.style_at_end_of_line(buffer, namespace, 0)
      
      assert.combinators.match({
        foreground = "#ff0000",
        ctermfg = 196,
        bold = true
      }, style)
    end)

    it("picks the last one if multiple", function()
      -- First mark
      vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 0, {
        end_col = 5,
        hl_group = "TestHL_Red",
      })
      -- Second mark (later in line)
      vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 6, {
        end_col = 10,
        hl_group = "TestHL_Blue",
      })
      
      local style = inspector.style_at_end_of_line(buffer, namespace, 0)
      
      assert.combinators.match({
        foreground = "#0000ff",
        ctermfg = 21,
        italic = true
      }, style)
    end)
  end)

  describe("style_at", function()
    it("returns specific style at column", function()
       -- 0-5: Red
       vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 0, {
        end_col = 5,
        hl_group = "TestHL_Red",
      })
      -- 6-10: Blue
      vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 6, {
        end_col = 10,
        hl_group = "TestHL_Blue",
      })
      
      local s1 = inspector.style_at(buffer, namespace, 0, 2) -- Inside Red
      assert.combinators.match({ foreground = "#ff0000" }, s1)
      
      local s2 = inspector.style_at(buffer, namespace, 0, 8) -- Inside Blue
      assert.combinators.match({ foreground = "#0000ff" }, s2)
      
      local s3 = inspector.style_at(buffer, namespace, 0, 5) -- In gap (col 5 is end of Red, start of gap)
      assert.combinators.match({}, s3)
    end)
  end)

  describe("fidelity (round trip)", function()
    it("recovers standard attributes and colors", function()
      -- Define a "Christmas Tree" highlight (compatible subset)
      vim.api.nvim_set_hl(0, "TestHL_Standard", {
        fg = "#112233", bg = "#445566", sp = "#778899",
        ctermfg = 1, ctermbg = 2,
        bold = true, italic = true, underline = true, 
        strikethrough = true, reverse = true
      })

      vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 0, {
        end_col = 10,
        hl_group = "TestHL_Standard"
      })

      local style = inspector.style_at_end_of_line(buffer, namespace, 0)

      assert.combinators.match({
        foreground = "#112233",
        background = "#445566",
        special = "#778899",
        ctermfg = 1,
        ctermbg = 2,
        bold = true,
        italic = true,
        underline = true,
        strikethrough = true,
        reverse = true
      }, style)
    end)
    
    it("recovers undercurl", function()
       vim.api.nvim_set_hl(0, "TestHL_Curl", { undercurl = true, sp = "#ff0000" })
       vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 0, { end_col = 5, hl_group = "TestHL_Curl" })
       local style = inspector.style_at_end_of_line(buffer, namespace, 0)
       assert.combinators.match({ undercurl = true, special = "#ff0000" }, style)
    end)
  end)

  describe("overlap behavior", function()
    it("returns the first mark found (implementation behavior check)", function()
      -- Neovim sorts extmarks by (row, col, id).
      -- Mark 1 (ID 1)
      vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 0, {
        id = 1,
        end_col = 10,
        hl_group = "TestHL_Red"
      })
      -- Mark 2 (ID 2) - Overlaps exactly
      vim.api.nvim_buf_set_extmark(buffer, namespace, 0, 0, {
        id = 2,
        end_col = 10,
        hl_group = "TestHL_Blue"
      })

      -- Since we iterate ipairs(extmarks) and return immediately,
      -- we expect the first one returned by nvim_buf_get_extmarks.
      -- nvim_buf_get_extmarks usually returns in order.
      local style = inspector.style_at(buffer, namespace, 0, 0)
      
      -- We assume ID 1 comes first.
      assert.combinators.match({ foreground = "#ff0000" }, style)
    end)
  end)
end)
