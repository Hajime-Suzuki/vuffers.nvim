local logger = require("utils.logger")
local actions = require("vuffers.ui-actions")
local config = require("vuffers.config")
local buffers = require("vuffers.buffers")

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

  vim.keymap.set(
    "n",
    keymaps.view.pin,
    actions.pin_buffer,
    { noremap = true, silent = true, nowait = true, buffer = bufnr }
  )

  vim.keymap.set(
    "n",
    keymaps.view.unpin,
    actions.unpin_buffer,
    { noremap = true, silent = true, nowait = true, buffer = bufnr }
  )

  vim.keymap.set("n", "R", function()
    local pos = vim.api.nvim_win_get_cursor(0)
    local b = buffers.get_buffer_by_index(pos[1])
    vim.ui.input({ prompt = "new name? ", default = b.name }, function(new_name)
      vim.notify(new_name)
      if not new_name then
        return
      end

      buffers.rename_buffer({ index = pos[1], new_name = new_name })
    end)
  end, { noremap = true, silent = true, nowait = true, buffer = bufnr })
end

return M
