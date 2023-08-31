local pinned = require("vuffers.buffers.pinned-buffers")
local logger = require("utils.logger")
local bufs = require("vuffers.buffers.buffers")
local active = require("vuffers.buffers.active-buffer")

local M = {}

local function _get_active_buffer()
  local path = active.get_active_buf_path()
  if not path then
    return nil, nil
  end

  return bufs.get_buffer_by_path(path)
end

---@return ActivePinnedBufferChangedPayload | nil
function M.get_active_pinned_buf_changed_event_payload()
  local prev_buf_path = pinned.get_last_visited_pinned_buf_path()
  local current_buf_path = pinned.get_active_pinned_buf_path()

  ---@type integer | nil
  local prev_index
  if prev_buf_path then
    local _, i = bufs.get_buffer_by_path(prev_buf_path)
    prev_index = i
  end

  ---@type integer | nil
  local current_index
  if current_buf_path then
    local _, i = bufs.get_buffer_by_path(current_buf_path)
    current_index = i
  end

  logger.debug(
    "get_active_pinned_buf_changed_event_payload: ",
    { current_index = current_index, prev_index = prev_index }
  )

  if not current_index and not prev_index then
    return
  end

  ---@type ActivePinnedBufferChangedPayload
  local payload = { current_index = current_index, prev_index = prev_index }
  return payload
end

---@param removed_buffers Buffer[]
---@return UnpinnedBuffersRemovedPayload
function M.get_unpinned_buffers_removed_payload(removed_buffers)
  local _buf_list = bufs.get_buffers()
  local _, index = _get_active_buffer()

  ---@type UnpinnedBuffersRemovedPayload
  return { buffers = _buf_list, active_buffer_index = index, removed_buffers = removed_buffers }
end

---@return ActiveBufferChangedPayload
function M.get_active_buf_changed_event_payload()
  local _, index = _get_active_buffer()

  ---@type ActiveBufferChangedPayload
  local payload = { index = index or 1 }
  return payload
end

---@return BufferListChangedPayload
function M.get_buffer_list_changed_event_payload()
  local _buf_list = bufs.get_buffers()
  local _, active_index = _get_active_buffer()
  local _, active_pinned_index = pinned.get_active_pinned_buffer()

  ---@type BufferListChangedPayload
  local payload =
    { buffers = _buf_list, active_buffer_index = active_index, active_pinned_buffer_index = active_pinned_index }
  return payload
end

return M
