local M = {}

function M.split(str, separator)
  local arr = {}
  local pattern = string.format("([^%s]+)", separator)
  str:gsub(pattern, function(substring)
    table.insert(arr, substring)
  end)
  return arr
end

return M
