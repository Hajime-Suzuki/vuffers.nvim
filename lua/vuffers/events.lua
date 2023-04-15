local M = {}

M.VuffersWindowOpened = "VuffersWindowOpened"

---@param event string
M.publish = function(event)
  vim.api.nvim_cmd({
    cmd = "doautocmd User " .. event,
  }, {})
end
return M
