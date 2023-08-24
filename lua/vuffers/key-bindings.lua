local logger = require("utils.logger")
local actions = require("vuffers.ui-actions")
local config = require("vuffers.config")

local M = {}

---@param payload VuffersWindowOpenedPayload
function M.setup(payload)
  local bufnr = payload.buffer_number
  local keymaps = config.get_keymaps()
  if not keymaps.use_default then
    logger.debug("skipping setting key bindings")
    return
  end

  logger.debug("setting key bindings", keymaps)

  local opts = { noremap = true, silent = true, nowait = true, buffer = bufnr }

  vim.keymap.set("n", keymaps.view.open, actions.open_buffer, opts)

  vim.keymap.set("n", keymaps.view.delete, actions.delete_buffer, opts)

  vim.keymap.set("n", keymaps.view.pin, actions.pin_buffer, opts)

  vim.keymap.set("n", keymaps.view.unpin, actions.unpin_buffer, opts)

  vim.keymap.set("n", keymaps.view.rename, actions.rename_buffer, opts)
end

return M
