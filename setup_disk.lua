---
--- run on a computer, set up disks to be used by builder robots
---

local shell = require("shell")
local component = require("component")
local sides = require("sides")

local transposer = component.transposer
if transposer == nil then
    error("setup_disk requires a transposer between this computer, an inventory containing disks, and a target inventory")
end


local setup_disk = {}


local source_side = sides.west -- inventory containing disks
local computer_side = sides.east -- computer
local target_side = sides.south -- inventory receiving disks

function setup_disk.writeDisk()
    local source_slot
    local computer_slot = 6
    local target_slot
    for i = 1,transposer.getInventorySize(source_side) do
        local stack = transposer.getStackInSlot(source_side, i)
        if stack.name == "opencomputers:storage" and stack.label == "Hard Disk Drive (Tier 3) (4MB)" then
            source_slot = i
            break
        end
    end
    for i = 1,transposer.getInventorySize(target_side) do
        local stack = transposer.getStackInSlot(target_side, i)
        if not stack then
            target_slot = i
            break
        end
    end

    if not source_slot then
        print("no T3 disk in source inventory")
        return false
    end
    if not target_slot then
        print("no space in target inventory")
        return false
    end

    transposer.transferItem(source_side, computer_side, 1, source_slot, computer_slot) -- move new disk from source to computer

    local fs_target
    for address, _ in component.list("filesystem") do
        local proxy = component.proxy(address)
        local label = proxy.getLabel()
        if label == "OpenOS" then
        elseif label == "tmpfs" then
        elseif label == nil then
            fs_target = proxy
        end
    end


    local code = string.format("cp -r -v /* /%s/", string.sub(fs_target, 1, 3))
    shell.execute(code)

    transposer.transferItem(computer_side, target_side, 1, computer_slot, target_slot) -- move written disk to target
    return true
end

function setup_disk.run()
    while setup_disk.writeDisk() do end
end



return setup_disk
