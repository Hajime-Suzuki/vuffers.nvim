local M = {}
local events = require("vuffers.events")
local eb = require("vuffers.event-bus")
local ui = require("vuffers.ui")

function M.setup()
  eb.subscribe(events.names.ActiveFileChanged, function()
    ui.highlight_active_buffer()
  end, { label = "ui - render buffers" })
end

return M
