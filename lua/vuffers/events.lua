local M = {}

---@class events
---@field BufferListChanged string
---@field ActiveFileChanged string
M.names = {
  BufferListChanged = "BufferListChanged",
  ActiveFileChanged = "ActiveFileChanged",
}

---@param event string
M.publish = function(event)
  vim.api.nvim_command("doautocmd User " .. event)
end

return M
