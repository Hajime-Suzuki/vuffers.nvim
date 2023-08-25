local M = {}

---@type BufPath | nil
local _active_buf = nil

---@param buf {path: BufPath} | nil
function M.set_active_buf(buf)
  _active_buf = buf ~= nil and buf.path or nil
end

function M.get_active_buf_path()
  return _active_buf
end

return M
