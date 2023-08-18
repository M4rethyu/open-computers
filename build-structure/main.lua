-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist

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
--for k,v in pairs(lines) do
--  print('line[' .. k .. ']', v)
--end


direction = {
  north = 0,
  east = 1,
  south = 2,
  west = 3
}

x = 91
y = 68
z = 269
facing = direction.east



local robot_api = require("robot")
local component = require("component")
local robot_component = component.robot

function turn_to(target_facing)
  local diff_facing = (target_facing - facing)%4
  if diff_facing == 1 then
    robot_api.turnLeft()
    facing = (facing - 1)%4
  elseif diff_facing == 2 then
    robot_api.turnLeft()
    robot_api.turnLeft()
    facing = (facing - 2)%4
  elseif diff_facing == 3 then
    robot_api.turnRight()
    facing = (facing + 1)%4
  end
end

function move_to(target_x, target_y, target_z)
  while(y ~= target_y) do
    if y < target_y then
      robot_api.up()
      y = y + 1
    end
    if y > target_y then
      robot_api.down()
      y = y - 1
    end
  end
  turn_to(direction.east)
  while(x ~= target_x) do
    if x < target_x then
      robot_api.forward()
      x = x + 1
    end
    if x > target_x then
      robot_api.backward()
      x = x - 1
    end
  end
  turn_to(direction.north)
  while(z ~= target_z) do
    if z < target_z then
      robot_api.forward()
      z = z + 1
    end
    if z > target_z then
      robot_api.back()
      z = z - 1
    end
  end
end

move_to(95, 75, 265)
