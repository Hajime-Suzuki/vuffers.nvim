local M = {}

---@enum Event
M.names = {
  -- Events into UI
  BufferListChanged = "BufferListChanged",
  ActiveBufferChanged = "ActiveBufferChanged",

  -- Events from UI
  VuffersWindowOpened = "VuffersWindowOpened",
}

---@param event string
M.publish = function(event)
  vim.api.nvim_command("doautocmd User " .. event)
end

return M
