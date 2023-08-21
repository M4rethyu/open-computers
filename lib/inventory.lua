local robot_api = require("robot")
local component = require("component")
local sides = require("sides")


local inventory_controller = component.inventory_controller
if inventory_controller == nil then
    error("inventory requires inventory controller upgrade")
end


local inventory = {}


-- some block's items have the same id but can be distinguished by their label. this table translates those ids to labels
inventory.special_blocks = {
    ["minecraft:andesite"] = {name = "minecraft:stone", label = "Andesite"},
    ["minecraft:granite"] = {name = "minecraft:stone", label = "Granite"},
    ["minecraft:grass_block"] = {name = "minecraft:grass", label = nil},

    ["minecraft:oak_log"] = {name = "minecraft:log", label = "Oak Wood"},
    ["minecraft:spruce_log"] = {name = "minecraft:log", label = "Spruce Wood"},
    ["minecraft:acacia_log"] = {name = "minecraft:log2", label = "Acacia Wood"},
    ["minecraft:dark_oak_log"] = {name = "minecraft:log2", label = "Dark Oak Wood"},
    ["minecraft:birch_log"] = {name = "minecraft:log", label = "Birch Wood"},

    ["minecraft:oak_leaves"] = {name = "minecraft:leaves", label = "Oak Leaves"},
    ["minecraft:spruce_leaves"] = {name = "minecraft:leaves", label = "Spruce Leaves"},
    ["minecraft:acacia_leaves"] = {name = "minecraft:leaves2", label = "Acacia Leaves"},
    ["minecraft:dark_oak_leaves"] = {name = "minecraft:leaves2", label = "Dark Oak Leaves"},
    ["minecraft:birch_leaves"] = {name = "minecraft:leaves", label = "Birch Leaves"},
}

function inventory.selectItem(name, label)
    assert(name or label, "at least one argument must be provided")
    for i = 1, robot_api.inventorySize() do
        local stack = inventory_controller.getStackInInternalSlot(i)
        if stack and (not name or stack.name == name) and (not label or stack.label == label) then
            robot_api.select(i)
            return true
        end
    end
    return false -- item not in inventory
end

function inventory.restock(name, label)
    assert(name or label, "at least one argument must be provided")
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
            if stack and (not name or stack.name == name) and (not label or stack.label == label) then
                inventory_controller.suckFromSlot(sides.top, i, stack.size)
                break
            end
        end

        robot_api.select(ec_slot)
        robot_api.swingUp() -- pick up ender chest
    end
end


return inventory
