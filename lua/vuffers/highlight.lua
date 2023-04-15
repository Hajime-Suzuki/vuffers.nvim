local ui = require("vuffers.ui")
local buffers = require("vuffers.buffers")

local M = {}

local ns_id = vim.api.nvim_create_namespace("my_namespace") -- namespace id

---@param bufnr number
function M.highlight_selected_buffer(bufnr)
  local selected = buffers.get_selected_buffer(bufnr)
  if selected == nil then
    return
  end

  local split_buf = ui.get_split_buf_num()
  vim.api.nvim_buf_clear_namespace(split_buf, ns_id, 0, -1)
  vim.api.nvim_buf_add_highlight(split_buf, ns_id, "VuffersSelectedBuffer", selected.index - 1, 0, -1)
end

return M
