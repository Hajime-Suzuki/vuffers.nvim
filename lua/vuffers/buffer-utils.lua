local list = require("utils.list")
local plenary = require("plenary")
local M = {}

local function split_path(path)
  local components = {}
  for component in string.gmatch(path, "[^\\/]+") do
    table.insert(components, component)
  end
  return components
end

---@param current_file_path string[]
---@param duplicate_file_path string[]
local function get_unique_names(current_file_path, duplicate_file_path)
  local output1 = ""
  local output2 = ""

  local i = #current_file_path
  local j = #duplicate_file_path

  while i > 0 or j > 0 do
    local prefix1 = current_file_path[i]
    local prefix2 = duplicate_file_path[j]

    output1 = prefix1 and prefix1 .. "/" .. output1 or output1
    output2 = prefix2 and prefix2 .. "/" .. output2 or output2

    if prefix1 ~= prefix2 then
      break
    end

    i = i - 1
    j = j - 1
  end

  -- remove trailing slash
  return string.gsub(output1, "/$", ""), string.gsub(output2, "/$", "")
end

---@param file_paths string[]
---@return string[]
function M.get_file_names(file_paths)
  local file_names = {}
  local seen = {}

  for _, path in ipairs(file_paths) do
    local file_path = split_path(path)

    local file_name = string.match(path, ".+/(.+)$")
    if file_name == nil then
      file_name = path
    end

    if seen[file_name] ~= nil then
      local current_file_name, seen_file_name = get_unique_names(file_path, seen[file_name])

      -- add file name to the output list
      table.insert(file_names, current_file_name)

      -- then update the previously added file name
      local seen_file_name_index = list.unsafe_find_index(file_names, file_name)
      file_names[seen_file_name_index] = seen_file_name

      -- currently skip updating the "seen" table
    else
      seen[file_name] = file_path
      table.insert(file_names, file_name)
    end
  end

  return file_names
end

return M
