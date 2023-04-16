local ui = require("vuffers.ui")
local bufs = require("vuffers.buffers")
local auto_commands = require("vuffers.auto-commands")
local actions = require("vuffers.actions")
local key_bindings = require("vuffers.key-bindings")

local M = {}

function M.setup(opts)
  -- auto_commands.setup()
end

function M.toggle()
  if ui.is_hidden() then
    M.open()
  else
    M.close()
  end
end

function M.open()
  if not ui.is_hidden() then
    return
  end

  local is_valid = ui.is_valid()

  auto_commands.create_auto_group()

  bufs.reload_all_buffers()

  ui.open()
  actions.render_buffers()

  if not is_valid then
    key_bindings.init(ui.get_split_buf_num())
  end
end

function M.close()
  if ui.is_hidden() then
    return
  end

  auto_commands.remove_auto_group()
  ui.close()
end

return M
