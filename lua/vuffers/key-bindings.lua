local buffers = require("vuffers.buffers")
local config = require("vuffers.config")
local events = require("vuffers.events")
local M = {}

function M.init(bufnr)
  vim.keymap.set("n", "<CR>", function()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1]
    local buf = buffers.get_buffer_by_index(row)

    vim.api.nvim_command("wincmd l" .. "|" .. "buffer " .. buf.buf)
  end, { noremap = true, silent = true, nowait = true, buffer = bufnr })

  vim.keymap.set("n", "d", function()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1]
    local buf = buffers.get_buffer_by_index(row)
    local active = buffers.get_current_buffer()
    local next_buf = buffers.get_buffer_by_index(row + 1) or buffers.get_buffer_by_index(row - 1)

    if not active then
      print("active buffer not found")
      return
    end

    if buf.buf == active.buf then
      if not next_buf then
        print("can not delete last buffer")
        return
      end

      vim.api.nvim_command("wincmd l" .. "|" .. "buffer " .. next_buf.buf .. "|" .. "wincmd h")

      buffers.remove_buffer({ bufnr = buf.buf })
      config.get_handlers().on_delete_buffer(buf.buf)
      buffers.set_current_bufnr({ buf = next_buf.buf, file = next_buf.path })
      return
    end

    buffers.remove_buffer({ bufnr = buf.buf })
    config.get_handlers().on_delete_buffer(buf.buf)
    buffers.set_current_bufnr({ buf = active.buf, file = active.path })
  end, { noremap = true, silent = true, nowait = true, buffer = bufnr })
end

return M
