local shell = require("shell")
local component = require("component")
local inventory = require("inventory")
local movement = require("movement")
local robot_api = require("robot")


local zero_coord = {x = -1280 - 64, y = 0, z = 768 - 64} -- target world coordinates which are equivalent to the source world's 0,0,0


local chunk_x, chunk_z, offset = ...

chunk_x = tonumber(chunk_x)
chunk_z = tonumber(chunk_z)

assert(chunk_x and chunk_z, "error: invalid chunk coordinates")

-- offset given by "--offset n"
if offset then
    offset = tonumber(offset)
    assert(offset, "error: invalid offset")
else
    offset = 0
end


-- download relevant files from github
--shell.execute('wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/build-structure/builder.lua" "/home/build-structure/builder.lua"')
--shell.execute('wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/lib/gps.lua" "/home/lib/gps.lua"')
--shell.execute('wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/lib/inventory.lua" "/home/lib/inventory.lua"')
--shell.execute('wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/lib/movement.lua" "/home/lib/movement.lua"')
--shell.execute(string.format(
--              'wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/chunks/chunk_%d_%d.txt" "/home/build-structure/input.txt"', chunk_x, chunk_z))
shell.execute('edit build-structure/input.txt')


if offset == 0 then
    -- equip pickaxe
    print("equipping pickaxe...")
    while not inventory.selectItem("projecte:item.pe_rm_pick") do -- select slot with pick
        inventory.restock("projecte:item.pe_rm_pick")
    end
    inventory.equip()
    robot_api.swingUp()
    print("done")

    -- put fuel into generator
    print("consuming fuel blocks...")
    while not inventory.selectItem("projecte:fuel_block", "Aeternalis Fuel Block") do -- select slot with block
        inventory.restock("projecte:fuel_block", "Aeternalis Fuel Block")
    end
    component.generator.insert()
    print("done")
end


local x = zero_coord.x + 16*chunk_x
local y = zero_coord.y
local z = zero_coord.z + 16*chunk_z
local builder = require("build-structure/builder")
print(string.format("builder will now build chunk (%d, %d) with anchorpoint (%d, %d, %d) and y-offset = %d", chunk_x, chunk_z, x, y, z, offset))

-- go up until reaching skybox
while movement.up() do end

builder.build(x, y, z, offset)

--return home
local pose = movement.getPose()
movement.moveTo(pose.x, 255, pose.z)
movement.moveTo(zero_coord.x, 255, zero_coord.z)
