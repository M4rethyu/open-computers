local component = require("component")
local sides = require("sides")


local assembler = component.assembler
if assembler == nil then
    error("assemble_robot and assembler next to the transposer")
end

local transposer = component.transposer
if transposer == nil then
    error("assemble_robot requires a transposer between the assembler and inventories containing the required components")
end


local source_sides = {sides.south, sides.east, sides.up}
local assembler_side = sides.down
local target_side = sides.west


local assemble_robot = {}


local components = {
    {name = "opencomputers:case3", label = "Computer Case (Tier 3)"},
    {name = "minecraft:air", label = "Air"},
    {name = "minecraft:air", label = "Air"},
    {name = "minecraft:air", label = "Air"},
    {name = "opencomputers:upgrade", label = "Solar Generator Upgrade"},
    {name = "opencomputers:upgrade", label = "Navigation Upgrade"},
    {name = "opencomputers:upgrade", label = "Generator Upgrade"},
    {name = "opencomputers:upgrade", label = "Hover Upgrade (Tier 2)"},
    {name = "opencomputers:upgrade", label = "Angel Upgrade"},
    {name = "opencomputers:upgrade", label = "Inventory Controller Upgrade"},
    {name = "opencomputers:upgrade", label = "Inventory Upgrade"},
    {name = "opencomputers:keyboard", label = "Keyboard"},
    {name = "opencomputers:screen1", label = "Screen (Tier 1)"},
    {name = "minecraft:air", label = "Air"},--{name = "opencomputers:card", label = "Graphics Card (Tier 3)"},
    {name = "minecraft:air", label = "Air"},--{name = "opencomputers:card", label = "Wireless Network Card (Tier 2)"},
    {name = "opencomputers:card", label = "Internet Card"},
    {name = "opencomputers:component", label = "Accelerated Processing Unit (APU) (Tier 3)"},
    {name = "opencomputers:component", label = "Memory (Tier 3.5)"},
    {name = "opencomputers:component", label = "Memory (Tier 3.5)"},
    {name = "opencomputers:storage", label = "EEPROM (Lua BIOS)"},
    {name = "opencomputers:storage", label = "Hard Disk Drive (Tier 3) (4MB)"},
    {name = "minecraft:air", label = "Air"}
}

function assemble_robot.insert_components()
    local success = true
    for i_component, c in ipairs(components) do
        print(string.format("inserting component %d : %s / %s", i_component, c.name, c.label))
        local stack = transposer.getStackInSlot(assembler_side, i_component)
        if c.name == "minecraft:air" then -- ignore if nothing needs to be in that slot
            print("skipping air component...")
        elseif stack and stack.name == c.name and stack.label == c.label then -- ignore if that slot already has the correct item
            print("component is already in assembled, skipping...")
        else
            local source_side
            local source_slot
            for _, side in ipairs(source_sides) do
                for i_slot, stack in ipairs(transposer.getAllStacks(side)) do
                    if stack and stack.name == c.name and stack.label == c.label then
                        source_side = side
                        source_slot = i_slot
                    end
                end
            end

            if source_side and source_slot then
                transposer.transferItem(source_side, assembler_side, 1, source_slot, i_component)
            else
                print(string.format("WARN: component %s / %s not found", c.name, c.label))
                success = false
            end
        end
    end
    return success
end

function assemble_robot.build_robot()
    if assemble_robot.insert_components() then
        if assembler.status() then
            print("starting assembler...")
            assembler.start()
            while(assembler.status() == "busy") do end -- wait for assembler to finish

            local target_slot
            for i = 1, transposer.getInventorySize(target_side) do
                local stack = transposer.getStackInSlot(target_side, i)
                if not stack then -- find first empty slot
                    target_slot = i
                end
            end

            if target_slot then
                transposer.transferItem(assembler_side, target_side, 1, 1, target_slot)
                return true
            else
                print("no free slot in target inventory")
                return false
            end
        end
    else
        return false
    end
end

while assemble_robot.build_robot() do end

return assemble_robot