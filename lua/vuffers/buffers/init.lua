local bufs = require("vuffers.buffers.buffers")
local logger = require("utils.logger")
local event_bus = require("vuffers.event-bus")
local pinned = require("vuffers.buffers.pinned-buffers")
local active = require("vuffers.buffers.active-buffer")
local event_payload = require("vuffers.buffers.event-payload")
local utils = require("vuffers.buffers.buffer-utils")
local list = require("utils.list")
local config = require("vuffers.config")
local persist = require("vuffers.buffers.persist")

local M = {}

---@param buffer NativeBuffer
M.add_buffer = function(buffer)
  if bufs.add_buffer(buffer) then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

---@param args {index: number, new_name: string}
M.rename_buffer = function(args)
  bufs.rename_buffer(args)
  local payload = event_payload.get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

---@param args {index: number}
M.reset_custom_display_name = function(args)
  if bufs.reset_custom_display_name(args) then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

M.reset_custom_display_names = function()
  if bufs.reset_custom_display_names() then
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
  local path = active.get_active_buf_path()

  if not path then
    return nil, nil
  end

  return bufs.get_buffer_by_path(path)
end

M.get_buffer_by_index = bufs.get_buffer_by_index
M.get_buffer_by_path = bufs.get_buffer_by_path
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

---@param args {path: string}
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

------------------------------------
--   PINNED BUFS                --
------------------------------------

M.get_active_pinned_buf_path = pinned.get_active_pinned_buf_path

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

  local active_buf_path = active.get_active_buf_path()
  local is_active_buffer_removed = not pinned.is_pinned(active_buf_path)

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

---@param buf NativeBuffer
M.set_active_pinned_bufnr = function(buf)
  local is_changed = pinned.set_active_pinned_buf({ path = buf.file })
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

---@param buffer Buffer | NativeBuffer
M.is_pinned = function(buffer)
  return pinned.is_pinned(buffer.path or buffer.file)
end

------------------------------------
--   CUSTOM ORDER             --
------------------------------------

---@param args {origin_index: number, target_index: number}
M.move_buffer = function(args)
  local target_buf = bufs.get_buffer_by_index(args.target_index)
  local origin_buf = bufs.get_buffer_by_index(args.origin_index)

  if not origin_buf or not target_buf then
    return logger.warn("move_buffer: buffer not found", args)
  end

  if not pinned.is_pinned(origin_buf.path) and pinned.is_pinned(target_buf.path) then
    logger.warn("move_buffer: can not move unpinned buffer to pinned buffers area", args)
    return
  end

  if pinned.is_pinned(origin_buf.path) and not pinned.is_pinned(target_buf.path) then
    logger.warn("move_buffer: can not move pinned buffer to unpinned buffers area", args)
    return
  end

  if bufs.move_buffer(args) then
    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

------------------------------------
--   MISC                       --
------------------------------------

M.debug_buffers = function()
  local active_buf_path = active.get_active_buf_path()
  ---@diagnostic disable-next-line: cast-local-type
  local active_buf = active_buf_path and bufs.get_buffer_by_path(active_buf_path)

  local active_pinned = pinned.get_active_pinned_buf_path()
  print("active", active_buf and active_buf.name or "none")
  print("active_pinned", active_pinned or "none")
  print(
    "pinned",
    vim.inspect({ prev = pinned.get_last_visited_pinned_buf_path(), current = pinned.get_active_pinned_buf_path() })
  )
  print("pinned buffers", vim.inspect(pinned.get_pinned_bufs()))
  print("buffers", vim.inspect(bufs.get_buffers()))
end

--------- persistence ---------
M.is_restored_from_session = persist.is_restored_from_session
M.set_is_restored_from_session = persist.set_is_restored_from_session
M.persist_buffers = persist.persist_buffers
M.restore_buffers = function()
  persist.restore_pinned_buffers()
  persist.restore_buffers_from_file()
  bufs.set_buffers(utils.sort_buffers(bufs.get_buffers(), config.get_sort()))
  local payload = event_payload.get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end
M.persist_pinned_buffers = persist.persist_pinned_buffers
M.restore_pinned_buffers = persist.restore_pinned_buffers

return M
