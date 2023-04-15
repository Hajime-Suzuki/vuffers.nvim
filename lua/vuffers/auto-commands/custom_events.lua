local events = require("vuffers.events")
local highlight = require("vuffers.highlight")

local M = {}

local function handleWindowOpened(buffer)
  highlight.highlight_selected_buffer()
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_custom_events(buffer)
  if buffer.match == events.VuffersWindowOpened then
    handleWindowOpened(buffer)
  end
end

return M
