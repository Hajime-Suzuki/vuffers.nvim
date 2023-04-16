local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local auto_commands = require("vuffers.auto-commands")
local ui = require("vuffers.ui")
local key_bindings = require("vuffers.key-bindings")

local M = {}

function M.setup(opts)
  -- auto_commands.setup()
end

function M.toggle()
  if window.is_hidden() then
    M.open()
  else
    M.close()
  end
end

function M.open()
  if not window.is_hidden() then
    return
  end

  local is_valid = window.is_valid()

  auto_commands.create_auto_group()

  window.open()
  bufs.reload_all_buffers()

  if not is_valid then
    key_bindings.init(window.get_split_buf_num())
  end
end

function M.close()
  if window.is_hidden() then
    return
  end

  auto_commands.remove_auto_group()
  window.close()
end

return M
