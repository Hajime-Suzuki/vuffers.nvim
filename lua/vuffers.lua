local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local auto_commands = require("vuffers.auto-commands")
local actions = require("vuffers.actions")

local M = {}

function M.setup(opts)
  auto_commands.setup()
end

function M.open()
  bufs.reload_all_buffers()

  ui.open()
  actions.render_buffers()
end

function M.close()
  ui.close()
end

return M
