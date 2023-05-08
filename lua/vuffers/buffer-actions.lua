local logger = require("utils.logger")
local buffers = require("vuffers.buffers")
local window = require("vuffers.window")
local config = require("vuffers.config")
local list = require("utils.list")

local M = {}

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

  local window_nr = window.get_window_number()
  if window.is_open() and window_nr then
    vim.api.nvim_win_set_cursor(window_nr, { index, 0 })
  end

  vim.api.nvim_command(":b " .. target.buf)
end

---@param args {direction: 'next' | 'prev', count?: integer}
function M.next_or_prev_buffer(args)
  local count = args.count or vim.v.count
  count = count == 0 and 1 or count
  count = args.direction == "next" and count or -count

  local _, active_index = buffers.get_active_buffer()
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

  local window_nr = window.get_window_number()
  if window.is_open() and window_nr then
    vim.api.nvim_win_set_cursor(window_nr, { target_index, 0 })
  end

  vim.api.nvim_command(":b " .. target.buf)
end

function M.go_to_next_pinned_buffer()
  local next_pinned_buf = buffers.get_next_or_prev_pinned_buffer("next")
  if not next_pinned_buf then
    return
  end

  vim.api.nvim_command(":b " .. next_pinned_buf.buf)
end

function M.go_to_prev_pinned_buffer()
  local prev_pinned_buf = buffers.get_next_or_prev_pinned_buffer("prev")
  if not prev_pinned_buf then
    return
  end

  vim.api.nvim_command(":b " .. prev_pinned_buf.buf)
end

return M
