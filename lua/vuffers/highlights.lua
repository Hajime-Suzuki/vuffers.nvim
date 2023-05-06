local hl = require("vuffers.constants").HIGHLIGHTS

local M = {}

local highlights = {
  [hl.WINDOW_BG] = "TabLineFill",
  [hl.ACTIVE] = "Identifier",
  [hl.MODIFIED_ICON] = "Identifier",
  [hl.PINNED_ICON] = "Identifier",
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
