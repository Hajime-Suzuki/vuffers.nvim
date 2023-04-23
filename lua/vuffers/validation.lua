local logger = require("utils.logger")

local M = {}

---@param buffer {buf: number}
---@return boolean
function M.is_valid_buf(buffer)
  if not vim.api.nvim_buf_is_valid(buffer.buf) then
    logger.warn("Buffer is not valid", buffer)
    return false
  end

  return true
end

return M
