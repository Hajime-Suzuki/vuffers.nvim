local str = require("utils.string")

local M = {}

function _ensure_file(filename)
  if vim.fn.filereadable(filename) == 0 then
    local folder = string.match(filename, "(.+)/.+$")
    vim.fn.mkdir(folder, "p")
    vim.fn.writefile({ vim.fn.json_encode({}) }, filename)
  end
end

---@param filename string
---@return unknown
function M.read_json_file(filename)
  _ensure_file(filename)
  local data = vim.fn.readfile(filename)
  return vim.fn.json_decode(table.concat(data, ""))
end

---@param filename string
---@param data table
function M.write_json_file(filename, data)
  _ensure_file(filename)
  vim.fn.writefile({ vim.fn.json_encode(data) }, filename)
end

function M.cwd_name()
  local cwd = vim.loop.cwd()
  return str.replace(cwd, "/", "_")
end

return M
