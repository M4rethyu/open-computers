local robot_api = require("robot")
local computer = require("computer")
local movement = require("movement")
local gps = require("gps")
local inventory = require("inventory")


local default_meta_data = {
    span_x = 16,
    span_y = 256,
    span_z = 16
}

local default_block_data = {
	[0] = "minecraft:air",
	[1] = "minecraft:stone",
	[2] = "minecraft:andesite",
	[3] = "minecraft:gravel",
	[4] = "minecraft:coal",
	[5] = "minecraft:coal",
	[6] = "minecraft:iron",
	[7] = "minecraft:dirt",
	[8] = "minecraft:granite",
	[9] = "minecraft:grass",
	[10] = "minecraft:emerald",
	[11] = "minecraft:lapis",
	[12] = "minecraft:gold",
	[13] = "minecraft:iron",
	[14] = "minecraft:oak",
	[15] = "minecraft:oak",
	[16] = "minecraft:spruce",
	[17] = "minecraft:spruce",
	[18] = "minecraft:acacia",
	[19] = "minecraft:acacia",
	[20] = "minecraft:cobblestone",
	[21] = "minecraft:diamond",
	[22] = "minecraft:birch",
	[23] = "minecraft:birch",
	[24] = "minecraft:dark",
	[25] = "minecraft:dark"
}


local builder = {}


local file_path
function builder.setInputFile(path)
    local f = io.open(path, "rb")
    if f then
        file_path = path
        f:close()
    else
        file_path = nil
        print("error: file does not exist")
    end
end

local function readFileHeader()
    local file_meta_data
    local file_block_data
    if not file_path then
        print("error: no input file specified")
        return nil
    end

    local f = io.open(file_path, "r")

    local line1 = f:read("*line")
    local x, y, z = string.match(line1, "^metadata:x=(%d+),y=(%d+),z=(%d+)")
    if x and y and z then
        print(x)
        print(y)
        print(z)
        file_meta_data = {
            span_x = math.floor(x),
            span_y = math.floor(y),
            span_z = math.floor(z)
        }
    end

    local line2 = f:read("*line")
    if string.match(line2, "^blockdata:") then
        file_block_data = {}
        local match = string.gmatch(line2, "(%d+)=([a-z:_]+)")
        for num_id, block_id in match do
            file_block_data[tonumber(num_id)] = block_id
            print(num_id..": "..block_id)
        end
    end

    if not (file_meta_data and file_block_data) then -- invalid header
        print("error: invalid header")
        return nil
    end
    return file_meta_data, file_block_data
end


function builder.build(x_anchor, y_anchor, z_anchor, y_offset) -- skip all layers until layer y_offset (0 indexed)
    assert(type(x_anchor) == "number", "error: x must be an integer")
    x_anchor = math.floor(x_anchor)
    assert(type(y_anchor) == "number", "error: y must be an integer")
    y_anchor = math.floor(y_anchor)
    assert(type(z_anchor) == "number", "error: z must be an integer")
    z_anchor = math.floor(z_anchor)
    y_offset = y_offset or 0


    --local meta_data, block_data = readFileHeader()
    local meta_data, block_data = default_meta_data, default_block_data -- for building chunk by chunk with predefined blocks, because max paste is 2^16 chars which is exactly the blocks in one chunk
    if not (meta_data and block_data) then return false end
    assert(y_offset < meta_data.span_y, "y_offset must be smaller than height (span_y) of structure")

    -- open file in binary read mode
    local file = assert(io.open(file_path, "r"))
    -- skip header lines
    --file:read("*line")
    --file:read("*line")

    local file_index = 0 -- start indexing after header lines
    local num_bytes = meta_data.span_x*meta_data.span_z -- number of bytes per x-z-plane / y-level (one byte per block)

    -- compensate for y_offset by skipping bytes in file and adjusting y
    for i = 1, y_offset do
        file:read(num_bytes)
    end
    --y_anchor = y_anchor + y_offset

    -- track coordinates within structure space
    local x_structure = 0
    local y_structure = y_offset
    local z_structure = 0

    -- initialize coordinates of movement lib
    local pose = gps.position()
    movement.setPose(pose.x, pose.y, pose.z, pose.dir)

    while y_structure < meta_data.span_y do
        print("=== placing layer "..tostring(y_structure).." ===")
        local layer_done = false

        -- read layer from bytes in file
        local layer = {} -- x-z-layer (indexed layer[z][x])
        local line = {}  -- x-line
        local bytes = file:read(num_bytes)
        local i = 0 -- count bytes, make new x-line after span_x bytes
        local first_non_zero -- remember first_non_zero element as starting point for placing blocks
        for b in string.gmatch(bytes, ".") do
            local n = string.byte(b) - 0x41
            table.insert(line, n)
            if not first_non_zero and n ~= 0 then
                first_non_zero = {x = i, z = #layer}
            end
            i = i + 1
            if i == meta_data.span_x then
                table.insert(layer, line)
                line = {}
                i = 0
            end
        end

        if not first_non_zero then
            layer_done = true -- if no non-zero block has been found, there is nothing to do in this layer
        else
            x_structure = first_non_zero.x
            z_structure = first_non_zero.z
        end


        while not layer_done do
            local index = layer[z_structure+1][x_structure+1] -- 0-indexed blocks vs 1-indexed arrays
            local block = block_data[index]

            -- if energy low, wait until it isn't
            while computer.energy() < 5000 do os.sleep(1) end

            --                                               +1 because robot places downwards
            movement.moveTo(x_anchor + x_structure, y_anchor + y_structure + 1, z_anchor + z_structure)
            if block ~= "minecraft:air" then
                print(string.format("waiting for block '%s'...", block))
                local s_block = inventory.special_blocks[block]
                if s_block then -- block is a special block
                    while not inventory.selectItem(s_block.name, s_block.label) do -- select slot with block
                        inventory.restock(s_block.name, s_block.label) -- if block not in inventory, try restocking until block is in inventory
                    end
                else
                    while not inventory.selectItem(block) do -- select slot with block
                        inventory.restock(block) -- if block not in inventory, try restocking until block is in inventory
                    end
                end

                robot_api.placeDown() -- place selected block
                print(string.format("placing block '%s' at (%d, %d)", block, x_structure, z_structure))
                layer[z_structure+1][x_structure+1] = 0 -- block has been placed so remove it from layer data
            else
                print(string.format("doing nothing with block '%s' at (%d, %d)", tostring(block), x_structure, z_structure))
            end


            -- find closest non-0 block to placed block
            local r = 0 -- radius from last placed block
            local max_r = 2*math.max(x_structure, meta_data.span_x - x_structure - 1, z_structure, meta_data.span_z - z_structure - 1) -- all blocks outside this radius are outside the structure

            local new_point_found = false
            while not new_point_found do -- loop until non-0 block found (place that block)
                r = r + 1
                if r > max_r then -- or until all blocks checked (no more blocks need to be placed)
                    layer_done = true
                    print(string.format("done checking blocks around (%d, %d) because radius exceeded %d", x_structure, z_structure, max_r))
                    break
                end
                print(string.format("checking blocks around (%d, %d) at radius %d", x_structure, z_structure, r))

                -- make table of all points on a square of distance r around the point
                local points = {}
                --[[
                for i = x_structure - r, x_structure + r do
                    table.insert(points, {x = i, z = z_structure + r})
                    table.insert(points, {x = i, z = z_structure - r})
                end
                for i = z_structure - r + 1, z_structure + r - 1 do
                    table.insert(points, {x = x_structure + r, z = i})
                    table.insert(points, {x = x_structure - r, z = i})
                end
                ]]

                for i = r, 0, -1 do
                    table.insert(points, {x = x_structure + i, z = z_structure + r - i})
                    table.insert(points, {x = x_structure + i, z = z_structure - r + i})
                end
                for i = -1, -r, -1 do
                    table.insert(points, {x = x_structure + i, z = z_structure + r + i})
                    table.insert(points, {x = x_structure + i, z = z_structure - r - i})
                end

                for _, point in ipairs(points) do
                    if (0 <= point.x and point.x <= meta_data.span_x - 1 and 0 <= point.z and point.z <= meta_data.span_z - 1) then -- check if point is within structure
                        if layer[point.z+1][point.x+1] ~= 0 then -- check if placeable block at point
                            new_point_found = true -- choose first point with placeable block as next block to be placed
                            x_structure = point.x
                            z_structure = point.z
                            break
                        end
                    end
                end
            end
        end


        y_structure = y_structure + 1
    end

    file:close()
end



builder.setInputFile("build-structure/input.txt")
--builder.build(0, 0, 0, 0)




return builder
