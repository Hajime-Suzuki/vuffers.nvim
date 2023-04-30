local event_bus = require("vuffers.event-bus")
local logger = require("utils.logger")
local utils = require("vuffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")
local constants = require("vuffers.constants")

--------------types >>----------------

---@class Buffer
---@field buf number
---@field name string name that will be displayed in the buffer list, which considers additional folder depth
---@field path string full path
---@field ext string
---@field is_pinned? boolean
---@field _unique_name string unique name
---@field _filename string filename ("test" in "test.txt")
---@field _default_folder_depth number
---@field _additional_folder_depth number
---@field _max_folder_depth number

---@class NativeBuffer
---@field buf number
---@field file string
---@field event string
---@field group number
---@field id number
---@field match string

--------------<<types ----------------

local M = {}

---@type Buffer[]
local _buf_list = {}

---@type number | nil
local _active_bufnr = nil

local function _get_all_buffers()
  return _buf_list
end

local function _get_active_bufnr()
  return _active_bufnr
end

---@type number | nil How many more parents the UI shows. This can not go below 0
local _global_additional_folder_depth = 0

---@return ActiveBufferChangedPayload
local function _get_active_buf_changed_event_payload()
  local _, index = M.get_active_buffer()

  ---@type ActiveBufferChangedPayload
  local payload = { index = index or 1 }
  return payload
end

---@return BufferListChangedPayload
local function _get_buffer_list_changed_event_payload()
  local _, index = M.get_active_buffer()

  ---@type BufferListChangedPayload
  local payload = { buffers = _buf_list, active_buffer_index = index }
  return payload
end

---@param buffer {path: string, buf: integer}
function M.set_active_bufnr(buffer)
  _active_bufnr = buffer.buf

  local event_payload = _get_active_buf_changed_event_payload()
  event_bus.publish_active_buffer_changed(event_payload)
end

local function reset_buffers()
  _buf_list = {}
end

---@param buf_or_filename integer | string
---@return boolean
-- `buf_or_filename` can be buffer number of filename
local function _is_in_buf_list(buf_or_filename)
  return list.find(_buf_list, function(buffer)
    return buffer.buf == buf_or_filename or buffer.name == buf_or_filename
  end) ~= nil
end

function M.get_num_of_buffers()
  return #_buf_list
end

---@param buffer NativeBuffer
function M.add_buffer(buffer)
  local should_ignore = _is_in_buf_list(buffer.file)

  if should_ignore then
    return
  end

  logger.debug("add_buffer: buffer will be added", { file = buffer.file })

  table.insert(_buf_list, {
    buf = buffer.buf,
    name = buffer.file,
    path = buffer.file,
    _additional_folder_depth = _global_additional_folder_depth,
  })

  local buffers = utils.get_formatted_buffers(_buf_list)
  utils.sort_buffers(buffers, config.get_sort())
  _buf_list = buffers

  logger.debug("add_buffer: buffer is added", { file = buffer.file })

  local payload = _get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

---@param args {bufnr?: number, index?: integer}
function M.remove_buffer(args)
  if not args.bufnr and not args.index then
    return
  end

  local target_index = args.index or list.find_index(_buf_list, function(buf)
    return buf.buf == args.bufnr
  end)

  if not target_index then
    -- TODO: debounce. buffer is deleted by UI action, first the buffer list is updated, then actual buffer is deleted by :bufwipeout, which triggers thsi function again
    logger.warn("remove_buffer: buffer not found", args)
    return
  end

  logger.debug("remove_buffer: buffer will be removed", args)

  if target_index ~= _get_active_bufnr() then
    table.remove(_buf_list, target_index)
    local buffers = utils.get_formatted_buffers(_buf_list)
    utils.sort_buffers(buffers, config.get_sort())
    _buf_list = buffers

    logger.debug("remove_buffer: buffer is removed", args)

    local payload = _get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
    return
  end
  --
  ---@type Buffer | nil
  local next_active_buffer = _buf_list[target_index + 1] or _buf_list[target_index - 1]

  if next_active_buffer then
    M.set_active_bufnr(next_active_buffer)
  else
    logger.warn("remove_buffer: can not delete the last buffer", args)
    return
  end

  table.remove(_buf_list, target_index)
  logger.debug("remove_buffer: buffer is removed", args)

  local payload = _get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

function M.change_sort()
  utils.sort_buffers(_buf_list, config.get_sort())

  local payload = _get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

---@param new_level integer
local function _change_additional_folder_depth(new_level)
  if new_level == _global_additional_folder_depth then
    logger.debug("change_level: level is not changed")
    return
  end

  local bufs = list.map(_buf_list, function(buf)
    buf._additional_folder_depth = new_level
    return buf
  end)
  bufs = utils.get_formatted_buffers(bufs)
  utils.sort_buffers(bufs, config.get_sort())
  _buf_list = bufs

  local payload = _get_buffer_list_changed_event_payload()

  _global_additional_folder_depth = new_level
  logger.debug("change_level: level changed", { new_level = new_level })

  event_bus.publish_buffer_list_changed(payload)
end

function M.increment_additional_folder_depth()
  local max_folder_depths = list.map(_buf_list, function(buf)
    return buf._max_folder_depth
  end)
  local max_additional_folder_depth = math.max(unpack(max_folder_depths)) - 1
  local new_level = math.min(_global_additional_folder_depth + 1, max_additional_folder_depth)
  _change_additional_folder_depth(new_level)
end

function M.decrement_additional_folder_depth()
  local new_level = math.max(_global_additional_folder_depth - 1, 0)
  _change_additional_folder_depth(new_level)
end

---@param index integer
function M.pin_buffer(index)
  local target = _buf_list[index]
  target.is_pinned = true
  utils.sort_buffers(target, config.get_sort())

  local payload = _get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

function M.reload_all_buffers()
  reset_buffers()

  local bufs = vim.api.nvim_list_bufs()
  bufs = list.map(bufs, function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    local filetype = vim.api.nvim_buf_get_option(buf, "filetype")
    return {
      buf = buf,
      name = name,
      path = name,
      filetype = filetype,
      _additional_folder_depth = _global_additional_folder_depth,
    }
  end)
  ---@diagnostic disable-next-line: cast-local-type
  bufs = list.filter(bufs, utils.is_valid_buf)

  if bufs == nil then
    logger.warn("reload_all_buffers: no buffers found")
    return
  end

  bufs = utils.get_formatted_buffers(bufs)
  utils.sort_buffers(bufs, config.get_sort())
  _buf_list = bufs

  local payload = _get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

---@param index integer
function M.get_buffer_by_index(index)
  local buffers = _get_all_buffers()

  return buffers[index]
end

---@param bufnr integer
---@return Buffer | nil buffer, integer | nil index
function M.get_buffer_by_bufnr(bufnr)
  local buffers = _get_all_buffers()

  local index = list.find_index(buffers, function(buf)
    return buf.buf == bufnr
  end)

  if not index then
    return
  end

  return buffers[index], index
end

function M.get_active_buffer()
  local bufnr = _get_active_bufnr()

  if not bufnr then
    return nil, nil
  end

  return M.get_buffer_by_bufnr(bufnr)
end

function M.debug_buffers()
  print("active", _active_bufnr)
  print("buffers", vim.inspect(_buf_list))
end

return M
