local M = {}

function M.unsafe_find_index(arr, target_item)
  for i = 1, #arr do
    if arr[i] == target_item then
      return i
    end
  end

  error("item not found in the list")
end

function M.slice_array(arr, start_index, end_index)
  local sliced_arr = {}
  for i = start_index, end_index do
    table.insert(sliced_arr, arr[i])
  end
  return sliced_arr
end

--- @generic TItem: any
--- @generic TGroupId: any
--- @param arr TItem[]
--- @param f fun(item: TItem, index: number): TGroupId
--- @return table<TGroupId, TItem[]>
function M.group_by(arr, f)
  local grouped = {}

  for i, item in pairs(arr) do
    local key = f(item, i)
    if grouped[key] == nil then
      grouped[key] = {}
    end
    table.insert(grouped[key], item)
  end

  return grouped
end

--- @generic A: any
--- @generic B: any
--- @param arr A[]
--- @param f fun(item: A, index: number): B
--- @return B[]
function M.map(arr, f)
  local grouped = {}

  for i, a in pairs(arr) do
    local b = f(a, i)
    table.insert(grouped, b)
  end

  return grouped
end

return M
