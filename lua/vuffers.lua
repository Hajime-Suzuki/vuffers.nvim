local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local auto_commands = require("vuffers.auto-commands")
local logger = require("utils.logger")
local config = require("vuffers.config")
local buffer_actions = require("vuffers.buffer-actions")
local highlights = require("vuffers.highlights")
local subscriptions = require("vuffers.subscriptions")

local M = {}

function M.setup(opts)
  logger.debug("setup start")
  config.setup(opts)
  logger.setup()
  highlights.setup()
  subscriptions.setup()
  auto_commands.create_auto_group()
  logger.debug("setup end")
end

---@return boolean
function M.is_open()
  return window.is_open()
end

function M.toggle()
  if window.is_open() then
    M.close()
  else
    M.open()
  end
end

function M.open()
  if window.is_open() then
    return
  end

  logger.trace("M.open: start")

  window.open()

  logger.trace("M.open: end")
end

function M.close()
  if not window.is_open() then
    return
  end

  logger.trace("M.close: start")

  local bufnr = window.get_buffer_number()
  if bufnr == nil then
    error("open: buffer not found")
    return
  end

  window.close()
  logger.trace("M.close: end")
end

function M.debug_buffers()
  bufs.debug_buffers()
end

---@param line_number? integer
function M.go_to_buffer_by_line(line_number)
  return buffer_actions.go_to_buffer_by_index(line_number)
end

---@param args {direction: 'next' | 'prev', count?: integer}
function M.go_to_buffer_by_count(args)
  return buffer_actions.next_or_prev_buffer(args)
end

---@param sort {type: SortType, direction: SortDirection}
function M.sort(sort)
  config.set_sort(sort)
  logger.info("set_sort: sort order has been updated", sort)
  bufs.change_sort()
end

---@param level LogLevel
function M.set_log_level(level)
  print("log level is set to " .. level)
  config.set_log_level(level)
  logger.setup()
end

---@param width number | string
--width: string such as "+10" or "-10", or number
function M.resize(width)
  window.resize(width)
end

function M.increment_additional_folder_depth()
  logger.debug("increment_additional_folder_depth")
  bufs.increment_additional_folder_depth()
end

function M.decrement_additional_folder_depth()
  logger.debug("decrement_additional_folder_depth")
  bufs.decrement_additional_folder_depth()
end

return M
