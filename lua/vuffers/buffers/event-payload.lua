local pinned = require("vuffers.buffers.pinned-buffers")
local logger = require("utils.logger")
local bufs = require("vuffers.buffers.buffers")

local M = {}

---@return ActivePinnedBufferChangedPayload | nil
function M.get_active_pinned_buf_changed_event_payload()
  local prev_bufnr = pinned.get_last_visited_pinned_bufnr()
  local current_bufnr = pinned.get_active_pinned_bufnr()

  ---@type integer | nil
  local prev_index
  if prev_bufnr then
    local _, i = bufs.get_buffer_by_bufnr(prev_bufnr)
    prev_index = i
  end

  ---@type integer | nil
  local current_index
  if current_bufnr then
    local _, i = bufs.get_buffer_by_bufnr(current_bufnr)
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
  local _, index = bufs.get_active_buffer()

  ---@type UnpinnedBuffersRemovedPayload
  return { buffers = _buf_list, active_buffer_index = index, removed_buffers = removed_buffers }
end
return M
