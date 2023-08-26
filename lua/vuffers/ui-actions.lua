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

return M
