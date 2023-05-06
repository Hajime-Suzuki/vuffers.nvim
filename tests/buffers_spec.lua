---@diagnostic disable: undefined-global
local buffers = require("vuffers.buffers")
local event_bus = require("vuffers.event-bus")
local config = require("vuffers.config")
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

describe("buffers >>", function()
  describe("pin_buffer >>", function()
    before_each(function()
      event_bus._delete_all_subscriptions()
      buffers._reset_buffers()
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

    it("should place pinned buffers on the top of the list", function()
      ---@type BufferListChangedPayload
      local _updated_bufs = {}
      local f = function(bufs)
        _updated_bufs = bufs
      end

      -- given there are buffers
      buffers.add_buffer(create_buffer({ file = "a/b/c/test.json", buf = 1 }))
      buffers.add_buffer(create_buffer({ file = "foo.lua", buf = 2 }))
      buffers.add_buffer(create_buffer({ file = "bar.lua", buf = 3 }))
      event_bus.subscribe(event_bus.event.BufferListChanged, f, { label = "test" })

      -- when buffer is pinned
      buffers.pin_buffer(2)
      buffers.pin_buffer(3)

      local bufs = list.map(_updated_bufs.buffers, function(buf)
        return { is_pinned = buf.is_pinned, buf = buf.buf }
      end)

      -- then buffers are sorted correctly
      assert.are.same({
        { is_pinned = true, buf = 2 },
        { is_pinned = true, buf = 3 },
        { is_pinned = false, buf = 1 },
      }, bufs)
    end)
  end)

  describe("unpin_buffer >>", function()
    before_each(function()
      event_bus._delete_all_subscriptions()
      buffers._reset_buffers()
    end)

    it("should unpin buffer", function()
      ---@type BufferListChangedPayload
      local _updated_bufs = {}
      local f = function(bufs)
        _updated_bufs = bufs
      end

      -- given there are buffers
      buffers.add_buffer(create_buffer({ file = "a/b/c/test.json", buf = 1 }))
      buffers.add_buffer(create_buffer({ file = "foo.lua", buf = 2 }))
      buffers.pin_buffer(1)

      event_bus.subscribe(event_bus.event.BufferListChanged, f, { label = "test" })

      -- when buffer is pinned
      buffers.unpin_buffer(1)

      -- then is_pinned is true
      assert.are.same(false, _updated_bufs.buffers[1].is_pinned)
    end)

    it("should place pinned buffers on the top of the list", function()
      ---@type BufferListChangedPayload
      local _updated_bufs = {}
      local f = function(bufs)
        _updated_bufs = bufs
      end

      -- given there are buffers
      buffers.add_buffer(create_buffer({ file = "a/b/c/test.json", buf = 1 }))
      buffers.add_buffer(create_buffer({ file = "foo.lua", buf = 2 }))
      buffers.add_buffer(create_buffer({ file = "bar.lua", buf = 3 }))
      buffers.pin_buffer(3) -- pin the last buffer on the list (buf 3) updated buf: 3, 1, 2
      buffers.pin_buffer(3) -- pin the last buffer on the list (buf 2) updated buf: 2, 3, 1
      buffers.pin_buffer(3) -- pin the last buffer on the list (buf 1) updated buf: 1, 2, 3

      event_bus.subscribe(event_bus.event.BufferListChanged, f, { label = "test" })

      -- when buffer is pinned
      buffers.unpin_buffer(1) -- unpin fist buffer on the list (buf 1) updated buf: 2, 3, 1
      buffers.unpin_buffer(1) -- unpin first buffer on the list (buf 2) updated buf: 3, 1, 2

      local bufs = list.map(_updated_bufs.buffers, function(buf)
        return { iis_pinned = buf.is_pinned, buf = buf.buf }
      end)

      -- then buffers are sorted correctly
      assert.are.same({
        { iis_pinned = true, buf = 3 },
        { iis_pinned = false, buf = 1 },
        { iis_pinned = false, buf = 2 },
      }, bufs)
    end)
  end)
end)
