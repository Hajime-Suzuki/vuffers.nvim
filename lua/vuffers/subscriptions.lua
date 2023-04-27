local events = require("vuffers.events")
local eb = require("vuffers.event-bus")
local ui = require("vuffers.ui")
local keymaps = require("vuffers.key-bindings")
local buffers = require("vuffers.buffers")

local M = {}

function M.setup()
  eb.subscribe(
    events.names.ActiveBufferChanged,
    ui.highlight_active_buffer,
    { label = "UI - highlight active buffers" }
  )

  eb.subscribe(events.names.BufferListChanged, ui.render_buffers, { label = "UI - render buffers" })

  eb.subscribe(events.names.VuffersWindowOpened, keymaps.setup, { label = "Keymaps - set up keymaps" })
  eb.subscribe(events.names.VuffersWindowOpened, buffers.reload_all_buffers, { label = "Buffers - reload all buffers" })
end

return M
