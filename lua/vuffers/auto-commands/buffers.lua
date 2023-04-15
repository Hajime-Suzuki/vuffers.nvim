local buffers = require("vuffers.buffers")
local actions = require("vuffers.actions")

local M = {}

---@param buffer {buf: number, event: string, file: string, group: number, id: number, match: string}
function M.on_buf_enter(buffer)
  -- print("bufenter", buffer.file)
  buffers.set_current_bufnr(buffer.buf)
  actions.render_buffers()
end

function M.on_buf_add(buffer) end

function M.on_buf_delete(buffer)
  -- print("delete", vim.inspect(buffer))
  -- actions.render_buffers()
end

return M
