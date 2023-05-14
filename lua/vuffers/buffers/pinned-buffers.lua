local event_bus = require("vuffers.event-bus")
local logger = require("utils.logger")
local utils = require("vuffers.buffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")

local bufs = function()
  return require("vuffers.buffers.buffers")
end

local M = {}

---@type integer[] first one is last, and the second one is current
local _pinned_bufnrs = {}

---@return Bufnr | nil
local function _get_last_visited_pinned_bufnr()
  return _pinned_bufnrs[1]
end

---@return Bufnr | nil
function M.get_active_pinned_bufnr()
  return _pinned_bufnrs[2]
end

---@return ActivePinnedBufferChangedPayload | nil
local function _get_active_pinned_buf_changed_event_payload()
  local prev_bufnr = _get_last_visited_pinned_bufnr()
  local current_bufnr = M.get_active_pinned_bufnr()

  local prev_index
  if prev_bufnr then
    local _, i = bufs().get_buffer_by_bufnr(prev_bufnr)
    prev_index = i
  end

  local current_index
  if current_bufnr then
    local _, i = bufs().get_buffer_by_bufnr(current_bufnr)
    current_index = i
  end

  if not current_index and not prev_index then
    return
  end

  ---@type ActivePinnedBufferChangedPayload
  local payload = { current_index = current_index, prev_index = prev_index }
  return payload
end

---@param bufnr Bufnr
---@param opts? { only_current_buf: boolean } -- when only_current_buf is true, it will only change the current pinned buffer
function M.set_active_pinned_bufnr(bufnr, opts)
  local _buf_list = bufs().get_buffers()
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

---@param removed_buffers Buffer[]
---@return UnpinnedBuffersRemovedPayload
local function _get_unpinned_buffers_removed_event_payload(removed_buffers)
  local _buf_list = bufs().get_buffers()
  local _, index = bufs().get_active_buffer()

  ---@type UnpinnedBuffersRemovedPayload
  local payload = { buffers = _buf_list, active_buffer_index = index, removed_buffers = removed_buffers }
  return payload
end

---@param index integer
function M.pin_buffer(index)
  local _buf_list = bufs().get_buffers()
  local target = _buf_list[index]
  if not target or target.is_pinned then
    return
  end
  target.is_pinned = true
  M.set_active_pinned_bufnr(target.buf)

  local bs = bufs().get_buffers()
  bufs().set_buffers(utils.sort_buffers(bs, config.get_sort()))

  local payload = bufs()._get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

---@param index integer
function M.unpin_buffer(index)
  local _buf_list = bufs().get_buffers()
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

  bufs().set_buffers(utils.sort_buffers(_buf_list, config.get_sort()))

  local payload = bufs()._get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

local function _get_pinned_bufs()
  local _buf_list = bufs().get_buffers()
  return list.filter(_buf_list, function(buf)
    return buf.is_pinned
  end)
end

local function _get_unpinned_bufs()
  local _buf_list = bufs().get_buffers()
  return list.filter(_buf_list, function(buf)
    return not buf.is_pinned
  end)
end

function M.remove_unpinned_buffers()
  local to_remove = _get_unpinned_bufs()

  if not to_remove then
    return
  end

  local active_bufnr = bufs().get_active_bufnr()

  local is_active_buffer_removed = list.find_index(to_remove or {}, function(buf)
    return buf.buf == active_bufnr
  end)

  local _buf_list = bufs().get_buffers()
  if is_active_buffer_removed then
    local new_active_buf = list.find(_buf_list, function(buf)
      return buf.is_pinned
    end)
    bufs()._set_active_bufnr(new_active_buf and new_active_buf.buf or nil)
  end

  local new_bufs = _get_pinned_bufs()
  bufs().set_buffers(utils.sort_buffers(new_bufs or {}, config.get_sort()))

  local payload = _get_unpinned_buffers_removed_event_payload(to_remove)
  event_bus.publish_unpinned_buffers_removed(payload)
end

function M.get_active_pinned_buffer()
  local bufnr = M.get_active_pinned_bufnr()

  if not bufnr then
    return nil, nil
  end

  return bufs().get_buffer_by_bufnr(bufnr)
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

return M
