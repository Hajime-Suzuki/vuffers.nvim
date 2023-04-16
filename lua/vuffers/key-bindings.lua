local buffers = require("vuffers.buffers")
local config = require("vuffers.config")
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
    local active_bufnr = buffers.get_current_bufnr()

    -- TODO: fix the limitation
    if buf.buf == active_bufnr then
      return
    end

    buffers.remove_buffer(buf.buf)
    config.get_handlers().on_delete_buffer(buf.buf)
  end, { noremap = true, silent = true, nowait = true, buffer = bufnr })
end

return M
