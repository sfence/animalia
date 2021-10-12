--------------------------------------
-- Convert Better Fauna to Animalia --
--------------------------------------

for i = 1, #animalia.mobs do
    local new_mob = animalia.mobs[i]
    local old_mob = "better_fauna:" .. new_mob:split(":")[2]
    minetest.register_entity(":" .. old_mob, {
        on_activate = mob_core.on_activate
    })
    minetest.register_alias_force("better_fauna:spawn_" .. new_mob:split(":")[2], "hades_animalia:spawn_" .. new_mob:split(":")[2])
end

minetest.register_globalstep(function(dtime)
    local mobs = minetest.luaentities
    for _, mob in pairs(mobs) do
        if mob
        and mob.name:match("better_fauna:") then
            if mob.name:find("lasso_fence_ent") then
                local pos = mob.object:get_pos()
                if pos then
                    minetest.add_entity(pos, "hades_animalia:lasso_fence_ent")
                end
                mob.object:remove()
            elseif mob.name:find("lasso_visual") then
                if pos then
                    minetest.add_entity(pos, "hades_animalia:lasso_visual")
                end
                mob.object:remove()
            end
            for i = 1, #animalia.mobs do
                local ent = animalia.mobs[i]
                local new_name = ent:split(":")[2]
                local old_name = mob.name:split(":")[2]
                if new_name == old_name then
                    local pos = mob.object:get_pos()
                    if pos then
                        local new_mob = minetest.add_entity(pos, ent)
                        local mem = nil
                        if mob.memory then
                            mem = mob.memory
                        end
                        minetest.after(0.1, function()
                            if mem then
                                new_mob:get_luaentity().memory = mem
                                new_mob:get_luaentity():on_activate(new_mob, nil, dtime)
                            end
                        end)
                    end
                    mob.object:remove()
                end
            end
        end
    end
end)


-- Tools

minetest.register_alias_force("better_fauna:net", "hades_animalia:net")
minetest.register_alias_force("better_fauna:lasso", "hades_animalia:lasso")
minetest.register_alias_force("better_fauna:cat_toy", "hades_animalia:cat_toy")
minetest.register_alias_force("better_fauna:saddle", "hades_animalia:saddle")
minetest.register_alias_force("better_fauna:shears", "hades_animalia:shears")

-- Drops

minetest.register_alias_force("better_fauna:beef_raw", "hades_animalia:beef_raw")
minetest.register_alias_force("better_fauna:beef_cooked", "hades_animalia:beef_cooked")
minetest.register_alias_force("better_fauna:bucket_milk", "hades_animalia:bucket_milk")
minetest.register_alias_force("better_fauna:leather", "hades_animalia:leather")
minetest.register_alias_force("better_fauna:chicken_egg", "hades_animalia:chicken_egg")
minetest.register_alias_force("better_fauna:chicken_raw", "hades_animalia:poultry_raw")
minetest.register_alias_force("better_fauna:chicken_cooked", "hades_animalia:poultry_cooked")
minetest.register_alias_force("better_fauna:feather", "hades_animalia:feather")
minetest.register_alias_force("better_fauna:mutton_raw", "hades_animalia:mutton_raw")
minetest.register_alias_force("better_fauna:mutton_cooked", "hades_animalia:mutton_cooked")
minetest.register_alias_force("better_fauna:porkchop_raw", "hades_animalia:porkchop_raw")
minetest.register_alias_force("better_fauna:porkchop_cooked", "hades_animalia:porkchop_cooked")
minetest.register_alias_force("better_fauna:turkey_raw", "hades_animalia:poultry_raw")
minetest.register_alias_force("better_fauna:turkey_cooked", "hades_animalia:poultry_cooked")
