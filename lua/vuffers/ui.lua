local constants = require("vuffers.constants")

local M = {}
local split

function M.init(opts)
  local Split = require("nui.split")

  split = Split({
    relative = "editor",
    position = "left",
    size = "20%",
    win_options = {
      relativenumber = false,
      number = false,
      list = false,
      winfixwidth = true,
      winfixheight = true,
      foldenable = false,
      spell = false,
      signcolumn = "yes",
      foldmethod = "manual",
      foldcolumn = "0",
      cursorcolumn = false,
      colorcolumn = "0",
      winhighlight = "Normal:VerticalBuffers",
    },

    buf_options = {
      swapfile = false,
      buftype = "nofile",
      -- modifiable = false,
      filetype = constants.FILE_TYPE,
      bufhidden = "hide",
    },
  })

  split:mount()

  split:hide()
end

local function get_split()
  if split then
    return split
  end
  M.init()
  return split
end

local is_open = false

function M.open()
  local s = get_split()

  s:show()
  is_open = true
end

function M.close()
  local s = get_split()

  s:hide()
  is_open = false
end

function M.is_hidden()
  return not is_open
end

---@return number
function M.get_split_buf_num()
  local s = get_split()

  return s.bufnr
end

return M
