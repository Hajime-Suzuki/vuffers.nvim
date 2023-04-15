local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local render = require("vuffers.render")
local auto_commands = require("vuffers.auto-commands")
local events = require("vuffers.events")
local highlight = require("vuffers.highlight")

local M = {}

function M.setup(opts)
  auto_commands.setup()
end

function M.open()
  local lines = bufs.get_all_buffer_names()
  local bufnr = ui.get_split_buf_num()
  local current_buffer = bufs.get_current_buffer()

  ui.open()

  render.render_new(bufnr, lines)

  -- TODO: use event to handle highlight
  if current_buffer ~= nil then
    highlight.highlight_selected_buffer(current_buffer.buf)
  end
end

function M.close()
  ui.close()
end

return M
