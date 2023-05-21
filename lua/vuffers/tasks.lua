local logger = require("utils.logger")
local list = require("utils.list")
local str = require("utils.string")

local M = {}

local PINNED_BUFFER_LOCATION = vim.fn.stdpath("data") .. "/vuffers"

---@return string
local function _get_filename()
  local cwd = vim.loop.cwd()
  local filename = str.replace(cwd, "/", "_")
  return PINNED_BUFFER_LOCATION .. "/" .. filename .. ".json"
end

local function _ensure_file(filename)
  if vim.fn.filereadable(filename) == 0 then
    local folder = string.match(filename, "(.+)/.+$")
    vim.fn.mkdir(folder, "p")
    vim.fn.writefile({ "{}" }, filename)
  end
end

---@param filename string
---@return unknown
local function _read_json_file(filename)
  _ensure_file(filename)
  local data = vim.fn.readfile(filename)
  return vim.fn.json_decode(table.concat(data, ""))
end

---@param filename string
---@param data table
local function _write_json_file(filename, data)
  _ensure_file(filename)
  vim.fn.writefile({ vim.fn.json_encode(data) }, filename)
end

---@param buffer Buffer
function M.persist_pinned_buffer(buffer)
  local ok, err = pcall(function()
    local filename = _get_filename()

    ---@type {path: string}[]
    local pinned_buffers = _read_json_file(filename)
    local is_pinned = list.find_index(pinned_buffers, function(item)
      return item.path == buffer.path
    end)

    if is_pinned then
      return
    end

    table.insert(pinned_buffers, { path = buffer.path })
    _write_json_file(filename, pinned_buffers)
  end)

  if not ok then
    logger.error("persist_pinned_buffer: ", err)
  end
end
