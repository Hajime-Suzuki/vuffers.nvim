local bufs = require("vuffers.buffers.buffers")
local logger = require("utils.logger")
local event_bus = require("vuffers.event-bus")
local pinned = require("vuffers.buffers.pinned-buffers")
local event_payload = require("vuffers.buffers.event-payload")

local M = {}

M.add_buffer = bufs.add_buffer
M.change_sort = bufs.change_sort
M.debug_buffers = bufs.debug_buffers
M.decrement_additional_folder_depth = bufs.decrement_additional_folder_depth
M.get_active_buffer = bufs.get_active_buffer
M.get_active_bufnr = bufs.get_active_bufnr
M.get_buffer_by_bufnr = bufs.get_buffer_by_bufnr
M.get_buffer_by_index = bufs.get_buffer_by_index
M.get_buffers = bufs.get_buffers
M.get_num_of_buffers = bufs.get_num_of_buffers
M.increment_additional_folder_depth = bufs.increment_additional_folder_depth
M.reload_buffers = bufs.reload_buffers
M.remove_buffer = bufs.remove_buffer
M.reset_buffers = bufs.reset_buffers
M.set_active_bufnr = bufs.set_active_bufnr
M.set_buffers = bufs.set_buffers
M._get_buffer_list_changed_event_payload = bufs._get_buffer_list_changed_event_payload
M._set_active_bufnr = bufs._set_active_bufnr

M.get_active_pinned_bufnr = pinned.get_active_pinned_bufnr

---@param index integer
M.pin_buffer = function(index)
  pinned.pin_buffer(index)
  local payload = bufs._get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

M.remove_unpinned_buffers = function()
  local removed_buffers = pinned.remove_unpinned_buffers()
  if not removed_buffers then
    return
  end
  local payload = event_payload.get_unpinned_buffers_removed_payload(removed_buffers)
  event_bus.publish_unpinned_buffers_removed(payload)
end

---@param bufnr Bufnr
M.set_active_pinned_bufnr = function(bufnr)
  local is_changed = pinned.set_active_pinned_bufnr(bufnr)
  if not is_changed then
    return
  end

  local payload = event_payload.get_active_pinned_buf_changed_event_payload()

  if not payload then
    logger.debug("set_active_pinned_bufnr: could not find the buffer index")
    return
  end

  event_bus.publish_active_pinned_buffer_changed(payload)
end

---@param index integer
M.unpin_buffer = function(index)
  pinned.unpin_buffer(index)

  local payload = bufs._get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

return M
