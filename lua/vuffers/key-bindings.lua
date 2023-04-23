local actions = require("vuffers.ui-actions")

local M = {}

-- TODO: delete keymap on clean up
function M.init(bufnr)
  vim.keymap.set("n", "<CR>", actions.open_buffer, { noremap = true, silent = true, nowait = true, buffer = bufnr })
  vim.keymap.set("n", "d", actions.delete_buffer, { noremap = true, silent = true, nowait = true, buffer = bufnr })
end

return M
