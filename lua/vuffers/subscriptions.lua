local eb = require("vuffers.event-bus")
local ui = require("vuffers.ui")
local keymaps = require("vuffers.key-bindings")
local buffers = require("vuffers.buffers")

local M = {}

function M.setup()
  eb.subscribe(eb.event.ActiveBufferChanged, ui.highlight_active_buffer, { label = "UI - highlight active buffers" })

  eb.subscribe(eb.event.BufferListChanged, ui.render_buffers, { label = "UI - render buffers" })

  eb.subscribe(eb.event.VuffersWindowOpened, keymaps.setup, { label = "Keymaps - set up keymaps" })
  eb.subscribe(eb.event.VuffersWindowOpened, buffers.reload_buffers, { label = "Buffers - reload all buffers" })
end

return M
