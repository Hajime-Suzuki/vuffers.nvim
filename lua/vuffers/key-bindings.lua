local logger = require("utils.logger")
local actions = require("vuffers.ui-actions")

local M = {}

-- TODO: delete keymap on clean up
function M.init(bufnr)
  logger.debug("set key bindings")
  vim.keymap.set("n", "<CR>", actions.open_buffer, { noremap = true, silent = true, nowait = true, buffer = bufnr })
  vim.keymap.set("n", "d", actions.delete_buffer, { noremap = true, silent = true, nowait = true, buffer = bufnr })
end

function M.destroy(bufnr)
  logger.debug("delete key bindings")
  pcall(function()
    vim.keymap.del("n", "<CR>", { buffer = bufnr })
    vim.keymap.del("n", "d", { buffer = bufnr })
  end)
end

return M
