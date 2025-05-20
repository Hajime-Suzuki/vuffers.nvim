local list = require("utils.list")
local logger = require("utils.logger")
local config = require("vuffers.config")
local constants = require("vuffers.constants")
local str = require("utils.string")

local M = {}

---@param path_fragments string[]
---@param level integer
function M._get_name_by_level(path_fragments, level)
  if #path_fragments <= level then
    return table.concat(path_fragments, "/")
  end

  local filenames = list.slice(path_fragments, #path_fragments - level + 1, #path_fragments)
  return table.concat(filenames, "/")
end

--- @param buffers { buf: integer, level: string, path_fragments: string[]}[]
local function _get_unique_folder_depth(buffers, output)
  local grouped_by_filename = list.group_by(buffers, function(item)
    return item.path_fragments[#item.path_fragments - item.level + 1]
  end)

  for _, items in pairs(grouped_by_filename) do
    local next_items = {}

    local is_unique = #items == 1 -- if the group has only one item then it is unique

    if is_unique then
      output[items[1].buf] = items[1]
      goto continue
    end

    for _, item in ipairs(items) do
      local parent = item.path_fragments[#item.path_fragments - item.level]

      if parent == nil then -- when there is no parent, use the item as it is
        output[item.buf] = item
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
---@param file_name string
---@return string filename, string extension
local function _split_filename_and_extension(file_name)
  local extension = string.match(file_name, "%.(%w+)$")

  local filename_without_extension = extension and string.gsub(file_name, "." .. extension .. "$", "")
  if not filename_without_extension or filename_without_extension == "" then
    filename_without_extension = file_name
  end

  return filename_without_extension, extension
end

--- @param item { buf: integer, path: string, level: integer, path_fragments: string[], additional_folder_depth?: integer, custom_name?: string }
--- @param unique_name string
local function _get_display_name(item, unique_name)
  if item.custom_name then
    return item.custom_name
  end

  local additional_depth = item.additional_folder_depth
  if additional_depth and additional_depth > 0 then
    return M._get_name_by_level(item.path_fragments, item.level + additional_depth)
  end

  return unique_name
end

--- @param item { buf: integer, path: string, level: integer, path_fragments: string[], additional_folder_depth?: integer, custom_name?: string }
--- @return Buffer
local function _format_buffer(item)
  local unique_name = M._get_name_by_level(item.path_fragments, item.level)
  local unique_name_without_extension, extension = _split_filename_and_extension(unique_name)

  local display_name = _get_display_name(item, unique_name)
  local name = config.get_view_config().show_file_extension and display_name
    or _split_filename_and_extension(display_name)
  local filename_without_extension = _split_filename_and_extension(item.path_fragments[#item.path_fragments])

  ---@type Buffer
  local b = {
    buf = item.buf,
    name = name,
    path = item.path,
    ext = extension or "",
    _unique_name = unique_name_without_extension,
    _filename = filename_without_extension,
    _additional_folder_depth = item.additional_folder_depth,
    _default_folder_depth = item.level,
    _max_folder_depth = #item.path_fragments,
    _custom_name = item.custom_name,
  }

  return b
end

--- @param buffers { buf:integer,  path: string, _additional_folder_depth?: integer, _custom_name?: string }[]
--- @return Buffer[] buffers
function M.get_formatted_buffers(buffers)
  local cwd = vim.loop.cwd()
  local output = {}

  -- preparing the input. adding extra data
  local input = list.map(buffers, function(buffer)
    local path_from_cwd = str.replace(buffer.path, (cwd or "") .. "/", "")
    local path_fragments = str.split(path_from_cwd, "/")
    return {
      buf = buffer.buf,
      path = buffer.path,
      level = 1,
      path_fragments = path_fragments,
      additional_folder_depth = buffer._additional_folder_depth,
      custom_name = buffer._custom_name,
    }
  end)

  --- getting the unique folder depths, which is used to calculate the unique names
  _get_unique_folder_depth(input, output)

  --- the output should be sorted in the original order
  return list.map(input, function(item)
    local target = output[item.buf]
    return _format_buffer(target)
  end)
end

--- @param buffers Buffer[]
--- @param fx (fun(buffer: Buffer): string | number)[]
--- @param directions SortDirection[]
local function order_by(buffers, fx, directions)
  if not next(buffers) or not next(fx) then
    return buffers
  end

  table.sort(buffers, function(a, b)
    for i, f in ipairs(fx) do
      local direction = directions[i] or constants.SORT_DIRECTION.ASC

      local a_value = f(a)
      local b_value = f(b)

      if a_value == b_value then
        goto continue
      end

      if direction == constants.SORT_DIRECTION.ASC then
        return a_value < b_value
      else
        return a_value > b_value
      end

      ::continue::
    end

    return false
  end)

  return buffers
end

--- @param buffers Buffer[]
--- @param sort SortOrder
function M.sort_buffers(buffers, sort)
  -- TODO: remove dependency
  local pinned = require("vuffers.buffers.pinned-buffers")

  if sort.type == constants.SORT_TYPE.__CUSTOM then
    local pinned_bufs = list.filter(buffers, function(buf)
      return pinned.is_pinned(buf.path)
    end)

    local unpinned_bufs = list.filter(buffers, function(buf)
      return not pinned.is_pinned(buf.path)
    end)

    return list.merge_unique(pinned_bufs or {}, unpinned_bufs or {}, {
      id = function(buf)
        return buf and buf.path
      end,
    })
  end

  return order_by(buffers, {
    function(buf)
      return pinned.is_pinned(buf.path) and 1 or 0
    end,
    function(buf)
      local type = buf.buf
      type = sort.type == constants.SORT_TYPE.FILENAME and buf._filename or type
      type = sort.type == constants.SORT_TYPE.UNIQUE_NAME and buf._unique_name or type
      return type
    end,
  }, { constants.SORT_DIRECTION.DESC, sort.direction })
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
