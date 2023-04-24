local logger = require("utils.logger")
local buffers = require("vuffers.buffers")
local config = require("vuffers.config")
local window = require("vuffers.window")

local M = {}

-- TODO: move to window actions
function M.open_buffer()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  local buf = buffers.get_buffer_by_index(row)

  vim.api.nvim_command("wincmd l" .. "|" .. "buffer " .. buf.buf)
end

-- TODO: move to window actions
function M.delete_buffer()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  local buf = buffers.get_buffer_by_index(row)
  local active = buffers.get_active_buffer()
  local next_buf = buffers.get_buffer_by_index(row + 1) or buffers.get_buffer_by_index(row - 1)

  if not active or not buf then
    return
  end

  if buf.buf ~= active.buf then
    buffers.remove_buffer({ bufnr = buf.buf })
    config.get_handlers().on_delete_buffer(buf.buf)
    return
  end

  if not next_buf then
    print("can not delete last buffer")
    return
  end

  -- can not close buffer if it is active buffer
  vim.api.nvim_command("wincmd l" .. "|" .. "buffer " .. next_buf.buf .. "|" .. "wincmd h")

  buffers.remove_buffer({ bufnr = buf.buf })
  config.get_handlers().on_delete_buffer(buf.buf)
end

---@param _index? integer
function M.go_to_buffer_by_index(_index)
  local num_of_buffers = buffers.get_num_of_buffers()

  local index = (_index or vim.v.count)

  if index == 0 then
    return
  end

  index = (1 <= index and index <= num_of_buffers) and index or (index < 1 and 1 or num_of_buffers)

  local target = buffers.get_buffer_by_index(index)

  if not target then
    logger.warn("ui:go_to_buffer_by_index: target buffer not found")
    return
  end

  if not window.is_hidden() then
    local window_id = window.get_window_id()
    vim.api.nvim_win_set_cursor(window_id, { index, 0 })
  end

  vim.api.nvim_command(":b " .. target.buf)
end

---@param args {direction: 'next' | 'prev', count?: integer}
function M.next_or_prev_buffer(args)
  local count = args.count or vim.v.count
  count = count == 0 and 1 or count
  count = args.direction == "next" and count or -count

  local active_index = buffers.get_active_buffer_index()
  if not active_index then
    logger.warn("ui:go_to_buffer_by_count: active buffer not found")
    return
  end

  local num_of_buffers = buffers.get_num_of_buffers()
  local target_index = active_index + count
  target_index = target_index < 1 and 1 or (target_index > num_of_buffers and num_of_buffers or target_index)

  logger.debug("ui:go_to_buffer_by_count: target index: " .. target_index)

  local target = buffers.get_buffer_by_index(target_index)

  if not target then
    logger.warn("ui:go_to_buffer_by_count: active buffer not found")
    return
  end

  if not window.is_hidden() then
    local window_id = window.get_window_id()
    vim.api.nvim_win_set_cursor(window_id, { target_index, 0 })
  end

  vim.api.nvim_command(":b " .. target.buf)
end

return M
