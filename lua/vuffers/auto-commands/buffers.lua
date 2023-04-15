local buffers = require("vuffers.buffers")
local actions = require("vuffers.actions")

local M = {}

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_buf_enter(buffer)
  buffers.set_current_bufnr(buffer.buf)
  actions.render_buffers()
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_buf_add(buffer)
  buffers.add_buffer(buffer)
  actions.render_buffers()
end

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_buf_delete(buffer)
  buffers.remove_buffer(buffer.buf)
  actions.render_buffers()
end

return M
