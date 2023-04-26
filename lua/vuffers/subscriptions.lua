local M = {}
local buffers = require("vuffers.buffers")
local eb = require("vuffers.event-bus")

function M.setup()
  eb.subscribe()
end

return M
