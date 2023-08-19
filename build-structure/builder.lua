


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


function builder.build(x, y, z, y_offset) -- skip all layers until layer start_y (0 indexed)
    y_offset = y_offset or 0

    local meta_data, block_data = readFileHeader()
    if not (meta_data and block_data) then return false end

    local file = assert(io.open(file_path, "rb"))
    -- skip header lines
    file:read("*line")
    file:read("*line")

    local file_index = 0 -- start indexing after header lines
    local num_bytes = meta_data.span_x*meta_data.span_z -- number of bytes per x-z-plane / y-level (one byte per block)
    for i = 0, y_offset do

    end


    local function buildLayer(yLevel)

    end


    local bytes = file:read(num_bytes)
    local line = ""
    for b in string.gfind(bytes, ".") do
        line = line..string.format("%02X ", string.byte(b))
        if string.len(line) >= 12 then
            print(line)
            line = ""
        end
    end

end



builder.setInputFile("build-structure/input_.txt")
--readFileHeader()
builder.build(0)




return builder
