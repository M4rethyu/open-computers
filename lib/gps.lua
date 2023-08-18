local movement = require("movement")
local component = require("component")
local sides = require("sides")


local navigation = component.navigation
if navigation == nil then
    error("gps requires a navigation upgrade")
end


local gps = {}

function gps.position()
    local wps = navigation.findWaypoints(1000) -- arg = range to search in. 1000 should cover loaded chunks
    for _, wp in ipairs(wps) do
        local waypoint_x, waypoint_y, waypoint_z = string.match(wp.label, "^(%d+) (%d+) (%d+)$")
        if waypoint_x and waypoint_y and waypoint_z then -- make sure waypoint label matches gps pattern
            -- waypoint.position (relative) is from view of the robot, ie. robot + wp.position = waypoint
            local robot_x = tonumber(waypoint_x) - wp.position[1]
            local robot_y = tonumber(waypoint_y) - wp.position[2]
            local robot_z = tonumber(waypoint_z) - wp.position[3]

            local facing = navigation.getFacing()
            local robot_dir -- translate from sides api to movement.DIRECTION
            if facing == sides.north then robot_dir = movement.DIRECTION.NORTH
            elseif facing == sides.east then robot_dir = movement.DIRECTION.EAST
            elseif facing == sides.south then robot_dir = movement.DIRECTION.SOUTH
            elseif facing == sides.west then robot_dir = movement.DIRECTION.WEST
            end

            local pose = {
                x = math.floor(robot_x + 0.5), -- cast to int by rounding
                y = math.floor(robot_y + 0.5),
                z = math.floor(robot_z + 0.5),
                dir = robot_dir
            }
            return pose
        end
    end
    return nil -- no matching waypoint found, so no position returned
end

return gps
