local logger = require("utils.logger")
local list = require("utils.list")
local str = require("utils.string")
local file = require("utils.file")

local M = {}

local PINNED_BUFFER_LOCATION = vim.fn.stdpath("data") .. "/vuffers"

---@return string
local function _get_filename()
  local cwd = vim.loop.cwd()
  local filename = str.replace(cwd, "/", "_")
  return PINNED_BUFFER_LOCATION .. "/" .. filename .. ".json"
end

---@param buffer Buffer
function M.persist_pinned_buffer(buffer)
  local ok, err = pcall(function()
    local filename = _get_filename()

    ---@type {path: string}[]
    local pinned_buffers = file.read_json_file(filename)
    local is_pinned = list.find_index(pinned_buffers, function(item)
      return item.path == buffer.path
    end)

    if is_pinned then
      return
    end

    table.insert(pinned_buffers, { path = buffer.path })
    file.write_json_file(filename, pinned_buffers)
  end)

  if not ok then
    logger.error("persist_pinned_buffer: ", err)
  end
end

---@param buffer Buffer
function M.remove_persisted_pinned_buffer(buffer)
  local ok, err = pcall(function()
    local filename = _get_filename()

    ---@type {path: string}[]
    local pinned_buffers = file.read_json_file(filename)
    local is_pinned = list.find_index(pinned_buffers, function(item)
      return item.path == buffer.path
    end)

    if not is_pinned then
      return
    end

    local updated = list.filter(pinned_buffers, function(item)
      return item.path ~= buffer.path
    end)

    file.write_json_file(filename, updated or {})
  end)

  if not ok then
    logger.error("persist_pinned_buffer: ", err)
  end
end

return M
