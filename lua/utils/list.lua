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

return M
