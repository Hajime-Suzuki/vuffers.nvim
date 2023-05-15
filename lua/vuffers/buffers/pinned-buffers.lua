local logger = require("utils.logger")
local utils = require("vuffers.buffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")

local bufs = function()
  return require("vuffers.buffers.buffers")
end

local active = function()
  return require("vuffers.buffers.active-buffer")
end

local M = {}

---@type integer[] first one is last, and the second one is current
local _pinned_bufnrs = {}

---@return Bufnr | nil
function M.get_last_visited_pinned_bufnr()
  return _pinned_bufnrs[1]
end

---@return Bufnr | nil
function M.get_active_pinned_bufnr()
  return _pinned_bufnrs[2]
end

---@param bufnr Bufnr
function M.set_active_pinned_bufnr(bufnr)
  local _buf_list = bufs().get_buffers()
  local prev_pos = 1
  local current_pos = 2

  local is_buf_pinned = list.find_index(_buf_list, function(b)
    return b.is_pinned and b.buf == bufnr
  end) ~= nil

  if not is_buf_pinned then
    return
  end

  _pinned_bufnrs[prev_pos] = _pinned_bufnrs[current_pos] or bufnr
  _pinned_bufnrs[current_pos] = bufnr

  return true
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
    M.set_active_pinned_bufnr(next_pinned.buf)
  end

  target.is_pinned = false

  bufs().set_buffers(utils.sort_buffers(_buf_list, config.get_sort()))
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

---@param active_bufnr? Bufnr
function M.remove_unpinned_buffers(active_bufnr)
  local to_remove = _get_unpinned_bufs()

  if not to_remove then
    return
  end

  local is_active_buffer_removed = list.find_index(to_remove or {}, function(buf)
    return buf.buf == active_bufnr
  end)

  local _buf_list = bufs().get_buffers()
  if is_active_buffer_removed then
    local new_active_buf = list.find(_buf_list, function(buf)
      return buf.is_pinned
    end)
    active().set_active_bufnr(new_active_buf and new_active_buf.buf or nil)
  end

  local new_bufs = _get_pinned_bufs()
  bufs().set_buffers(utils.sort_buffers(new_bufs or {}, config.get_sort()))

  return to_remove
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
