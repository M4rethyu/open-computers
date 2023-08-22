local shell = require("shell")
local component = require("component")
local inventory = require("inventory")


local zero_coord = {x = 127, y = 0, z = 303} -- target world coordinates which are equivalent to the source world's 0,0,0

-- parse arguments and options given to program
local args, ops = shell.parse(...)

local chunk_x = tonumber(args[1])
local chunk_z = tonumber(args[2])
assert(chunk_x and chunk_z, "error: invalid chunk coordinates")

-- offset given by "--offset n"
local offset
if ops["offset"] then
    offset = tonumber(ops["offset"])
    assert(offset, "error: invalid offset")
else
    offset = 0
end


-- download relevant files from github
shell.execute('wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/build-structure/builder.lua" "/home/build-structure/builder.lua"')
shell.execute('wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/lib/gps.lua" "/home/lib/gps.lua"')
shell.execute('wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/lib/inventory.lua" "/home/lib/inventory.lua"')
shell.execute('wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/lib/movement.lua" "/home/lib/movement.lua"')
shell.execute(string.format(
              'wget -f "https://raw.githubusercontent.com/M4rethyu/open-computers/master/chunks/chunk_%d_%d.txt" "/home/build-structure/input.txt"', chunk_x, chunk_z))


-- put fuel into generator
print("consuming fuel blocks...")
while not inventory.selectItem("projecte:fuel_block", "Aeternalis Fuel Block") do -- select slot with block
    inventory.restock("projecte:fuel_block", "Aeternalis Fuel Block")
    component.generator.insert()
end
print("done")

local x = zero_coord.x + 16*chunk_x
local y = zero_coord.y
local z = zero_coord.z + 16*chunk_z
local builder = require("build-structure/builder")
print(string.format("builder would now start building chunk (%d, %d) with anchorpoint (%d, %d, %d) and y-offset = %d", chunk_x, chunk_z, x, y, z, offset))
--builder.build(x, y, z, offset)
