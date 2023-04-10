local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local render = require("vuffers.render")
local M = {}

function M.setup(opts) end

function M.open()
  ui.open()

  local lines = bufs.get_all_buffers()
  local bufnr = ui.get_split_buf_num()

  render.render_new(bufnr, lines)
end

function M.close()
  ui.close()
end

return M
