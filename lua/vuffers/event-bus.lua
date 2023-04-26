local logger = require("utils.logger")

local M = {}

---@type table<string, {handler: function, label?: string}>
local _subscribers = {}

---@param event Event
---@param handler function
---@param opts? {label: string}
function M.subscribe(event, handler, opts)
  if _subscribers[event] then
    _subscribers[event] = {}
  end

  table.insert(_subscribers[event], handler)

  local label = (opts and opts.label and opts.label or "")
  logger.debug("subscribed to event: " .. event .. (label and " (" .. label .. ")" or ""))
end

---@param event Event
function M.publish(event)
  print("published!")
end

return M
