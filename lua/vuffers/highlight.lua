local ui = require("vuffers.ui")
local buffers = require("vuffers.buffers")

local M = {}

local ns_id = vim.api.nvim_create_namespace("my_namespace") -- namespace id

function M.highlight_selected_buffer()
  local current_buffer = buffers.get_current_buffer()
  if current_buffer == nil then
    return
  end

  local split_buf = ui.get_split_buf_num()
  vim.api.nvim_buf_clear_namespace(split_buf, ns_id, 0, -1)
  vim.api.nvim_buf_add_highlight(split_buf, ns_id, "VuffersSelectedBuffer", current_buffer.index - 1, 0, -1)
end

return M
