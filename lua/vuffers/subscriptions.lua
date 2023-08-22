local eb = require("vuffers.event-bus")
local ui = require("vuffers.ui")
local keymaps = require("vuffers.key-bindings")
local buffers = require("vuffers.buffers")
local buffer_actions = require("vuffers.buffer-actions")
local config = require("vuffers.config")
local list = require("utils.list")
local logger = require("utils.logger")
local window = require("vuffers.window")

local M = {}

function M.setup()
  eb.subscribe(eb.event.ActiveBufferChanged, ui.highlight_active_buffer, { label = "UI - highlight active buffers" })
  eb.subscribe(
    eb.event.ActivePinnedBufferChanged,
    ui.highlight_active_pinned_buffer,
    { label = "UI - highlight active pinned buffers" }
  )

  eb.subscribe(eb.event.BufferListChanged, ui.render_buffers, { label = "UI - render buffers" })
  -- eb.subscribe(eb.event.BufferListChanged, buffers.persist_buffers, { label = "File - persist buffers to a file" })
  eb.subscribe(eb.event.BufferListChanged, window.auto_resize, { label = "Window - auto resize" })

  eb.subscribe(eb.event.VuffersWindowOpened, keymaps.setup, { label = "Keymaps - set up keymaps" })
  eb.subscribe(eb.event.VuffersWindowOpened, buffers.reload_buffers, { label = "Buffers - reload all buffers" })

  eb.subscribe(
    eb.event.UnpinnedBuffersRemoved,
    ui.render_buffers,
    { label = "UI - render buffers after unpinned buffers removed" }
  )

  eb.subscribe(
    eb.event.UnpinnedBuffersRemoved,
    ---@param payload UnpinnedBuffersRemovedPayload
    function(payload)
      if not payload.active_buffer_index then
        logger.warn("UnpinnedBuffersRemovedPayload: active buffer not found")
        return
      end

      buffer_actions.go_to_buffer_by_index(payload.active_buffer_index)
    end,
    { label = "UI - render buffers after unpinned buffers removed" }
  )

  eb.subscribe(
    eb.event.UnpinnedBuffersRemoved,
    ---@param payload UnpinnedBuffersRemovedPayload
    function(payload)
      list.for_each(payload.removed_buffers, function(buffer)
        config.get_handlers().on_delete_buffer(buffer.buf)
      end)
    end,
    { label = "Handlers - on_buffer_delete" }
  )
end

return M
