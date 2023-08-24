local component = require("component")
local sides = require("sides")


local transposer = component.transposer
if transposer == nil then
    error("setup_robot requires a transposer between the robot and inventories containing the required components")
end


local enderchest_side = sides.east -- inventory containing enderchests
local robot_side = sides.up -- robot


local setup_robot = {}


function setup_robot.setup()
    local robot = component.robot
    if robot == nil then
        error("setup_robot requires a robot connected to the computer")
        return false
    end

    local enderchest_slot
    for i_slot, stack in ipairs(transposer.getAllStacks(enderchest_side)) do
        if stack and stack.name == "enderstorage:ender_storage" then
            enderchest_slot = i_slot
        end
    end

    if enderchest_slot then
        local stack = transposer.getStackInSlot(robot_side, 1)
        if stack and stack.name == "enderstorage:ender_storage" then
            print("enderchest already in inventory, skipping...")
        else
            transposer.transferItem(enderchest_side, robot_side, 1, enderchest_slot, 1)
        end
    else
        print("could not find enderchest")
        return false
    end
end


setup_robot.setup()


return setup_robot