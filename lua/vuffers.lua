local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local auto_commands = require("vuffers.auto-commands")
local actions = require("vuffers.actions")

local M = {}

function M.setup(opts)
  -- auto_commands.setup()
end

function M.open()
  auto_commands.create_auto_group()

  bufs.reload_all_buffers()

  ui.open()
  actions.render_buffers()
end

function M.close()
  if ui.is_hidden() then
    return
  end

  auto_commands.remove_auto_group()
  ui.close()
end

return M
