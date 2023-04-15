local utils = require("vuffers.buffer-utils")
local list = require("utils.list")

local M = {}

function M.get_all_buffers()
  ---@type {buf: number, name: string, index: number}[]
  local _buffers = {}

  local bufs = vim.api.nvim_list_bufs()

  for i, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)

    if name ~= "" and name ~= "/" then
      table.insert(_buffers, { buf = buf, name = name, index = i })
    end
  end

  _buffers = utils.get_file_names(_buffers)

  return _buffers
end

function M.get_all_buffer_names()
  local buffers = M.get_all_buffers()

  return list.map(buffers, function(buf)
    return buf.name
  end)
end

---@param bufnr number
function M.get_selected_buffer(bufnr)
  local buffers = M.get_all_buffers()

  return list.find(buffers, function(buf)
    return buf.buf == bufnr
  end)
end

return M
