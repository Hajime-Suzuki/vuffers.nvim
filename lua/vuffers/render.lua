local M = {}

---@param bufnr number
---@param lines string[]
function M.render_new(bufnr, lines)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

return M
