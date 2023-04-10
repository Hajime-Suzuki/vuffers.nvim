local utils = require("vuffers.utils")

local M = {}

function M.get_all_buffers()
  ---@type string[]
  local _buffers = {}

  local bufs = vim.api.nvim_list_bufs()

  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)

    if name ~= "" and name ~= "/" then
      table.insert(_buffers, name)
    end
  end

  return _buffers
end

---@return string[]
function M.get_all_buffer_names()
  local buffers = M.get_all_buffers()

  return utils.get_file_names(buffers)
end

return M
