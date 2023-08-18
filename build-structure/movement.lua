local robot_api = require("robot")
local gps
pcall(function() gps = require("gps") end)


local movement = {}

-- constants
movement.DIRECTION = {
    NORTH = 0, --  -z
    EAST = 1,  --  +x
    SOUTH = 2, --  +z
    WEST = 3,  --  -x
    UP = 4,    --  +y
    DOWN = 5   --  -y
}


-- track location and orientation
local pose = {
    x = 0,
    y = 0,
    z = 0,
    dir = movement.DIRECTION.NORTH
}

-- getter and setter for pose
function movement.getPose()
    local pose_copy = {
        x = pose.x,
        y = pose.y,
        z = pose.z,
        dir = pose.dir
    } -- make copy of pose so internal pose doesn't accidentally get changed
    return pose_copy
end

function movement.setPose(x, y, z, dir) -- all parameters optional, use nil to omit left params
    pose.x = x or pose.x
    pose.y = y or pose.y
    pose.z = z or pose.z
    pose.dir = dir or pose.dir
end

if gps then
    local gps_pose = gps.position()
    movement.setPose(gps_pose.x, gps_pose.y, gps_pose.z, gps_pose.dir)
end

-- wrappers for built in turning functions of robots to track orientation
function movement.turnLeft()
    robot_api.turnLeft()
    if pose.dir == 0 then
        pose.dir = 3
    else -- pose.dir in {1, 2, 3}
        pose.dir = pose.dir - 1
    end
end

function movement.turnRight()
    robot_api.turnRight()
    if pose.dir == 3 then
        pose.dir = 0
    else -- pose.dir in {0, 1, 2}
        pose.dir = pose.dir + 1
    end
end

function movement.turnAround()
    robot_api.turnAround()
    if pose.dir == 0 or pose.dir == 1 then
        pose.dir = pose.dir + 2
    else -- pose.dir in {2, 3}
        pose.dir = pose.dir - 2
    end
end

-- higher order turning function to go directly to target_facing
function movement.turnTo(target_facing)
  local diff_facing = (target_facing - pose.dir)%4
  if diff_facing == 1 then
    movement.turnRight()
  elseif diff_facing == 2 then
    movement.turnAround()
  elseif diff_facing == 3 then
    movement.turnLeft()
  end
end


-- wrappers for built in movement functions of robots to track location
function movement.forward()
    local success, msg = robot_api.forward()
    if success then -- movement succeeded
        if     pose.dir == movement.DIRECTION.NORTH then
            pose.z = pose.z - 1
        elseif pose.dir == movement.DIRECTION.EAST then
            pose.x = pose.x + 1
        elseif pose.dir == movement.DIRECTION.SOUTH then
            pose.z = pose.z + 1
        elseif pose.dir == movement.DIRECTION.WEST then
            pose.x = pose.x - 1
        end
        return success
    else -- movement failed
        return success, msg
    end
end

function movement.back()
    local success, msg = robot_api.back()
    if success then -- movement succeeded
        if     pose.dir == movement.DIRECTION.NORTH then
            pose.z = pose.z + 1
        elseif pose.dir == movement.DIRECTION.EAST then
            pose.x = pose.x - 1
        elseif pose.dir == movement.DIRECTION.SOUTH then
            pose.z = pose.z - 1
        elseif pose.dir == movement.DIRECTION.WEST then
            pose.x = pose.x + 1
        end
        return success
    else -- movement failed
        return success, msg
    end
end

function movement.up()
    local success, msg = robot_api.up()
    if success then -- movement succeeded
        pose.y = pose.y + 1
        return success
    else -- movement failed
        return success, msg
    end
end

function movement.down()
    local success, msg = robot_api.down()
    if success then -- movement succeeded
        pose.y = pose.y - 1
        return success
    else -- movement failed
        return success, msg
    end
end

-- higher order movement function to move in target DIRECTION
function movement.move(direction) -- direction must be [0-5] (see movement.DIRECTION)
    if movement.DIRECTION.NORTH <= direction and direction <= movement.DIRECTION.WEST then -- horizontal movement
        movement.turnTo(direction)
        return movement.forward()
    elseif direction == movement.DIRECTION.UP then -- vertical movement (up)
        return movement.up()
    elseif direction == movement.DIRECTION.DOWN then -- vertical movement (down)
        return movement.down()
    end
end

-- higher order movement function to move directly to target coordinates
function movement.moveTo(target_x, target_y, target_z)
    while (pose.x ~= target_x) or (pose.y ~= target_y) or (pose.z ~= target_z) do
        -- only one move per iteration; check if move necessary, then do it; skip all other elseif, because one was true
        if     pose.y < target_y and movement.move(movement.DIRECTION.UP)    then -- try moving up first (if necessary)
        elseif pose.x < target_x and movement.move(movement.DIRECTION.EAST)  then -- then try moving horizontally (if necessary)
        elseif pose.x > target_x and movement.move(movement.DIRECTION.WEST)  then -- ...
        elseif pose.z < target_z and movement.move(movement.DIRECTION.SOUTH) then -- ...
        elseif pose.z > target_z and movement.move(movement.DIRECTION.NORTH) then -- ...
        elseif pose.y > target_y and movement.move(movement.DIRECTION.DOWN)  then -- then try moving down (if necessary)
        else return false -- target not reached but all possible moves blocked
        end
    end
    return true -- target reached (because condition of while loop is false
end

return movement
