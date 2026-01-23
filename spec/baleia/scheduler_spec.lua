local scheduler = require("baleia.scheduler")
require("matcher_combinators.luassert")

describe("baleia.scheduler", function()
  -- Mock vim.schedule
  local original_schedule = vim.schedule
  local scheduled_callbacks = {}

  before_each(function()
    scheduled_callbacks = {}
    vim.schedule = function(cb)
      table.insert(scheduled_callbacks, cb)
    end
  end)

  after_each(function()
    vim.schedule = original_schedule
  end)

  local function run_next_callback()
    if #scheduled_callbacks > 0 then
      local cb = table.remove(scheduled_callbacks, 1)
      cb()
    end
  end

  describe("process_array", function()
    it("processes all items synchronously when async=false", function()
      local items = { 1, 2, 3, 4, 5 }
      local processed = {}
      local rendered = {}

      scheduler.process_array(
        items,
        function(chunk, start_idx, seed)
          -- seed acts as accumulator
          local sum = seed or 0
          for _, v in ipairs(chunk) do
            table.insert(processed, v)
            sum = sum + v
          end
          return sum, sum
        end,
        function(start_idx, result)
          table.insert(rendered, { idx = start_idx, res = result })
        end,
        {
          async = false,
          chunk_size = 2,
          initial_seed = 0,
        }
      )

      -- Since async=false, everything should happen immediately without flushing schedule
      assert.combinators.match({ 1, 2, 3, 4, 5 }, processed)
      assert.combinators.match({
        { idx = 1, res = 3 }, -- 1+2
        { idx = 3, res = 10 }, -- 3+7 (accumulated) -> wait. 3+4=7. previous sum was 3. 3+3=6, 6+4=10.
        { idx = 5, res = 15 }, -- 10+5
      }, rendered)
    end)

    it("processes items in chunks when async=true", function()
      local items = { 1, 2, 3, 4, 5 }
      local processed = {}

      scheduler.process_array(
        items,
        function(chunk)
          for _, v in ipairs(chunk) do
            table.insert(processed, v)
          end
          return true
        end,
        function() end,
        {
          async = true,
          chunk_size = 2,
        }
      )

      -- First chunk runs synchronously
      assert.combinators.match({ 1, 2 }, processed)

      -- Second chunk is scheduled
      assert.are.equal(1, #scheduled_callbacks)

      run_next_callback() -- Run chunk 2 (3, 4)
      assert.combinators.match({ 1, 2, 3, 4 }, processed)

      -- Third chunk is scheduled
      assert.are.equal(1, #scheduled_callbacks)

      run_next_callback() -- Run chunk 3 (5)
      assert.combinators.match({ 1, 2, 3, 4, 5 }, processed)

      -- Done
      assert.are.equal(0, #scheduled_callbacks) -- Completion callback might be scheduled
    end)

    it("stops processing when cancelled", function()
      local items = { 1, 2, 3, 4, 5, 6 }
      local processed = {}

      local cancel = scheduler.process_array(
        items,
        function(chunk)
          for _, v in ipairs(chunk) do
            table.insert(processed, v)
          end
          return true
        end,
        function() end,
        {
          async = true,
          chunk_size = 2,
        }
      )

      -- Chunk 1 runs immediately
      assert.combinators.match({ 1, 2 }, processed)

      -- Cancel before chunk 2 runs
      cancel()

      run_next_callback()

      -- Should NOT have processed chunk 2
      assert.combinators.match({ 1, 2 }, processed)
    end)

    it("calls on_complete when finished", function()
      local items = { 1 }
      local completed = false

      scheduler.process_array(
        items,
        function() return true end,
        function() end,
        {
          async = true,
          chunk_size = 1,
          on_complete = function()
            completed = true
          end,
        }
      )

      assert.is_false(completed)
      run_next_callback() -- Schedule the on_complete call (chunk processing)
      run_next_callback() -- Execute on_complete
      assert.is_true(completed)
    end)

    it("handles errors in processing function", function()
      local items = { 1 }
      local error_msg = nil

      scheduler.process_array(
        items,
        function()
          error("Boom")
        end,
        function() end,
        {
          async = false,
          chunk_size = 1,
          on_error = function(err)
            error_msg = err
          end,
        }
      )

      assert.truthy(string.match(error_msg, "Processing failed.*Boom"))
    end)
  end)
end)
