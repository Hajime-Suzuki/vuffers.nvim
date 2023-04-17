local list = require("utils.list")

local M = {}

--- @param buffers Buffer[]
--- @return Buffer[]
function M.get_file_names(buffers)
  local output = {}

  -- preparing the input. adding extra data
  local input = list.map(buffers, function(buffer, i)
    return {
      current_filename = "",
      remaining = buffer.path,
      buf = buffer.buf,
      index = i,
      path = buffer.path,
    }
  end)

  --- @param ls {current_filename: string, remaining: string, buf: number, index: number, path: string}[]
  local function loop(ls)
    local grouped_by_filename = list.group_by(ls, function(item)
      return string.match(item.remaining, ".+/(.+)$") or item.remaining
    end)

    for grouped_name, items in pairs(grouped_by_filename) do
      local next_items = {}

      if #items == 1 then -- this is unique item of the group. item should be used without further processing
        local item = items[1]

        -- item.remaining can be empty if file name is like "data.json". if so, use it as it is
        -- cut the the remaining parent folders
        local filename = string.gsub(
          (string.match(item.remaining, ".+/(.+)$") or item.remaining) .. "/" .. item.current_filename,
          "/$",
          ""
        )

        local filename_with_index = {
          index = item.index,
          name = filename,
          buf = item.buf,
          path = item.path,
        }

        table.insert(output, filename_with_index)

        goto continue
      end

      for _, item in ipairs(items) do
        local parent = string.match(item.remaining, "(.+)/.+$")

        if parent == nil then -- when there is no parent, use the item as it is
          local filename = string.gsub(item.remaining .. "/" .. item.current_filename, "/$", "")
          table.insert(output, {
            index = item.index,
            name = filename,
            buf = item.buf,
            path = item.path,
          })
        else
          table.insert(next_items, {
            current_filename = grouped_name .. "/" .. item.current_filename,
            remaining = parent,
            index = item.index,
            buf = item.buf,
            path = item.path,
          })
        end
      end

      if #next_items > 0 then
        loop(next_items)
      end

      ::continue::
    end
  end

  loop(input)

  table.sort(output, function(a, b)
    return a.index < b.index
  end)

  return list.map(output, function(item)
    return {
      buf = item.buf,
      name = item.name,
      path = item.path,
    }
  end)
end

return M
