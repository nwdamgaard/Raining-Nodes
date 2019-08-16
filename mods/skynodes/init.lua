local storage = minetest.get_mod_storage()

local world_size = 25
local block_spawn_freq = 0.05

if storage:contains("block_spawn_freq") then
    block_spawn_freq = tonumber(storage:get("block_spawn_freq"))
else
   
end

local c_bedrock = minetest.get_content_id("bedrock:bedrock")

minetest.set_mapgen_params({mgname="singlenode"})

minetest.register_on_generated(function (minp, maxp, seed)
    if minp.x > world_size then
        return
    end
    if minp.z > world_size then
        return
    end
    if maxp.x < 0 then
        return
    end
    if maxp.z < 0 then
        return
    end
    if(minp.y > 0) then
        return
    end
    if(maxp.y < 0) then
        return
    end

    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
    local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
    
    for i in area:iter(
                    math.max(minp.x, 0), 0, math.max(minp.z, 0),
                    math.min(maxp.x, world_size), 0, math.max(minp.z, world_size)
    ) do
        data[i] = c_bedrock
    end

    vm:set_data(data)
	vm:set_lighting{day=0, night=0}
	vm:calc_lighting()
	vm:write_to_map()

end)

local largest_node_id = 0
minetest.register_on_mods_loaded(function()
    for _ in pairs(minetest.registered_nodes) do
        largest_node_id = largest_node_id + 1
    end
end)

local probabilities = {
    node_types = {"wood", "stone", "water", "ore"},
    weight =     {0.04,    0.949,   0.001,  0.01},
    csum =       {0.04,    0.989,   0.99,    1.0}
}

local ores = {
    "default:stone_with_coal",
    "default:stone_with_iron",
    "default:stone_with_copper",
    "default:stone_with_tin",
    "default:stone_with_gold",
    "default:stone_with_mese",
    "default:stone_with_diamond"
}

local fillerNodes = {
    "default:dirt",
    "default:stone"
}

local node_type_functions = {
    ["wood"] = function() return "default:pine_tree" end,
    ["stone"] = function() return fillerNodes[math.random(#fillerNodes)] end,
    ["water"] = function() return "default:water_source" end,
    ["ore"] = function()
        return ores[math.random(#ores)]
    end
}

function choose_node()
    local chosen_node_type
    local r = math.random()
    for i, csum in pairs(probabilities.csum) do
        if(r < csum) then
            chosen_node_type = probabilities.node_types[i]
            break
        end
    end

    return node_type_functions[chosen_node_type]()
end

local levels = {}
if storage:contains("levels") then
    for x = 0,world_size do
        levels[x] = {}
        for z = 0,world_size do
            levels[x][z] = storage:get_int("levels"..tostring(x)..tostring(z))
        end
    end
else
    storage:set_string("levels", "weeeooo")
    for x = 0,world_size do
        levels[x] = {}
        for z = 0,world_size do
            levels[x][z] = 0
            storage:set_int("levels"..tostring(x)..tostring(z), 0)
        end
    end
end

local timer = 0
minetest.register_globalstep(function (dtime)
    timer = timer + dtime
    if(timer >= block_spawn_freq) then
        timer = 0

        local x = math.random(0, world_size)
        local z = math.random(0, world_size)
        local pos = {x=x, y=10 + levels[x][z], z=z}

        local chosen_node = choose_node()

        minetest.set_node(pos, {name=chosen_node})
        minetest.spawn_falling_node(pos)

        levels[x][z] = levels[x][z] + 1
        storage:set_int("levels"..tostring(x)..tostring(z), levels[x][z])
    end
end)

minetest.register_chatcommand("setblockspawnrate", {
    privs = {server = true},
    func = function (name, param)
        if tonumber(param) ~= nil then
            block_spawn_freq = tonumber(param)
            storage:set_string("block_spawn_freq", tostring(block_spawn_freq))
            return true, "Block spawn rate set successfully!"
        else
            return false, "Error: param is not a number!"
        end
    end
})

minetest.register_on_newplayer(function(player)
    player:set_pos({x=0, y=1, z=0})
    return false
end)