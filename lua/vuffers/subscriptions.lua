local events = require("vuffers.events")
local eb = require("vuffers.event-bus")
local ui = require("vuffers.ui")

local M = {}

function M.setup()
  eb.subscribe(
    events.names.ActiveBufferChanged,
    ui.highlight_active_buffer,
    { label = "UI - highlight active buffers" }
  )
  eb.subscribe(events.names.BufferListChanged, ui.render_buffers, { label = "UI - render buffers" })
end

return M
