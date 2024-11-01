local logger = require("utils.logger")
local actions = require("vuffers.ui-actions")
local config = require("vuffers.config")

local lup_actions = {
	open												= actions.open_buffer,
	delete											= actions.delete_buffer,
	pin													=	actions.pin_buffer,
	unpin												= actions.unpin_buffer,
	rename											= actions.rename_buffer,
	reset_custom_display_name		= actions.reset_custom_display_name,
	reset_custom_display_names	= actions.reset_custom_display_name,
	move_up											= function() actions.move_current_buffer_by_count({ direction = "prev" }) end,
	move_down										= function() actions.move_current_buffer_by_count({ direction = "next" }) end,
	move_to											= actions.move_buffer_to_index
}

local M = {}

---@param payload VuffersWindowOpenedPayload
function M.setup(payload)
  local bufnr = payload.buffer_number
  local keymaps = config.get_keymaps()
  if not keymaps.use_default then
    logger.debug("skipping setting key bindings")
    return
  end

  logger.debug("setting key bindings", keymaps)

  local opts = { noremap = true, silent = true, nowait = true, buffer = bufnr }
	vim.iter(keymaps.view)
		:each(function(rhs, lhsgroup)
			vim.iter({ lhsgroup or nil }):flatten()
				:each(function(lhs)
					vim.keymap.set("n", lhs, lup_actions[rhs], opts)
				end)
		end)
end

return M
