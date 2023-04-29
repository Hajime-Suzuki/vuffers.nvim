local M = {}

function M.split(str, separator)
  local arr = {}
  local pattern = string.format("([^%s]+)", separator)
  str:gsub(pattern, function(substring)
    table.insert(arr, substring)
  end)
  return arr
end

function M.replace(str, what, with)
  what = string.gsub(what, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
  with = string.gsub(with, "[%%]", "%%%%") -- escape replacement
  return string.gsub(str, what, with)
end

return M
