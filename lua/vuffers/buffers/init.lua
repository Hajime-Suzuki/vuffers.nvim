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
  local target = bufs.get_buffer_by_index(index)

  if not pinned.is_pinned(target.buf) then
    pinned.pin_buffer(target)

    bufs.set_buffers(utils.sort_buffers(bufs.get_buffers(), config.get_sort()))

    local payload = event_payload.get_buffer_list_changed_event_payload()
    event_bus.publish_buffer_list_changed(payload)
  end
end

---@param index integer
M.unpin_buffer = function(index)
  local target = bufs.get_buffer_by_index(index)

  if pinned.is_pinned(target.buf) then
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

  local is_active_buffer_removed = not pinned.is_pinned(active.get_active_bufnr())

  local _buf_list = bufs.get_buffers()

  if is_active_buffer_removed then
    local new_active_buf = list.find(_buf_list, function(buf)
      return pinned.is_pinned(buf.buf)
    end)
    active.set_active_bufnr(new_active_buf and new_active_buf.buf or nil)
  end

  local remaining_buffers = list.filter(_buf_list, function(buf)
    return pinned.is_pinned(buf.buf)
  end)

  local removed_buffers = list.filter(_buf_list, function(buf)
    return not pinned.is_pinned(buf.buf)
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

---@param buffer Buffer | NativeBuffer
M.is_pinned = function(buffer)
  return pinned.is_pinned(buffer.buf)
end

M.persist_buffers = bufs.persist_buffers

local loaded = false
local cwd = nil
---@param force? boolean
M.restore_buffers = function(force)
  if not force and (loaded or cwd == vim.loop.cwd()) then
    return
  end

  logger.info("restore_buffers: buffers are loaded from file")
  loaded = true
  cwd = vim.loop.cwd()

  bufs.load_buffers()
  pinned.restore_pinned_buffers()

  if not #bufs.get_buffers() then
    return
  end

  bufs.set_buffers(utils.sort_buffers(bufs.get_buffers(), config.get_sort()))

  local payload = event_payload.get_buffer_list_changed_event_payload()
  event_bus.publish_buffer_list_changed(payload)
end

return M
