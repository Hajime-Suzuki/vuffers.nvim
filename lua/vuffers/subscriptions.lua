local eb = require("vuffers.event-bus")
local ui = require("vuffers.ui")
local keymaps = require("vuffers.key-bindings")
local buffers = require("vuffers.buffers")
local config = require("vuffers.config")
local list = require("utils.list")

local M = {}

function M.setup()
  eb.subscribe(eb.event.ActiveBufferChanged, ui.highlight_active_buffer, { label = "UI - highlight active buffers" })

  eb.subscribe(eb.event.BufferListChanged, ui.render_buffers, { label = "UI - render buffers" })

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
      list.for_each(payload.removed_buffers, function(buffer)
        config.get_handlers().on_delete_buffer(buffer.buf)
      end)
    end,
    { label = "Handlers - on_buffer" }
  )
end

return M
