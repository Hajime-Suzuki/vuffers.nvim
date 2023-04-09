local M = {}

function M.setup(opts) end

function M.open()
  local Split = require("nui.split")

  local split = Split({
    relative = "editor",
    position = "left",
    size = "20%",
  })

  split:mount()
end

return M
