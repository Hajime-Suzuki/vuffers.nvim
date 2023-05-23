local bufs = require("vuffers.buffers.buffers")
local logger = require("utils.logger")
local event_bus = require("vuffers.event-bus")
local pinned = require("vuffers.buffers.pinned-buffers")
local active = require("vuffers.buffers.active-buffer")
local event_payload = require("vuffers.buffers.event-payload")
local utils = require("vuffers.buffers.buffer-utils")
local config = require("vuffers.config")

local M = {}

---@param buffer NativeBuffer
M.add_buffer = function(buffer)
  if bufs.add_buffer(buffer) then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

M.change_sort = function()
  bufs.change_sort()
  local payload = event_payload.get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

M.get_active_buffer = function()
  local bufnr = active.get_active_bufnr()

  if not bufnr then
    return nil, nil
  end

  return bufs.get_buffer_by_bufnr(bufnr)
end

M.get_buffer_by_bufnr = bufs.get_buffer_by_bufnr
M.get_buffer_by_index = bufs.get_buffer_by_index
M.get_num_of_buffers = bufs.get_num_of_buffers

M.increment_additional_folder_depth = function()
  if bufs.increment_additional_folder_depth() then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

M.decrement_additional_folder_depth = function()
  if bufs.decrement_additional_folder_depth() then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

M.reload_buffers = function()
  if bufs.get_num_of_buffers() == 0 then
    return M.reset_buffers()
  end

  local payload = event_payload.get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

---@param args {bufnr: number}
M.remove_buffer = function(args)
  if bufs.remove_buffer(args) then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

M.reset_buffers = function()
  if bufs.reset_buffers() then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

---@param bufnr Bufnr
M.set_active_bufnr = function(bufnr)
  active.set_active_bufnr(bufnr)
  local payload = event_payload.get_active_buf_changed_event_payload()
  event_bus.publish_active_buffer_changed(payload)
end

M.set_buffers = bufs.set_buffers -- TODO: remove
M.get_active_pinned_bufnr = pinned.get_active_pinned_bufnr

---@param index integer
M.pin_buffer = function(index)
  if pinned.pin_buffer(index) then
    local target = bufs.get_buffer_by_index(index)

    bufs.update_buffer({ index = index }, { is_pinned = true })
    bufs.set_buffers(utils.sort_buffers(bufs.get_buffers(), config.get_sort()))

    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
    pinned.persist_pinned_buffer(target)
  end
end

M.remove_unpinned_buffers = function()
  local remaining_bufs, removed_buffers = pinned.remove_unpinned_buffers(active.get_active_bufnr())
  if not removed_buffers then
    return
  end
  bufs.set_buffers(utils.sort_buffers(remaining_bufs or {}, config.get_sort()))

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
  if pinned.unpin_buffer(index) then
    local target = bufs.get_buffer_by_index(index)
    bufs.update_buffer({ index = index }, { is_pinned = false })
    bufs.set_buffers(utils.sort_buffers(bufs.get_buffers(), config.get_sort()))

    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
    pinned.remove_persisted_pinned_buffer(target)
  end
end

M.get_next_or_prev_pinned_buffer = pinned.get_next_or_prev_pinned_buffer

M.debug_buffers = function()
  local active_buf = active.get_active_bufnr()
  ---@diagnostic disable-next-line: cast-local-type
  active_buf = active_buf and bufs.get_buffer_by_bufnr(active_buf) or nil

  local active_pinned = pinned.get_active_pinned_bufnr()
  print("active", active_buf and active_buf.name or "none")
  print("active_pinned", active_pinned or "none")
  print(
    "pinned",
    vim.inspect({ prev = pinned.get_last_visited_pinned_bufnr(), current = pinned.get_active_pinned_bufnr() })
  )
  print("buffers", vim.inspect(bufs.get_buffers()))
end

return M
