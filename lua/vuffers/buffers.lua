local M = {}

---@type string[]
local _buffers = {}

function M.getAllBuffers()
  local bufs = vim.api.nvim_list_bufs()

  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    if buf ~= "" then
      table.insert(_buffers, name)
    end
  end

end

function M.getBuffers()
  return _buffers
end

return M
