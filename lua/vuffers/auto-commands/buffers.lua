local buffers = require("vuffers.buffers")

local M = {}

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_buf_enter(buffer)
  buffers.set_current_bufnr(buffer.buf)
end

return M
