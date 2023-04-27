local M = {}

---@enum Event
M.names = {
  BufferListChanged = "BufferListChanged",
  ActiveBufferChanged = "ActiveBufferChanged",
  SortChanged = "SortChanged",
}

---@param event string
M.publish = function(event)
  vim.api.nvim_command("doautocmd User " .. event)
end

return M
