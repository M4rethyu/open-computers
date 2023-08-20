local robot_api = require("robot")
local movement = require("movement")
local gps = require("gps")


local builder = {}

-- see if the file exists
function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist

function lines_from(file)
    if not file_exists(file) then return {} end
    local lines = {}
    for line in io.lines(file) do
        lines[#lines + 1] = line
    end
    return lines
end


-- tests the functions above

-- print all line numbers and their contents
--for k,v in pairs(lines) do
--  print('line[' .. k .. ']', v)
--end

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
        local match = string.gmatch(line2, "(%d+)=([a-z:]+)")
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


function builder.build(x_anchor, y_anchor, z_anchor, y_offset) -- skip all layers until layer start_y (0 indexed)
    assert(type(x_anchor) == "number", "error: x must be an integer")
    x_anchor = math.floor(x_anchor)
    assert(type(y_anchor) == "number", "error: y must be an integer")
    y_anchor = math.floor(y_anchor)
    assert(type(z_anchor) == "number", "error: z must be an integer")
    z_anchor = math.floor(z_anchor)
    y_offset = y_offset or 0


    local meta_data, block_data = readFileHeader()
    if not (meta_data and block_data) then return false end
    assert(y_offset < meta_data.span_y, "y_offset must be smaller than height (span_y) of structure")

    -- open file in binary read mode
    local file = assert(io.open(file_path, "rb"))
    -- skip header lines
    file:read("*line")
    file:read("*line")

    local file_index = 0 -- start indexing after header lines
    local num_bytes = meta_data.span_x*meta_data.span_z -- number of bytes per x-z-plane / y-level (one byte per block)

    -- compensate for y_offset by skipping bytes in file and adjusting y
    for i = 1, y_offset do
        file:read(num_bytes)
    end
    y_anchor = y_anchor + y_offset

    -- track coordinates within structure space
    local x_structure, y_structure, z_structure = 0, y_offset, 0

    -- initialize coordinates of movement
    local pose = gps.position()
    movement.setPose(pose.x, pose.y, pose.z, pose.dir)

    -- read layer from bytes in file
    local layer = {} -- x-z-layer
    local line = {}  -- x-line
    local bytes = file:read(num_bytes)
    local i = 0 -- count bytes, make new x-line after span_x bytes
    local first_non_zero -- remember first_non_zero element as starting point for placing blocks <-TODO
    for b in string.gmatch(bytes, ".") do
        table.insert(line, string.byte(b))
        i = i + 1
        if i == meta_data.span_x then
            table.insert(layer, line)
            line = {}
            i = 0
        end
    end

    for _, line in ipairs(layer) do
        for _, n in ipairs(line) do
            io.write(tostring(n).." ")
        end
        io.write("\n")
    end

    local block
    for z_structure, line in ipairs(layer) do
        z_structure = z_structure - 1
        for x_structure, n in ipairs(line) do
            x_structure = x_structure - 1
            block = block_data[n]
            -- todo: move to (x, y+1, z) and place block below
            movement.moveTo(x_anchor + x_structure, y_anchor + y_structure, z_anchor + z_structure)
            if block == "minecraft:stone" then
                robot_api.placeDown()
            end
            print(string.format("placing block '%s' at (%d, %d, %d)", block, x_structure, y_structure, z_structure))
        end
    end

    file:close()
end



builder.setInputFile("build-structure/input_.txt")
builder.build(0, 0, 0, 0)




return builder
