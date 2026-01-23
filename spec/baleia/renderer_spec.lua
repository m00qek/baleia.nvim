local ansi = require("baleia.ansi")
local renderer = require("baleia.renderer")

describe("baleia.renderer", function()
  local buffer
  local namespace

  before_each(function()
    buffer = vim.api.nvim_create_buf(false, true)
    namespace = vim.api.nvim_create_namespace("baleia_test")
  end)

  it("updates buffer text and applies highlights", function()
    local items = {
      {
        text = "Hello",
        highlights = {
          {
            from = 0,
            to = 4,
            style = { ctermfg = 1 }, -- Red
          },
        },
      },
    }

    local options = {
      name = "BaleiaColors",
      strip_ansi_codes = true,
      colors = ansi.NR_8,
    }

    renderer.render(buffer, namespace, 0, items, options, true)

    -- Check text
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    assert.combinators.match({ "Hello" }, lines)

    -- Check highlights (extmarks)
    local extmarks = vim.api.nvim_buf_get_extmarks(buffer, namespace, 0, -1, { details = true })

    assert.are.equal(1, #extmarks)
    local mark = extmarks[1]

    -- mark structure: { id, row, col, details }
    assert.are.equal(0, mark[2]) -- row
    assert.are.equal(0, mark[3]) -- col
    assert.are.equal(5, mark[4].end_col)

    -- Verify highlight definition
    local hl_group = mark[4].hl_group
    assert.truthy(string.match(hl_group, "^BaleiaColors_"))

    local hl_def = vim.api.nvim_get_hl(0, { name = hl_group })
    -- Note: nvim_get_hl returns fg as integer color
    assert.truthy(hl_def.fg)
  end)

  it("caches highlight definitions", function()
    local items = {
      {
        text = "Hello",
        highlights = {
          {
            from = 0,
            to = 4,
            style = { ctermfg = 4 }, -- Blue
          },
        },
      },
    }

    local options = {
      name = "BaleiaCacheTest",
      strip_ansi_codes = true,
      colors = ansi.NR_8,
    }

    local original_set_hl = vim.api.nvim_set_hl
    local set_hl_count = 0
    vim.api.nvim_set_hl = function(...)
      set_hl_count = set_hl_count + 1
      return original_set_hl(...)
    end

    -- First render: should call set_hl
    renderer.render(buffer, namespace, 0, items, options, true)
    assert.are.equal(1, set_hl_count)

    -- Second render with SAME options: should NOT call set_hl
    renderer.render(buffer, namespace, 1, items, options, true)
    assert.are.equal(1, set_hl_count)

    -- Restore spy
    vim.api.nvim_set_hl = original_set_hl
  end)

  it("hydrates hex from cterm", function()
    local style = { ctermfg = 9 } -- Bright Red (ANSI) -> #ff0000 (usually)
    local hydrated = renderer.attributes(style)
    assert.combinators.match({
      ctermfg = 9,
      foreground = "#ff0000",
    }, hydrated)
  end)

  it("hydrates cterm from hex", function()
    local style = { foreground = "#ff0000" }
    local hydrated = renderer.attributes(style)
    assert.combinators.match({
      foreground = "#ff0000",
      ctermfg = 196, -- xterm Red
    }, hydrated)
  end)

  it("uses theme for cterm -> gui conversion if provided", function()
    local style = { ctermfg = 1 }
    local theme = { [1] = "MyDarkRed" }
    local hydrated = renderer.attributes(style, theme)
    assert.combinators.match({
      ctermfg = 1,
      foreground = "MyDarkRed",
    }, hydrated)
  end)

  describe("name()", function()
    it("sanitizes '#' in hex codes", function()
      local style = { foreground = "#ff0000", bold = true }
      local name = renderer.name("Baleia", style)
      -- Sorted keys: bold, foreground
      assert.are.equal("Baleia_bold_true_foreground_xff0000", name)
    end)

    it("is deterministic (sorts keys)", function()
      local s1 = { bold = true, italic = true }
      local s2 = { italic = true, bold = true }
      assert.are.equal(renderer.name("B", s1), renderer.name("B", s2))
    end)
  end)

  describe("hydration logic", function()
    it("preserves existing values (Conflict Preservation)", function()
      -- If both are provided, hydration should not overwrite them
      local style = { ctermfg = 1, foreground = "#0000ff" }
      local hydrated = renderer.attributes(style)

      assert.are.equal(1, hydrated.ctermfg)
      assert.are.equal("#0000ff", hydrated.foreground)
    end)

    it("hydrates special color (ctermsp <-> special)", function()
      -- special -> ctermsp is removed
      local s1 = { special = "#ff0000" }
      local h1 = renderer.attributes(s1)
      assert.is_nil(h1.ctermsp)
      assert.are.equal("#ff0000", h1.special)

      -- ctermsp -> special, then ctermsp is removed
      local s2 = { ctermsp = 9 }
      local h2 = renderer.attributes(s2)
      assert.is_nil(h2.ctermsp)
      assert.are.equal("#ff0000", h2.special)
    end)

    it("falls back to xterm conversion if theme key is missing", function()
      local style = { ctermfg = 196 } -- Red
      local theme = { [1] = "MyDarkRed" } -- Theme only knows about color 1

      local hydrated = renderer.attributes(style, theme)
      assert.are.equal("#ff0000", hydrated.foreground) -- Should fallback to calculated hex
    end)
  end)

  describe("render behavior", function()
    it("passes through attributes (Attribute Pass-through)", function()
      local items = {
        {
          text = "Attributes",
          highlights = {
            {
              from = 0,
              to = 9,
              style = { bold = true, undercurl = true, italic = true },
            },
          },
        },
      }

      local options = { name = "BaleiaAttr", colors = {} }

      renderer.render(buffer, namespace, 0, items, options, true)

      local extmarks = vim.api.nvim_buf_get_extmarks(buffer, namespace, 0, -1, { details = true })
      local hl_group = extmarks[1][4].hl_group
      local hl_def = vim.api.nvim_get_hl(0, { name = hl_group })

      assert.is_true(hl_def.bold)
      assert.is_true(hl_def.undercurl)
      assert.is_true(hl_def.italic)
    end)

    it("respects update_text=false (Update Text False)", function()
      -- Pre-fill buffer
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Original Text" })

      local items = {
        {
          text = "New Text", -- Should NOT be written
          highlights = {
            { from = 0, to = 5, style = { ctermfg = 1 } },
          },
        },
      }

      local options = { name = "BaleiaNoUpdate", colors = {} }
      renderer.render(buffer, namespace, 0, items, options, false)

      -- Check Text: Should remain "Original Text"
      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      assert.are.equal("Original Text", lines[1])

      -- Check Highlights: Should be present
      local extmarks = vim.api.nvim_buf_get_extmarks(buffer, namespace, 0, -1, { details = true })
      assert.are.equal(1, #extmarks)
      assert.are.equal(0, extmarks[1][3]) -- col 0
      assert.are.equal(6, extmarks[1][4].end_col) -- col 6 (from 0 to 5 inclusive is length 6? Wait. 0 to 5 is 6 chars? 0,1,2,3,4,5. Yes.)
    end)
  end)
end)
