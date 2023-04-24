local logger = require("utils.logger")
local actions = require("vuffers.buffer-actions")

local M = {}

---@param bufnr integer
function M.setup(bufnr)
  logger.debug("set key bindings")
  vim.keymap.set("n", "<CR>", actions.open_buffer, { noremap = true, silent = true, nowait = true, buffer = bufnr })
  vim.keymap.set("n", "d", actions.delete_buffer, { noremap = true, silent = true, nowait = true, buffer = bufnr })
end

return M
