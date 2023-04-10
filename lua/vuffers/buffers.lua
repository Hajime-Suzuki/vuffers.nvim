local M = {}

---@type string[]
local _buffers = {}

function M.get_all_buffers()
  local bufs = vim.api.nvim_list_bufs()

  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)

    if name ~= "" then
      vim.notify(vim.inspect(_buffers))
      table.insert(_buffers, name)
    end
  end

  return _buffers
end

return M
