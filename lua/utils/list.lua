local M = {}

function M.unsafe_find_index(arr, target_item)
  for i = 1, #arr do
    if arr[i] == target_item then
      return i
    end
  end

  error("item not found in the list")
end

--- @generic TItem
--- @param arr TItem[]
--- @param callback fun(item: TItem, index: number): nil
--- @return nil
function M.for_each(arr, callback)
  for i, v in ipairs(arr) do
    callback(v, i)
  end
end

--- @generic TItem
--- @param arr1 TItem[]
--- @param arr2 TItem[]
--- @return TItem[]
function M.merge(arr1, arr2)
  local merged = {}
  for _, v in ipairs(arr1) do
    table.insert(merged, v)
  end
  for _, v in ipairs(arr2) do
    table.insert(merged, v)
  end
  return merged
end

--- @generic TItem
--- @param arr TItem[]
--- @param predicate fun(item: TItem, index: number): boolean
--- @return TItem[] | nil
--- returns non empty list
function M.filter(arr, predicate)
  local filtered = {}
  for i, v in ipairs(arr) do
    if predicate(v, i) then
      table.insert(filtered, v)
    end
  end
  return #filtered and filtered or nil
end

--- @generic TItem: any
--- @param arr TItem[]
--- @param predicate fun(item: any, index: number): boolean
--- @return TItem | nil
function M.find(arr, predicate)
  for i, v in pairs(arr) do
    if predicate(v, i) then
      return v
    end
  end
  return nil
end

--- @generic TItem
--- @param arr TItem[]
--- @param predicate fun(item: TItem, index: number): boolean
--- @return integer | nil
function M.find_index(arr, predicate)
  for i, v in pairs(arr) do
    if predicate(v, i) then
      return i
    end
  end
  return nil
end

function M.slice(arr, start_index, end_index)
  local sliced_arr = {}
  for i = start_index, end_index do
    table.insert(sliced_arr, arr[i])
  end
  return sliced_arr
end

--- @generic TItem
--- @generic TGroupId
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

--- @generic A
--- @generic B
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
