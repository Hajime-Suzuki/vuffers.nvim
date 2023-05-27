---@diagnostic disable: undefined-global
local buffers = require("vuffers.buffers")
local pinned_bufs = require("vuffers.buffers.pinned-buffers")
local bs = require("vuffers.buffers.buffers")
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
      buffers.set_buffers({})
      pinned_bufs.__reset_pinned_bufnrs()
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
      assert.are.same(true, buffers.is_pinned({ buf = 1 }))
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
        return { is_pinned = buffers.is_pinned(buf), buf = buf.buf }
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
      buffers.set_buffers({})
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
      assert.are.same(false, buffers.is_pinned({ buf = 1 }))
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
        return { is_pinned = buffers.is_pinned(buf), buf = buf.buf }
      end)

      -- then buffers are sorted correctly
      assert.are.same({
        { is_pinned = true, buf = 3 },
        { is_pinned = false, buf = 1 },
        { is_pinned = false, buf = 2 },
      }, bufs)
    end)
  end)

  describe("remove_unpinned_buffers >>", function()
    before_each(function()
      event_bus._delete_all_subscriptions()
      buffers.set_buffers({})
      pinned_bufs.__reset_pinned_bufnrs()
    end)

    it("should remove unpinned buffers when active buffer is pinned", function()
      ---@type UnpinnedBuffersRemovedPayload
      local _updated_bufs = {}
      local f = function(bufs)
        _updated_bufs = bufs
      end

      -- GIVEN there are buffers
      buffers.add_buffer(create_buffer({ file = "a/b/c/test.json", buf = 1 }))
      buffers.add_buffer(create_buffer({ file = "foo.lua", buf = 2 }))
      buffers.add_buffer(create_buffer({ file = "bar.lua", buf = 3 }))
      buffers.add_buffer(create_buffer({ file = "test/something.ts", buf = 4 }))

      event_bus.subscribe(event_bus.event.BufferListChanged, f, { label = "test" })

      -- AND there are pinned buffers
      -- (pin buf4 and buf3)
      buffers.pin_buffer(4)
      buffers.pin_buffer(4)

      -- active buffer is buf 4
      buffers.set_active_bufnr(4)

      local pinned = list.filter(_updated_bufs.buffers, function(buf)
        return buffers.is_pinned(buf)
      end)

      pinned = list.map(pinned or {}, function(buf)
        return buf.buf
      end)

      -- there are pinned buffers
      assert.are.same({ 3, 4 }, pinned)

      event_bus.subscribe(event_bus.event.UnpinnedBuffersRemoved, f, { label = "test" })

      -- WHEN remove unpinned buffers
      buffers.remove_unpinned_buffers()

      local unpinned = list.filter(_updated_bufs.buffers, function(buf)
        return not buffers.is_pinned(buf)
      end)

      pinned = list.filter(_updated_bufs.buffers, function(buf)
        return buffers.is_pinned(buf)
      end)
      pinned = list.map(pinned or {}, function(buf)
        return buf.buf
      end)
      local removed = list.map(_updated_bufs.removed_buffers, function(buf)
        return buf.buf
      end)

      -- THEN there are no unpinned buffers
      assert.are.same({}, unpinned)

      -- AND pinned buffers are kept
      assert.are.same({ 3, 4 }, pinned)

      -- AND unpinned buffers are removed buffers
      assert.are.same({ 1, 2 }, removed)

      -- AND active buffer is still buf 4 (index 2)
      assert.are.same(2, _updated_bufs.active_buffer_index)
    end)

    it("should remove unpinned buffers when active buffer is not pinned", function()
      ---@type UnpinnedBuffersRemovedPayload
      local _updated_bufs = {}
      local f = function(bufs)
        _updated_bufs = bufs
      end

      -- GIVEN there are buffers
      buffers.add_buffer(create_buffer({ file = "a/b/c/test.json", buf = 1 }))
      buffers.add_buffer(create_buffer({ file = "foo.lua", buf = 2 }))
      buffers.add_buffer(create_buffer({ file = "bar.lua", buf = 3 }))
      buffers.add_buffer(create_buffer({ file = "test/something.ts", buf = 4 }))

      event_bus.subscribe(event_bus.event.BufferListChanged, f, { label = "test" })

      -- AND there are pinned buffers
      -- (pin buf4 and buf3)
      buffers.pin_buffer(4)
      buffers.pin_buffer(4)

      -- active buffer is buf 2
      buffers.set_active_bufnr(2)

      local pinned = list.filter(_updated_bufs.buffers, function(buf)
        return buffers.is_pinned(buf)
      end)

      pinned = list.map(pinned or {}, function(buf)
        return buf.buf
      end)

      -- there are pinned buffers
      assert.are.same({ 3, 4 }, pinned)

      event_bus.subscribe(event_bus.event.UnpinnedBuffersRemoved, f, { label = "test" })

      -- WHEN remove unpinned buffers
      buffers.remove_unpinned_buffers()

      local unpinned = list.filter(_updated_bufs.buffers, function(buf)
        return not buffers.is_pinned(buf)
      end)

      pinned = list.filter(_updated_bufs.buffers, function(buf)
        return buffers.is_pinned(buf)
      end)
      pinned = list.map(pinned or {}, function(buf)
        return buf.buf
      end)
      local removed = list.map(_updated_bufs.removed_buffers, function(buf)
        return buf.buf
      end)

      -- THEN there are no unpinned buffers
      assert.are.same({}, unpinned)

      -- AND pinned buffers are kept
      assert.are.same({ 3, 4 }, pinned)

      -- AND unpinned buffers are removed buffers
      assert.are.same({ 1, 2 }, removed)

      -- AND active buffer is still buf 3 (index 1)
      assert.are.same(1, _updated_bufs.active_buffer_index)
    end)
  end)
end)
