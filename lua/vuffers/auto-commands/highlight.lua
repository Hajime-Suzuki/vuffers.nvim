local highlight = require("vuffers.highlight")
local M = {}

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_buf_enter(buffer)
  highlight.highlight_selected_buffer(buffer.buf)
end

return M
