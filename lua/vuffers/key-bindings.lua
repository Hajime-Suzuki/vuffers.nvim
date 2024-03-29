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

  vim.keymap.set("n", keymaps.view.reset_custom_display_name, actions.reset_custom_display_name, opts)

  vim.keymap.set("n", keymaps.view.reset_custom_display_names, actions.reset_custom_display_names, opts)

  vim.keymap.set("n", keymaps.view.move_up, function()
    actions.move_current_buffer_by_count({ direction = "prev" })
  end, opts)

  vim.keymap.set("n", keymaps.view.move_down, function()
    actions.move_current_buffer_by_count({ direction = "next" })
  end, opts)

  vim.keymap.set("n", keymaps.view.move_to, actions.move_buffer_to_index, opts)
end

return M
