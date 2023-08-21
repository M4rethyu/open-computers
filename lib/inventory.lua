local robot_api = require("robot")
local component = require("component")
local sides = require("sides")


local inventory_controller = component.inventory_controller
if inventory_controller == nil then
    error("inventory requires inventory controller upgrade")
end


local inventory = {}


function inventory.selectItem(name)
    for i = 1, robot_api.inventorySize() do
        local stack = inventory_controller.getStackInInternalSlot(i)
        if stack and stack.name == name then
            robot_api.select(i)
            return true
        end
    end
    return false -- item not in inventory
end

function inventory.restock(name)
    local ec_slot
    if not inventory.selectItem("enderstorage:ender_storage") then
        print("warning: robot does not have an enderchest")
        while not inventory.selectItem("enderstorage:ender_storage") do
            -- wait until ender chest provided
        end
    else
        ec_slot = robot_api.select()
        robot_api.placeUp() -- place ender chest

        -- find first empty slot, or else the stack with the least items
        local lowest_slot_count = 1000
        local lowest_slot_index
        for i = 1, robot_api.inventorySize() do
            local stack = inventory_controller.getStackInInternalSlot(i)
            if i == ec_slot then -- don't fill ender chest slot
            elseif not stack then -- slot empty (nil)
                lowest_slot_count = 0
                lowest_slot_index = i
                break
            elseif stack.size < lowest_slot_count then
                lowest_slot_count = stack.size
                lowest_slot_index = i
            end
        end
        robot_api.select(lowest_slot_index)

        if lowest_slot_count ~= 0 then
            -- empty this slot
            robot_api.dropDown(lowest_slot_count)
        end

        -- find needed item in ender chest
        for i = 1, inventory_controller.getInventorySize(sides.top) do
            local stack = inventory_controller.getStackInSlot(sides.top, i)
            if stack and stack.name == name then
                inventory_controller.suckFromSlot(sides.top, i, stack.size)
                break
            end
        end

        robot_api.select(ec_slot)
        robot_api.swingUp() -- pick up ender chest
    end
end


return inventory
