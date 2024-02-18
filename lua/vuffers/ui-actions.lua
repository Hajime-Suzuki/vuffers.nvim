-- actions triggered via UI window

local buffers = require("vuffers.buffers")
local config = require("vuffers.config")

local M = {}
function M.open_buffer()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  local buf = buffers.get_buffer_by_index(row)

  vim.api.nvim_command("wincmd l" .. "|" .. "buffer " .. buf.buf)
end

function M.delete_buffer()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  local buf = buffers.get_buffer_by_index(row)
  local active = buffers.get_active_buffer()

  if buffers.is_pinned(buf) then
    return
  end

  if not active or not buf then
    return
  end

  if buf.buf ~= active.buf then
    buffers.remove_buffer({ path = buf.path })
    config.get_handlers().on_delete_buffer(buf.buf)
    return
  end

  local next_buf = buffers.get_buffer_by_index(row + 1) or buffers.get_buffer_by_index(row - 1)
  if not next_buf then
    print("can not delete last buffer")
    return
  end

  -- can not close buffer if it is active buffer
  vim.api.nvim_command("wincmd l" .. "|" .. "buffer " .. next_buf.buf .. "|" .. "wincmd h")

  buffers.remove_buffer({ path = buf.path })
  config.get_handlers().on_delete_buffer(buf.buf)
end

function M.pin_buffer()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  buffers.pin_buffer(row)
end

function M.unpin_buffer()
  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  buffers.unpin_buffer(row)
end

function M.rename_buffer()
  local pos = vim.api.nvim_win_get_cursor(0)
  local buf = buffers.get_buffer_by_index(pos[1])
  vim.ui.input({ prompt = "new name? ", default = buf.name }, function(new_name)
    if not new_name then
      return
    end
    buffers.rename_buffer({ index = pos[1], new_name = new_name })
  end)
end

function M.reset_custom_display_name()
  local pos = vim.api.nvim_win_get_cursor(0)
  buffers.reset_custom_display_name({ index = pos[1] })
end

function M.reset_custom_display_names()
  buffers.reset_custom_display_names()
end

---@param args {direction: 'next' | 'prev', count?: integer}
function M.move_current_buffer_by_count(args)
  local count = args.count or vim.v.count or 0
  count = count == 0 and 1 or count

  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  local col = pos[2]
  local buf = buffers.get_buffer_by_index(row)

  if not buf then
    return
  end

  local target_index = row + (args.direction == "next" and count or -count)

  if buffers.move_buffer({ origin_index = row, target_index = target_index }) then
    vim.api.nvim_win_set_cursor(0, { target_index, col })
  end
end

function M.move_buffer_to_index()
  local target_index = vim.v.count
  if not target_index or target_index == 0 then
    return
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1]
  local col = pos[2]
  local buf = buffers.get_buffer_by_index(row)

  if not buf then
    return
  end

  if buffers.move_buffer({ origin_index = row, target_index = target_index }) then
    vim.api.nvim_win_set_cursor(0, { target_index, col })
  end
end

return M
