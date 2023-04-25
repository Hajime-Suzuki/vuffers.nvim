local logger = require("utils.logger")
local actions = require("vuffers.buffer-actions")
local config = require("vuffers.config")

local M = {}

---@param bufnr integer
function M.setup(bufnr)
  local keymaps = config.get_keymaps()
  if not keymaps.use_default then
    logger.debug("skipping setting key bindings")
    return
  end

  logger.debug("setting key bindings", keymaps)

  vim.keymap.set(
    "n",
    keymaps.view.open,
    actions.open_buffer,
    { noremap = true, silent = true, nowait = true, buffer = bufnr }
  )

  vim.keymap.set(
    "n",
    keymaps.view.delete,
    actions.delete_buffer,
    { noremap = true, silent = true, nowait = true, buffer = bufnr }
  )
end

return M
