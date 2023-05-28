local window = require("vuffers.window")
local bufs = require("vuffers.buffers")
local auto_commands = require("vuffers.auto-commands")
local logger = require("utils.logger")
local config = require("vuffers.config")
local buffer_actions = require("vuffers.buffer-actions")
local highlights = require("vuffers.highlights")
local subscriptions = require("vuffers.subscriptions")

local M = {}

---@param opts Config
function M.setup(opts)
  logger.debug("setup start")
  config.setup(opts)
  logger.setup()
  highlights.setup()
  subscriptions.setup()
  auto_commands.create_auto_group()
  logger.debug("setup end")
end

------------------------------------
-- UI WINDOW                    --
------------------------------------

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

  logger.debug("M.open: start")

  window.open()

  logger.debug("M.open: end")
end

function M.close()
  if not window.is_open() then
    return
  end

  logger.debug("M.close: start")

  local bufnr = window.get_buffer_number()
  if bufnr == nil then
    error("open: buffer not found")
    return
  end

  window.close()
  logger.debug("M.close: end")
end

---@param width number | string
--width: string such as "+10" or "-10", or number
function M.resize(width)
  window.resize(width)
end

function M.toggle_auto_resize()
  local view_config = config.get_view_config()
  local auto_resize_enabled = not view_config.window.auto_resize

  config.set_auto_resize(auto_resize_enabled)
  if auto_resize_enabled then
    window.auto_resize()
  end
end

------------------------------------
--   BUFFERS                    --
------------------------------------

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

function M.increment_additional_folder_depth()
  logger.debug("increment_additional_folder_depth: start")
  bufs.increment_additional_folder_depth()
  logger.info("increment_additional_folder_depth: done")
end

function M.decrement_additional_folder_depth()
  logger.debug("decrement_additional_folder_depth: start")
  bufs.decrement_additional_folder_depth()
  logger.info("decrement_additional_folder_depth: done")
end

function M.pin_current_buffer()
  logger.debug("pin_buffer: start")
  local _, current_index = bufs.get_active_buffer()
  if not current_index then
    return
  end
  bufs.pin_buffer(current_index)
  logger.info("pin_buffer: done")
end

function M.unpin_current_buffer()
  logger.debug("unpin_buffer: start")
  local _, current_index = bufs.get_active_buffer()
  if not current_index then
    return
  end

  bufs.unpin_buffer(current_index)
  logger.info("unpin_buffer: done")
end

function M.close_unpinned_buffers()
  bufs.remove_unpinned_buffers()
end

function M.go_to_active_pinned_buffer()
  logger.debug("go_to_active_pinned_buffer: start")
  buffer_actions.go_to_active_pinned_buffer()
  logger.info("go_to_active_pinned_buffer: done")
end

function M.go_to_next_pinned_buffer()
  logger.debug("go_to_next_pinned_buffer: start")
  buffer_actions.go_to_next_pinned_buffer()
  logger.info("go_to_next_pinned_buffer: done")
end

function M.go_to_prev_pinned_buffer()
  logger.debug("go_to_next_pinned_buffer: start")
  buffer_actions.go_to_prev_pinned_buffer()
  logger.info("go_to_next_pinned_buffer: done")
end

--- rest buffers and reload buffers from scratch
function M.reset_buffers()
  logger.debug("reset_buffers: start")
  local _, current_index = bufs.get_active_buffer()
  if not current_index then
    return
  end

  bufs.reload_buffers()
  logger.info("reset_buffers: done")
end

------------------------------------
-- MISC                         --
------------------------------------

function M.debug_buffers()
  bufs.debug_buffers()
end

---@param level LogLevel
function M.set_log_level(level)
  print("log level is set to " .. level)
  config.set_log_level(level)
  logger.setup()
end

return M
