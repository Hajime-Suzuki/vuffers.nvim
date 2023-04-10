local buffers = require("vuffers.buffers")

local M = {}
local split

local function init(opts)
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
      modifiable = false,
      filetype = "vuffer",
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
  init()
  return split
end

function M.open()
  local s = get_split()

  s:show()
end

function M.close()
  local s = get_split()

  s:hide()
end

return M
