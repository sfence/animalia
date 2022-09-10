-------------
-- Chicken --
-------------

local follows = {}

minetest.register_on_mods_loaded(function()
    for name in pairs(minetest.registered_items) do
        if name:match(":seed_")
		or name:match("_seed") then
			table.insert(follows, name)
        end
    end
end)

creatura.register_mob("hades_animalia:chicken", {
    -- Stats
    max_health = 5,
    armor_groups = {fleshy = 150},
    damage = 0,
    speed = 4,
	tracking_range = 4,
    despawn_after = 1500,
	-- Entity Physics
	stepheight = 1.1,
	max_fall = 8,
	turn_rate = 7,
    -- Visuals
    mesh = "animalia_chicken.b3d",
	hitbox = {
		width = 0.15,
		height = 0.3
	},
    visual_size = {x = 7, y = 7},
	female_textures = {
		"animalia_chicken_1.png",
		"animalia_chicken_2.png",
		"animalia_chicken_3.png"
	},
	male_textures = {
		"animalia_rooster_1.png",
		"animalia_rooster_2.png",
		"animalia_rooster_3.png"
	},
	child_textures = {"animalia_chicken_child.png"},
    animations = {
		stand = {range = {x = 1, y = 39}, speed = 20, frame_blend = 0.3, loop = true},
		walk = {range = {x = 41, y = 59}, speed = 30, frame_blend = 0.3, loop = true},
		run = {range = {x = 41, y = 59}, speed = 45, frame_blend = 0.3, loop = true},
		eat = {range = {x = 61, y = 89}, speed = 45, frame_blend = 0.3, loop = true},
        fall = {range = {x = 91, y = 99}, speed = 70, frame_blend = 0.3, loop = true}
	},
    -- Misc
	catch_with_net = true,
	catch_with_lasso = true,
    sounds = {
        random = {
            name = "animalia_chicken_idle",
            gain = 0.5,
            distance = 8
        },
        hurt = {
            name = "animalia_chicken_hurt",
            gain = 0.5,
            distance = 8
        },
        death = {
            name = "animalia_chicken_death",
            gain = 0.5,
            distance = 8
        }
    },
    drops = {
        {name = "hades_animalia:poultry_raw", min = 1, max = 3, chance = 1},
		{name = "hades_animalia:feather", min = 1, max = 3, chance = 2}
    },
    follow = follows,
	head_data = {
		offset = {x = 0, y = 0.45, z = 0},
		pitch_correction = 40,
		pivot_h = 0.25,
		pivot_v = 0.55
	},
    -- Function
	add_child = function(self)
		local pos = self.object:get_pos()
		if not pos then return end
		minetest.add_particlespawner({
			amount = 6,
			time = 0.25,
			minpos = {x = pos.x - 7/16, y = pos.y - 5/16, z = pos.z - 7/16},
			maxpos = {x = pos.x + 7/16, y = pos.y - 5/16, z = pos.z + 7/16},
			minvel = vector.new(-1, 2, -1),
			maxvel = vector.new(1, 5, 1),
			minacc = vector.new(0, -9.81, 0),
			maxacc = vector.new(0, -9.81, 0),
			collisiondetection = true,
			texture = "animalia_egg_fragment.png",
		})
		local object = minetest.add_entity(pos, self.name)
		local ent = object:get_luaentity()
		ent.growth_scale = 0.7
		animalia.initialize_api(ent)
		animalia.protect_from_despawn(ent)
	end,
	utility_stack = {
		{
			utility = "hades_animalia:wander_group",
			step_delay = 0.25,
			get_score = function(self)
				return 0.1, {self}
			end
		},
		{
			utility = "hades_animalia:swim_to_land",
			step_delay = 0.25,
			get_score = function(self)
				if self.in_liquid then
					return 0.5, {self}
				end
				return 0
			end
		},
		{
			utility = "hades_animalia:follow_player",
			get_score = function(self)
				local lasso = type(self.lasso_origin or {}) == "userdata" and self.lasso_origin
				local force = lasso and lasso ~= false
				local player = (force and lasso) or creatura.get_nearby_player(self)
				if player
				and self:follow_wielded_item(player) then
					return 0.3, {self, player}
				end
				return 0
			end
		},
		{
			utility = "hades_animalia:breed",
			step_delay = 0.25,
			get_score = function(self)
				if self.breeding
				and animalia.get_nearby_mate(self, self.name) then
					return 0.4, {self}
				end
				return 0
			end
		},
		{
			utility = "hades_animalia:flee_from_target",
			get_score = function(self)
				local puncher = self._target
				if puncher
				and puncher:get_pos() then
					return 0.6, {self, puncher}
				end
				self._target = nil
				return 0
			end
		}
	},
    activate_func = function(self)
		animalia.initialize_api(self)
		animalia.initialize_lasso(self)
    end,
    step_func = function(self)
		animalia.step_timers(self)
		animalia.head_tracking(self, 0.75, 0.75)
		animalia.do_growth(self, 60)
		animalia.update_lasso_effects(self)
		if self.fall_start then
			self:set_gravity(-4.9)
			self:animate("fall")
		end
		if self:timer(60) then
			animalia.random_drop_item(self, "hades_animalia:chicken_egg", 3)
		end
    end,
    death_func = function(self)
		if self:get_utility() ~= "hades_animalia:die" then
			self:initiate_utility("hades_animalia:die", self)
		end
    end,
	on_rightclick = function(self, clicker)
		if animalia.feed(self, clicker, false, true) then
			return
		end
		if animalia.set_nametag(self, clicker) then
			return
		end
		animalia.add_libri_page(self, clicker, {name = "chicken", form = "pg_chicken;Chickens"})
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		creatura.basic_punch_func(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		self._target = puncher
	end
})

creatura.register_spawn_egg("hades_animalia:chicken", "c6c6c6", "d22222")
