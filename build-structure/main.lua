

function lines_from(file)
  if not file_exists(file) then return {} end
  local lines = {}
  for line in io.lines(file) do
    lines[#lines + 1] = line
  end
  return lines
end


-- tests the functions above
local file = 'input.txt'
local lines = lines_from(file)

-- print all line numbers and their contents
for k,v in pairs(lines) do
  print('line[' .. k .. ']', v)
end