---@diagnostic disable: undefined-global
local buffers = require("vuffers.buffers")
local event_bus = require("vuffers.event-bus")
local str = require("utils.string")
local list = require("utils.list")
local constants = require("vuffers.constants")

---@param buf {file: string}
local function create_buffer(buf)
  return vim.tbl_deep_extend("force", {
    buf = math.random(1, 2000),
  }, buf)
end

describe("buffers", function()
  describe("pin_buffer", function()
    before_each(function()
      event_bus._delete_all_subscriptions()
    end)

    it("should pin buffer", function()
      local _updated_bufs = {}
      local f = function(bufs)
        _updated_bufs = bufs
      end

      -- given there are buffers
      event_bus.subscribe(event_bus.event.BufferListChanged, f, { label = "test" })
      buffers.add_buffer(create_buffer({ file = "a/b/c/test.json" }))
      buffers.add_buffer(create_buffer({ file = "foo.lua" }))

      -- when buffer is pinned
      buffers.pin_buffer(1)

      -- then is_pinned is true
      asserts.are.same(true, _updated_bufs[1].is_pinned)
    end)
  end)
end)
