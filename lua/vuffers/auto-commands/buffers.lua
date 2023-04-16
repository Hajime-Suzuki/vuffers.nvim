local buffers = require("vuffers.buffers")
local ui = require("vuffers.ui")

local M = {}

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
---@param filetype string
function M.on_buf_enter(buffer, filetype)
  buffers.set_current_bufnr(buffer, filetype)
  ui.highlight_active_buffer()
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
---@param filetype string
function M.on_buf_add(buffer, filetype)
  buffers.add_buffer(buffer, filetype)
  ui.render_buffers()
  ui.highlight_active_buffer()
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_buf_delete(buffer)
  buffers.remove_buffer(buffer.buf)
  ui.render_buffers()
  ui.highlight_active_buffer()
end

return M
