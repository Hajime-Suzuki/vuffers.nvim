local list = require("utils.list")
local M = {}

local ns_id = vim.api.nvim_create_namespace("my_namespace") -- namespace id

---@param bufnr integer
---@param buffers {buf: integer, name: string, index: integer, path: string, active: boolean}[]
function M.render_new(bufnr, buffers)
  local lines = list.map(buffers, function(buffer)
    return buffer.name .. "(" .. buffer.buf .. ")"
  end)

  local ok = pcall(function()
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end)

  if not ok then
    print("Error: Could not set lines in buffer " .. bufnr)
  end
end

---@param bufnr integer
---@param line_number integer
function M.set_highlight(bufnr, line_number)
  local ok = pcall(function()
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    vim.api.nvim_buf_add_highlight(bufnr, ns_id, "VuffersSelectedBuffer", line_number, 0, -1)
  end)

  if not ok then
    print("Error: Could not set highlight in buffer " .. bufnr)
  end
end

return M
