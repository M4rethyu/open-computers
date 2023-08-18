local robot_api = require("robot")


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
movement.pose = {
    x = 91,
    y = 68,
    z = 269,
    dir = movement.DIRECTION.EAST
}

-- getter and setter for pose
function movement.getPose()
    local pose = {
        x = movement.pose.x,
        y = movement.pose.y,
        z = movement.pose.z,
        dir = movement.pose.dir
    } -- make copy of pose so internal pose doesn't accidentally get changed
    return pose
end

function movement.setPose(x, y, z, dir) -- all parameters optional, use nil to omit left params
    movement.pose.x = x or movement.pose.x
    movement.pose.y = y or movement.pose.y
    movement.pose.z = z or movement.pose.z
    movement.pose.dir = dir or movement.pose.dir
end


-- wrappers for built in turning functions of robots to track orientation
function movement.turnLeft()
    robot_api.turnLeft()
    if movement.pose.dir == 0 then
        movement.pose.dir = 3
    else -- movement.pose.dir in {1, 2, 3}
        movement.pose.dir = movement.pose.dir - 1
    end
end

function movement.turnRight()
    robot_api.turnRight()
    if movement.pose.dir == 3 then
        movement.pose.dir = 0
    else -- movement.pose.dir in {0, 1, 2}
        movement.pose.dir = movement.pose.dir + 1
    end
end

function movement.turnAround()
    robot_api.turnAround()
    if movement.pose.dir == 0 or movement.pose.dir == 1 then
        movement.pose.dir = movement.pose.dir + 2
    else -- movement.pose.dir in {2, 3}
        movement.pose.dir = movement.pose.dir - 2
    end
end

-- higher order turning function to go directly to target_facing
function movement.turnTo(target_facing)
  local diff_facing = (target_facing - movement.pose.dir)%4
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
        if     movement.pose.dir == movement.DIRECTION.NORTH then
            movement.pose.z = movement.pose.z - 1
        elseif movement.pose.dir == movement.DIRECTION.EAST then
            movement.pose.x = movement.pose.x + 1
        elseif movement.pose.dir == movement.DIRECTION.SOUTH then
            movement.pose.z = movement.pose.z + 1
        elseif movement.pose.dir == movement.DIRECTION.WEST then
            movement.pose.x = movement.pose.x - 1
        end
        return success
    else -- movement failed
        return success, msg
    end
end

function movement.back()
    local success, msg = robot_api.back()
    if success then -- movement succeeded
        if     movement.pose.dir == movement.DIRECTION.NORTH then
            movement.pose.z = movement.pose.z + 1
        elseif movement.pose.dir == movement.DIRECTION.EAST then
            movement.pose.x = movement.pose.x - 1
        elseif movement.pose.dir == movement.DIRECTION.SOUTH then
            movement.pose.z = movement.pose.z - 1
        elseif movement.pose.dir == movement.DIRECTION.WEST then
            movement.pose.x = movement.pose.x + 1
        end
        return success
    else -- movement failed
        return success, msg
    end
end

function movement.up()
    local success, msg = robot_api.up()
    if success then -- movement succeeded
        movement.pose.y = movement.pose.y + 1
        return success
    else -- movement failed
        return success, msg
    end
end

function movement.down()
    local success, msg = robot_api.down()
    if success then -- movement succeeded
        movement.pose.y = movement.pose.y - 1
        return success
    else -- movement failed
        return success, msg
    end
end

-- higher order movement function to move in target DIRECTION
function movement.move(direction) -- direction must be [0-5] (see movement.DIRECTION)
    if movement.DIRECTION.NORTH <= direction and direction <= movement.DIRECTION.WEST then -- horizontal movement
        movement.turnTo(direction)
        movement.forward()
    elseif direction == movement.DIRECTION.UP then -- vertical movement (up)
        movement.up()
    elseif direction == movement.DIRECTION.DOWN then -- vertical movement (down)
        movement.down()
    end
end

-- higher order movement function to move directly to target coordinates
function movement.moveTo(target_x, target_y, target_z)
    while(movement.pose.x ~= target_x and movement.pose.y ~= target_y and movement.pose.z ~= target_z) do
        -- only one move per iteration; check if move necessary, then do it; skip all other elseif, because one was true
        if     movement.pose.y < target_y and movement.move(movement.DIRECTION.UP)    then -- try moving up first (if necessary)
        elseif movement.pose.x < target_x and movement.move(movement.DIRECTION.EAST)  then -- then try moving horizontally (if necessary)
        elseif movement.pose.x > target_x and movement.move(movement.DIRECTION.WEST)  then -- ...
        elseif movement.pose.z < target_z and movement.move(movement.DIRECTION.SOUTH) then -- ...
        elseif movement.pose.z > target_z and movement.move(movement.DIRECTION.NORTH) then -- ...
        elseif movement.pose.y > target_y and movement.move(movement.DIRECTION.DOWN)  then -- then try moving down (if necessary)
        else return false -- target not reached but all possible moves blocked
        end
    end
    return true -- target reached (because condition of while loop is false
end

return movement
