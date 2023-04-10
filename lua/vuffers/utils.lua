local M = {}

---@param file_paths string[]
---@return string[]
function M.get_file_names(file_paths)
  local file_names = {}
  local seen = {}

  for _, path in ipairs(file_paths) do
    local file_name = string.match(path, ".+/(.+)$")
    if file_name == nil then
      file_name = path
    end

    table.insert(file_names, file_name)
  end

  return file_names
end

return M
