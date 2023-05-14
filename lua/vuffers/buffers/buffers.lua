local event_bus = require("vuffers.event-bus")
local logger = require("utils.logger")
local utils = require("vuffers.buffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")

--------------types >>----------------

---@class Buffer
---@field buf Bufnr
---@field name string name that will be displayed in the buffer list, which considers additional folder depth
---@field path string full path
---@field ext string
---@field is_pinned boolean
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

---@alias Bufnr integer
--------------<<types ----------------

local M = {}

---@type Buffer[]
local _buf_list = {}

---@type number | nil
local _active_bufnr = nil

---@type integer[] first one is last, and the second one is current
local _pinned_bufnrs = {}

local function _get_all_buffers()
  return _buf_list
end

local function _get_active_bufnr()
  return _active_bufnr
end

---@return Bufnr | nil
local function _get_last_visited_pinned_bufnr()
  return _pinned_bufnrs[1]
end

---@return Bufnr | nil
function M.get_active_pinned_bufnr()
  return _pinned_bufnrs[2]
end

---@type integer | nil How many more parents the UI shows. This can not go below 0
local _global_additional_folder_depth = 0

---@return ActiveBufferChangedPayload
local function _get_active_buf_changed_event_payload()
  local _, index = M.get_active_buffer()

  ---@type ActiveBufferChangedPayload
  local payload = { index = index or 1 }
  return payload
end

---@return ActivePinnedBufferChangedPayload | nil
local function _get_active_pinned_buf_changed_event_payload()
  local prev_bufnr = _get_last_visited_pinned_bufnr()
  local current_bufnr = M.get_active_pinned_bufnr()

  local prev_index
  if prev_bufnr then
    local _, i = M.get_buffer_by_bufnr(prev_bufnr)
    prev_index = i
  end

  local current_index
  if current_bufnr then
    local _, i = M.get_buffer_by_bufnr(current_bufnr)
    current_index = i
  end

  if not current_index and not prev_index then
    return
  end

  ---@type ActivePinnedBufferChangedPayload
  local payload = { current_index = current_index, prev_index = prev_index }
  return payload
end

---@return BufferListChangedPayload
local function _get_buffer_list_changed_event_payload()
  local _, active_index = M.get_active_buffer()
  local _, active_pinned_index = M.get_active_pinned_buffer()

  ---@type BufferListChangedPayload
  local payload =
    { buffers = _buf_list, active_buffer_index = active_index, active_pinned_buffer_index = active_pinned_index }
  return payload
end

---@param removed_buffers Buffer[]
---@return UnpinnedBuffersRemovedPayload
local function _get_unpinned_buffers_removed_event_payload(removed_buffers)
  local _, index = M.get_active_buffer()

  ---@type UnpinnedBuffersRemovedPayload
  local payload = { buffers = _buf_list, active_buffer_index = index, removed_buffers = removed_buffers }
  return payload
end

---@param buffer {path: string, buf: integer}
function M.set_active_bufnr(buffer)
  _active_bufnr = buffer.buf

  local event_payload = _get_active_buf_changed_event_payload()
  event_bus.publish_active_buffer_changed(event_payload)
end

---@param bufnr Bufnr
---@param opts? { only_current_buf: boolean } -- when only_current_buf is true, it will only change the current pinned buffer
function M.set_active_pinned_bufnr(bufnr, opts)
  local prev_pos = 1
  local current_pos = 2

  local is_buf_pinned = list.find_index(_buf_list, function(b)
    return b.is_pinned and b.buf == bufnr
  end) ~= nil

  if not is_buf_pinned then
    return
  end

  if opts and opts.only_current_buf then
    _pinned_bufnrs[current_pos] = bufnr
    return
  end

  _pinned_bufnrs[prev_pos] = _pinned_bufnrs[current_pos] or bufnr
  _pinned_bufnrs[current_pos] = bufnr

  local payload = _get_active_pinned_buf_changed_event_payload()
  if not payload then
    logger.error("set_active_pinned_bufnr: could not find the buffer index")
    return
  end
  event_bus.publish_active_pinned_buffer_changed(payload)
end

function M._reset_buffers()
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
  buffers = utils.sort_buffers(buffers, config.get_sort())
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
    buffers = utils.sort_buffers(buffers, config.get_sort())
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
  _buf_list = utils.sort_buffers(_buf_list, config.get_sort())

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
  bufs = utils.sort_buffers(bufs, config.get_sort())
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
  if not target or target.is_pinned then
    return
  end
  target.is_pinned = true
  M.set_active_pinned_bufnr(target.buf)

  _buf_list = utils.sort_buffers(_buf_list, config.get_sort())

  local payload = _get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

---@param index integer
function M.unpin_buffer(index)
  local target = _buf_list[index]

  if not target or not target.is_pinned then
    return
  end

  local target_index = list.find_index(_buf_list, function(buf)
    return buf.is_pinned and buf.buf == target.buf
  end)

  -- pinned buffers are always next to each other
  local next_pinned = list.find({ _buf_list[target_index + 1] or {}, _buf_list[target_index - 1] or {} }, function(item)
    return item.is_pinned
  end)

  logger.debug("unpin_buffer: next pinned buffer", next_pinned)
  if not next_pinned then
    -- there is no pinned buffer any more
    _pinned_bufnrs = {}
  else
    logger.debug("unpin_buffer: next pinned buffer found", { next_pinned = next_pinned })
    M.set_active_pinned_bufnr(next_pinned.buf, { only_current_buf = true })
  end

  target.is_pinned = false

  _buf_list = utils.sort_buffers(_buf_list, config.get_sort())

  local payload = _get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

local function _get_pinned_bufs()
  return list.filter(_buf_list, function(buf)
    return buf.is_pinned
  end)
end

local function _get_unpinned_bufs()
  return list.filter(_buf_list, function(buf)
    return not buf.is_pinned
  end)
end

function M.remove_unpinned_buffers()
  local to_remove = _get_unpinned_bufs()

  if not to_remove then
    return
  end

  local active_bufnr = _get_active_bufnr()

  local is_active_buffer_removed = list.find_index(to_remove or {}, function(buf)
    return buf.buf == active_bufnr
  end)

  if is_active_buffer_removed then
    local new_active_buf = list.find(_buf_list, function(buf)
      return buf.is_pinned
    end)
    _active_bufnr = new_active_buf and new_active_buf.buf or nil
  end

  local new_bufs = _get_pinned_bufs()
  _buf_list = utils.sort_buffers(new_bufs or {}, config.get_sort())

  local payload = _get_unpinned_buffers_removed_event_payload(to_remove)
  event_bus.publish_unpinned_buffers_removed(payload)
end

function M.reload_buffers()
  if #_buf_list == 0 then
    logger.debug("reload_buffers: buffer list is empty. reload all buffers")
    return M.reset_buffers()
  end

  logger.debug("reload_buffers: reloading buffers", { buf_list = _buf_list })
  local payload = _get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

function M.reset_buffers()
  M._reset_buffers()

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
  bufs = utils.sort_buffers(bufs, config.get_sort())
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

function M.get_active_pinned_buffer()
  local bufnr = M.get_active_pinned_bufnr()

  if not bufnr then
    return nil, nil
  end

  return M.get_buffer_by_bufnr(bufnr)
end

---@param type 'next' | 'prev'
function M.get_next_or_prev_pinned_buffer(type)
  local currently_pinned_bufnr = M.get_active_pinned_bufnr()

  if not currently_pinned_bufnr then
    return
  end

  local pinned_buffers = _get_pinned_bufs()

  if not pinned_buffers then
    return
  end

  local currently_pinned_buf_index = list.find_index(pinned_buffers, function(buf)
    return buf.buf == currently_pinned_bufnr
  end)

  if not currently_pinned_buf_index then
    return
  end

  local target_buf_index = currently_pinned_buf_index + (type == "next" and 1 or -1)
  return pinned_buffers[target_buf_index]
end

function M.debug_buffers()
  local active = M.get_active_buffer()
  local active_pinned = M.get_active_pinned_buffer()
  print("active", active and active.name or "none")
  print("active_pinned", active_pinned and active_pinned.name or "none")
  print("buffers", vim.inspect(_buf_list))
  print("pinned", vim.inspect({ prev = _pinned_bufnrs[1], current = _pinned_bufnrs[2] }))
end

return M
