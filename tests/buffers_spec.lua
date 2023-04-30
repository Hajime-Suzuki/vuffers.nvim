---@diagnostic disable: undefined-global
local buffers = require("vuffers.buffers")
local event_bus = require("vuffers.event-bus")
local config = require("vuffers.config")
local str = require("utils.string")
local list = require("utils.list")
local constants = require("vuffers.constants")

---@param buf {file: string}
local function create_buffer(buf)
  return vim.tbl_deep_extend("force", {
    buf = math.random(1, 2000),
  }, buf)
end

config.setup({
  sort = {
    type = constants.SORT_TYPE.NONE,
    direction = constants.SORT_DIRECTION.ASC,
  },
})

describe("buffers", function()
  describe("pin_buffer", function()
    before_each(function()
      event_bus._delete_all_subscriptions()
    end)

    it("should pin buffer", function()
      ---@type BufferListChangedPayload
      local _updated_bufs = {}
      local f = function(bufs)
        _updated_bufs = bufs
      end

      -- given there are buffers
      buffers.add_buffer(create_buffer({ file = "a/b/c/test.json", buf = 1 }))
      buffers.add_buffer(create_buffer({ file = "foo.lua", buf = 2 }))

      event_bus.subscribe(event_bus.event.BufferListChanged, f, { label = "test" })

      -- when buffer is pinned
      buffers.pin_buffer(1)

      -- then is_pinned is true
      assert.are.same(true, _updated_bufs.buffers[1].is_pinned)
    end)
  end)
end)
