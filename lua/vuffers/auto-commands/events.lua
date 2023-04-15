local events = require("vuffers.events")
local highlight = require("vuffers.highlight")

local M = {}

local function handleWindowOpened(buffer)
  print("handleWindowOpened")
  -- highlight.highlight_selected_buffer(buffer.buf)
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_events(buffer)
  print("on_events: ", vim.inspect(buffer))
  if buffer.match == events.VuffersWindowOpened then
    handleWindowOpened(buffer)
  end
end

return M
