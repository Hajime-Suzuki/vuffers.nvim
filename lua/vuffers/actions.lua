local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local render = require("vuffers.render")

local M = {}

function M.render_buffers()
  local buffers = bufs.get_all_buffers()
  local split_bufnr = ui.get_split_buf_num()
  local current_buffer = bufs.get_current_buffer()

  render.render_new(split_bufnr, buffers)

  local active_line = current_buffer and current_buffer.index

  if active_line == nil then
    return
  end

  print("active_line", active_line)

  render.set_highlight(split_bufnr, active_line - 1)
end

return M
