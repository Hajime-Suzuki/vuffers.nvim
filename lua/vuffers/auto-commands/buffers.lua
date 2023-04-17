local buffers = require("vuffers.buffers")

local M = {}

---@param buffer NativeBuffer
---@param filetype string
function M.on_buf_enter(buffer, filetype)
  buffers.set_active_bufnr({ path = buffer.file, buf = buffer.buf }, filetype)
end

---@param buffer NativeBuffer
---@param filetype string
function M.on_buf_add(buffer, filetype)
  buffers.add_buffer(buffer, filetype)
end

---@param buffer NativeBuffer
function M.on_buf_delete(buffer)
  buffers.remove_buffer({ bufnr = buffer.buf })
end

return M
