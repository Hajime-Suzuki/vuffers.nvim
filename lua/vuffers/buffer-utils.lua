local list = require("utils.list")
local logger = require("utils.logger")
local config = require("vuffers.config")
local constants = require("vuffers.constants")

local M = {}

--- @param buffers { buf:integer, name: string, path: string }[]
--- @return Buffer[]
function M.get_file_names(buffers)
  local output = {}

  -- preparing the input. adding extra data
  local input = list.map(buffers, function(buffer, i)
    return {
      current_filename = "",
      remaining = buffer.path,
      buf = buffer.buf,
      index = i,
      path = buffer.path,
    }
  end)

  --- @param ls {current_filename: string, remaining: string, buf: number, index: number, path: string}[]
  local function get_unique_names(ls)
    local grouped_by_filename = list.group_by(ls, function(item)
      return string.match(item.remaining, ".+/(.+)$") or item.remaining
    end)

    for grouped_name, items in pairs(grouped_by_filename) do
      local next_items = {}

      if #items == 1 then -- this is unique item of the group. item should be used without further processing
        local item = items[1]

        -- item.remaining can be empty if file name is like "data.json". if so, use it as it is
        -- cut the the remaining parent folders
        local filename = string.gsub(
          (string.match(item.remaining, ".+/(.+)$") or item.remaining) .. "/" .. item.current_filename,
          "/$",
          ""
        )

        local filename_with_index = {
          index = item.index,
          name = filename,
          buf = item.buf,
          path = item.path,
        }

        table.insert(output, filename_with_index)

        goto continue
      end

      for _, item in ipairs(items) do
        local parent = string.match(item.remaining, "(.+)/.+$")

        if parent == nil then -- when there is no parent, use the item as it is
          local filename = string.gsub(item.remaining .. "/" .. item.current_filename, "/$", "")
          table.insert(output, {
            index = item.index,
            name = filename,
            buf = item.buf,
            path = item.path,
          })
        else
          table.insert(next_items, {
            current_filename = grouped_name .. "/" .. item.current_filename,
            remaining = parent,
            index = item.index,
            buf = item.buf,
            path = item.path,
          })
        end
      end

      if #next_items > 0 then
        get_unique_names(next_items)
      end

      ::continue::
    end
  end

  get_unique_names(input)

  return list.map(output, function(item)
    local extension = string.match(item.name, "%.(%w+)$")

    local name_without_extension = extension and string.gsub(item.name, "." .. extension .. "$", "")
    if not name_without_extension or name_without_extension == "" then
      name_without_extension = item.name
    end

    return {
      buf = item.buf,
      name = name_without_extension,
      path = item.path,
      ext = extension,
    }
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
      local n1 = a.name:match(".+/(.+)$") or a.name
      local n2 = b.name:match(".+/(.+)$") or b.name
      if sort.direction == constants.SORT_DIRECTION.ASC then
        return n1 < n2
      else
        return n1 > n2
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
  local filetype = vim.bo[buffer.buf].filetype

  if filename == "" or filename == "/" or filename == " " then
    return false
  end

  local file_names_to_ignore = config.get_exclude().filenames

  for _, pattern in pairs(file_names_to_ignore) do
    if filename:match(pattern) then
      return false
    end
  end

  if filetype then
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
