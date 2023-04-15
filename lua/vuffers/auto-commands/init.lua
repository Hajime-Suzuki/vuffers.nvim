local highlight = require("vuffers.auto-commands.highlight")
local const = require("vuffers.constants")

local M = {}

function M.setup()
  vim.api.nvim_create_augroup(const.AUTO_CMD_GROUP, { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    group = const.AUTO_CMD_GROUP,
    callback = highlight.on_buf_enter,
  })
end

return M
