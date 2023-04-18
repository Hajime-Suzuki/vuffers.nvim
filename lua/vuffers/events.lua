local M = {}

---@class events
---@field BufferListChanged string
---@field ActiveFileChanged string
---@field SortChanged string
M.names = {
  BufferListChanged = "BufferListChanged",
  ActiveFileChanged = "ActiveFileChanged",
  SortChanged = "SortChanged",
}

---@param event string
M.publish = function(event)
  vim.api.nvim_command("doautocmd User " .. event)
end

return M
