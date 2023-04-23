local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local auto_commands = require("vuffers.auto-commands")
local key_bindings = require("vuffers.key-bindings")
local logger = require("utils.logger")
local config = require("vuffers.config")
local ui_actions = require("vuffers.ui-actions")
local events = require("vuffers.events")

local M = {}

function M.setup(opts)
  config.setup(opts)
  logger.setup()
  auto_commands.create_auto_group()
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

  logger.debug("M.open: start")

  window.open()
  bufs.reload_all_buffers()
  key_bindings.init(window.get_bufnr())

  logger.debug("M.open: end")
end

function M.close()
  if window.is_hidden() then
    return
  end

  logger.debug("M.close: start")

  window.close()
  logger.debug("M.close: end")
end

function M.debug_buffers()
  bufs.debug_buffers()
end

---@param line_number? integer
function M.go_to_buffer_by_line(line_number)
  return ui_actions.go_to_buffer_by_index(line_number)
end

---@param args {direction: 'next' | 'prev', count?: integer}
function M.go_to_buffer_by_count(args)
  return ui_actions.next_or_prev_buffer(args)
end

---@param sort {type: SortType, direction: SortDirection}
function M.change_sort(sort)
  config.set_sort(sort)
  logger.info("set_sort: sort order has been updated", sort)
  events.publish(events.names.SortChanged)
end

---@param width number | string
--width: string such as "+10" or "-10", or number
function M.resize(width)
  window.resize(width)
end

return M
