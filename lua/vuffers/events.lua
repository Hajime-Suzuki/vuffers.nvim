local M = {}

M.VuffersWindowOpened = "VuffersWindowOpened"

---@param event string
M.publish = function(event)
  vim.api.nvim_command("doautocmd User " .. event)
end
return M
