local buffers = require("vuffers.buffers")

local M = {}

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
---@param filetype string
function M.on_buf_enter(buffer, filetype)
  buffers.set_active_bufnr(buffer, filetype)
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
---@param filetype string
function M.on_buf_add(buffer, filetype)
  buffers.add_buffer(buffer, filetype)
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_buf_delete(buffer)
  buffers.remove_buffer({ bufnr = buffer.buf })
end

return M
