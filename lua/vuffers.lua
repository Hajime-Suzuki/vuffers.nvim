local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local render = require("vuffers.render")
local auto_commands = require("vuffers.auto-commands")
local events = require("vuffers.events")
local actions = require("vuffers.actions")

local M = {}

function M.setup(opts)
  auto_commands.setup()
end

function M.open()
  bufs.reload_all_buffers()

  ui.open()
  actions.render_buffers()

  events.publish(events.VuffersWindowOpened)
end

function M.close()
  ui.close()
end

return M
