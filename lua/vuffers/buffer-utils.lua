local list = require("utils.list")
local logger = require("utils.logger")
local config = require("vuffers.config")
local constants = require("vuffers.constants")
local str = require("utils.string")

local M = {}

function M.get_name_by_level(filename, level)
  local items = str.split(filename, "/")

  if #items <= level then
    return filename
  end

  local filenames = list.slice(items, #items - level + 1, #items)
  return table.concat(filenames, "/")
end

--- @param buffers {  buf: number, path: string, level: string, path_fragments: string[]}[]
local function _get_unique_folder_depth(buffers, output)
  local grouped_by_filename = list.group_by(buffers, function(item)
    return item.path_fragments[#item.path_fragments - item.level + 1]
  end)

  for _, items in pairs(grouped_by_filename) do
    local next_items = {}

    local is_unique = #items == 1 -- if the group has only one item then it is unique

    if is_unique then
      table.insert(output, items[1])
      goto continue
    end

    for _, item in ipairs(items) do
      local parent = item.path_fragments[#item.path_fragments - item.level]

      if parent == nil then -- when there is no parent, use the item as it is
        table.insert(output, item)
      else
        item.level = item.level + 1
        table.insert(next_items, item)
      end
    end

    if #next_items > 0 then
      _get_unique_folder_depth(next_items, output)
    end

    ::continue::
  end
end

--- @param buffers { buf:integer, name: string, path: string, additional_folder_depth?: integer }[]
--- @return Buffer[]
function M.get_formatted_buffers(buffers)
  local output = {}

  -- preparing the input. adding extra data
  local input = list.map(buffers, function(buffer, i)
    return {
      buf = buffer.buf,
      path = buffer.path,
      level = 1,
      path_fragments = str.split(buffer.path, "/"),
      additional_folder_depth = buffer.additional_folder_depth,
    }
  end)

  --- getting the unique folder depths, which is used to calculate the unique names
  _get_unique_folder_depth(input, output)

  return list.map(output, function(item)
    local name = M.get_name_by_level(item.path, item.level)
    local extension = string.match(name, "%.(%w+)$")

    local name_without_extension = extension and string.gsub(name, "." .. extension .. "$", "")
    if not name_without_extension or name_without_extension == "" then
      name_without_extension = name
    end

    ---@type Buffer
    local b = {
      buf = item.buf,
      name = name_without_extension,
      path = item.path,
      ext = extension or "",
      _unique_name = name_without_extension,
      _additional_folder_depth = item.additional_folder_depth,
      _default_folder_depth = item.level,
    }

    return b
  end)
end

--- @param buffers Buffer[]
--- @param sort SortOrder
function M.sort_buffers(buffers, sort)
  if sort.type == constants.SORT_TYPE.NONE then
    table.sort(buffers, function(a, b)
      return a.buf < b.buf
    end)
  elseif sort.type == constants.SORT_TYPE.FILENAME then
    table.sort(buffers, function(a, b)
      if sort.direction == constants.SORT_DIRECTION.ASC then
        return a._unique_name < b._unique_name
      else
        return a._unique_name > b._unique_name
      end
    end)
  else
    logger.warn("sort_buffers: unknown sort type", sort)
  end

  logger.info("sort_buffers: buffers are sorted", sort)
end

---@param buffer NativeBuffer | Buffer
---@return boolean
function M.is_valid_buf(buffer)
  if not vim.api.nvim_buf_is_valid(buffer.buf) then
    logger.warn("Buffer is not valid", buffer)
    return false
  end

  if vim.fn.buflisted(buffer.buf) == 0 then
    return false
  end

  local filename = buffer.file or buffer.name
  if filename == "" or filename == "/" or filename == " " then
    return false
  end

  local file_names_to_ignore = config.get_exclude().filenames

  for _, pattern in pairs(file_names_to_ignore) do
    if filename:match(pattern) then
      return false
    end
  end

  local filetype = vim.api.nvim_buf_get_option(buffer.buf, "filetype")
  if filetype and filetype ~= "" then
    if string.match(filetype, constants.VUFFERS_FILE_TYPE) then
      return false
    end

    local file_types_to_ignore = config.get_exclude().filetypes

    for _, ft in pairs(file_types_to_ignore) do
      if filetype == ft then
        return false
      end
    end
  end

  return true
end

return M
