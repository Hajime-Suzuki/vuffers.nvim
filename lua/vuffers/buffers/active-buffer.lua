local M = {}

---@type integer | nil
local _active_bufnr = nil

---@param bufnr Bufnr | nil
function M.set_active_bufnr(bufnr)
  _active_bufnr = bufnr
end

function M.get_active_bufnr()
  return _active_bufnr
end

return M
