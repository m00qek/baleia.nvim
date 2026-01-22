local renderer = require("baleia.renderer")
local styles = require("baleia.styles")
local themes = require("baleia.styles.themes")

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
            style = styles.none(), -- Simplified style
          },
        },
      },
    }

    local style = styles.none()
    style.foreground.set = true
    style.foreground.value = { name = "red", cterm = 1, inferred = "#ff0000" }

    items[1].highlights[1].style = style

    local options = {
      name = "BaleiaColors",
      strip_ansi_codes = true,
      colors = themes.NR_8,
    }

    renderer.render(buffer, namespace, 0, items, options, true)

    -- Check text
    local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    assert.combinators.match({ "Hello" }, lines)

    -- Check highlights (extmarks)
    local extmarks = vim.api.nvim_buf_get_extmarks(buffer, namespace, 0, -1, { details = true })
    assert.combinators.match({
      {
        [1] = 1, -- id
        [2] = 0, -- row
        [3] = 0, -- col
        [4] = {
          end_col = 5,
        },
      },
    }, extmarks)

    -- Verify highlight definition
    local mark = extmarks[1]
    local hl_group = mark[4].hl_group
    assert.truthy(string.match(hl_group, "^BaleiaColors_"))

    local hl_def = vim.api.nvim_get_hl(0, { name = hl_group })
    assert.truthy(hl_def.fg) -- Should have foreground set
  end)

  it("caches highlight definitions", function()
    local items = {
      {
        text = "Hello",
        highlights = {
          {
            from = 0,
            to = 4,
            style = styles.none(),
          },
        },
      },
    }
    -- Setup a style
    local style = styles.none()
    style.foreground.set = true
    style.foreground.value = { name = "blue", cterm = 4, inferred = "#0000ff" }
    items[1].highlights[1].style = style

    local options = {
      name = "BaleiaCacheTest",
      strip_ansi_codes = true,
      colors = themes.NR_8,
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
end)