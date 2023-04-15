local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local render = require("vuffers.render")
local auto_commands = require("vuffers.auto-commands")
local events = require("vuffers.events")

local M = {}

function M.setup(opts)
  auto_commands.setup()
end

function M.open()
  ui.open()

  local lines = bufs.get_all_buffer_names()
  local bufnr = ui.get_split_buf_num()

  render.render_new(bufnr, lines)

  events.publish(events.VuffersWindowOpened)
end

function M.close()
  ui.close()
end

return M
