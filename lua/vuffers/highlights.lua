local hl = require("vuffers.constants").HIGHLIGHTS

local M = {}

local highlights = {
  [hl.ACTIVE] = "Identifier",
  [hl.MODIFIED] = "Identifier",
}

function M.setup()
  for hl_group, link in pairs(highlights) do
    vim.api.nvim_set_hl(0, hl_group, {
      link = link,
      default = true,
    })
  end
end

return M