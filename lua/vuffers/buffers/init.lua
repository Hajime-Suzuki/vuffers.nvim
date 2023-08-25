local bufs = require("vuffers.buffers.buffers")
local logger = require("utils.logger")
local event_bus = require("vuffers.event-bus")
local pinned = require("vuffers.buffers.pinned-buffers")
local active = require("vuffers.buffers.active-buffer")
local event_payload = require("vuffers.buffers.event-payload")
local utils = require("vuffers.buffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")

local M = {}

---@param buffer NativeBuffer
M.add_buffer = function(buffer)
  if bufs.add_buffer(buffer) then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

---@param {index: number, new_name: string}
M.rename_buffer = function(args)
  bufs.rename_buffer(args)
  local payload = event_payload.get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

M.change_sort = function()
  bufs.change_sort()
  local payload = event_payload.get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

M.get_active_buffer = function()
  local path = active.get_active_buf_path()

  if not path then
    return nil, nil
  end

  return bufs.get_buffer_by_path(path)
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

-- TODO: rename and move to buffers.init. this is just publishing event for UI.
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

---@param buf Buffer | NativeBuffer
M.set_active_buf = function(buf)
  active.set_active_buf({ path = buf.path or buf.file })
  local payload = event_payload.get_active_buf_changed_event_payload()
  event_bus.publish_active_buffer_changed(payload)
end

M.set_buffers = bufs.set_buffers -- TODO: remove
M.get_active_pinned_bufnr = pinned.get_active_pinned_bufnr

---@param index integer
M.pin_buffer = function(index)
  local target = bufs.get_buffer_by_index(index)

  if not pinned.is_pinned(target.path) then
    pinned.pin_buffer(target)

    bufs.set_buffers(utils.sort_buffers(bufs.get_buffers(), config.get_sort()))

    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

---@param index integer
M.unpin_buffer = function(index)
  local target = bufs.get_buffer_by_index(index)

  if pinned.is_pinned(target.path) then
    pinned.unpin_buffer(target)
    bufs.set_buffers(utils.sort_buffers(bufs.get_buffers(), config.get_sort()))

    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

M.remove_unpinned_buffers = function()
  if pinned.is_empty() then
    return
  end

  -- TODO: remove when is_pinned accepts path
  local active_buf_path = active.get_active_buf_path()
  local active_buf = active_buf_path and bufs.get_buffer_by_path(active_buf_path)

  local is_active_buffer_removed = active_buf and not pinned.is_pinned(active_buf.path)

  local _buf_list = bufs.get_buffers()

  if is_active_buffer_removed then
    local new_active_buf = list.find(_buf_list, function(buf)
      return pinned.is_pinned(buf.path)
    end)
    active.set_active_buf(new_active_buf)
  end

  local remaining_buffers = list.filter(_buf_list, function(buf)
    return pinned.is_pinned(buf.path)
  end)

  local removed_buffers = list.filter(_buf_list, function(buf)
    return not pinned.is_pinned(buf.path)
  end)

  if not removed_buffers then
    return
  end

  bufs.set_buffers(utils.sort_buffers(remaining_buffers or {}, config.get_sort()))

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

M.get_next_or_prev_pinned_buffer = pinned.get_next_or_prev_pinned_buffer

M.debug_buffers = function()
  local active_buf_path = active.get_active_buf_path()
  ---@diagnostic disable-next-line: cast-local-type
  local active_buf = active_buf_path and bufs.get_buffer_by_path(active_buf_path)

  local active_pinned = pinned.get_active_pinned_bufnr()
  print("active", active_buf and active_buf.name or "none")
  print("active_pinned", active_pinned or "none")
  print(
    "pinned",
    vim.inspect({ prev = pinned.get_last_visited_pinned_bufnr(), current = pinned.get_active_pinned_bufnr() })
  )
  print("buffers", vim.inspect(bufs.get_buffers()))
end

---@param buffer Buffer | NativeBuffer
M.is_pinned = function(buffer)
  return pinned.is_pinned(buffer.path or buffer.file)
end

M.persist_buffers = bufs.persist_buffers

M.is_restored_from_session = false
M.set_is_restored_from_session = function(value)
  M.is_restored_from_session = value
end

M.restore_buffers = function()
  pinned.restore_pinned_buffers()
  bufs.restore_buffers_from_file()
  bufs.set_buffers(utils.sort_buffers(bufs.get_buffers(), config.get_sort()))

  local payload = event_payload.get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

M.persist_pinned_buffers = pinned.persist_pinned_buffers
M.restore_pinned_buffers = pinned.restore_pinned_buffers

return M
