local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local render = require("vuffers.render")

local M = {}

function M.render_buffers()
  local lines = bufs.get_all_buffer_names()
  local bufnr = ui.get_split_buf_num()

  render.render_new(bufnr, lines)

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

return M
