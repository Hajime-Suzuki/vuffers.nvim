local highlight = require("vuffers.auto-commands.highlight")
local event_handlers = require("vuffers.auto-commands.events")
local events = require("vuffers.events")
local constants = require("vuffers.constants")

local M = {}

function M.setup()
  vim.api.nvim_create_augroup(constants.AUTO_CMD_GROUP, { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    group = constants.AUTO_CMD_GROUP,
    callback = function(buffer)
      if vim.bo.filetype == constants.FILE_TYPE then
        return
      end
      highlight.on_buf_enter(buffer)
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = events.VuffersWindowOpened,
    group = constants.AUTO_CMD_GROUP,
    callback = event_handlers.on_events,
  })
end

return M
