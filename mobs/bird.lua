---------------
-- Song Bird --
---------------

local follows = {}

minetest.register_on_mods_loaded(function()
	for name in pairs(minetest.registered_items) do
		if name:match(":seed_")
		or name:match("_seed") then
			table.insert(follows, name)
		end
	end
end)

local random = math.random

local vec_dist = vector.distance

creatura.register_mob("hades_animalia:bird", {
	-- Stats
	max_health = 5,
	armor_groups = {fleshy = 200},
	damage = 0,
	speed = 4,
	tracking_range = 16,
	despawn_after = 100,
	-- Entity Physics
	stepheight = 1.1,
	max_fall = 0,
	turn_rate = 6,
	boid_seperation = 0.4,
	-- Visuals
	mesh = "animalia_bird.b3d",
	hitbox = {
		width = 0.15,
		height = 0.3
	},
	visual_size = {x = 7, y = 7},
	textures = {
		"animalia_bird_cardinal.png",
		"animalia_bird_eastern_blue.png",
		"animalia_bird_goldfinch.png"
	},
	animations = {
		stand = {range = {x = 1, y = 40}, speed = 10, frame_blend = 0.3, loop = true},
		walk = {range = {x = 50, y = 70}, speed = 30, frame_blend = 0.3, loop = true},
		fly = {range = {x = 120, y = 140}, speed = 80, frame_blend = 0.3, loop = true}
	},
	-- Misc
	step_delay = 0.25,
	catch_with_net = true,
	catch_with_lasso = false,
	sounds = {
		cardinal = {
			name = "animalia_cardinal",
			gain = 0.5,
			distance = 63,
			variations = 3
		},
		eastern_blue = {
			name = "animalia_eastern_blue",
			gain = 0.5,
			distance = 63,
			variations = 3
		},
		goldfinch = {
			name = "animalia_goldfinch",
			gain = 0.5,
			distance = 63,
			variations = 3
		},
	},
	follow = follows,
	-- Function
	wander_action = animalia.action_move_flock,
	utility_stack = {
		{
			utility = "hades_animalia:wander_group",
			step_delay = 0.25,
			get_score = function(self)
				return 0.1, {self, true}
			end
		},
		{
			utility = "hades_animalia:aerial_wander",
			step_delay = 0.25,
			get_score = function(self)
				if not self.is_landed
				or self.in_liquid then
					return 0.2, {self}
				end
				return 0
			end
		},
		{
			utility = "hades_animalia:fly_to_land",
			get_score = function(self)
				if self.is_landed
				and not self.touching_ground
				and not self.in_liquid
				and creatura.sensor_floor(self, 3, true) > 2 then
					return 0.3, {self}
				end
				return 0
			end
		},
		{
			utility = "hades_animalia:fly_to_roost",
			get_score = function(self)
				local pos = self.object:get_pos()
				if not pos then return end
				local player = creatura.get_nearby_player(self)
				if player
				and player:get_pos() then
					local dist = vector.distance(pos, player:get_pos())
					if dist < 3 then
						return 0
					end
				end
				local home = not animalia.is_day and self.home_position
				if home
				and vec_dist(pos, home) < 8 then
					return 0.6, {self}
				end
				return 0
			end
		}
	},
	activate_func = function(self)
		animalia.initialize_api(self)
		animalia.initialize_lasso(self)
		self._tp2home = self:recall("_tp2home") or nil
		self.home_position = self:recall("home_position") or nil
		if self._tp2home
		and self.home_position then
			self.object:set_pos(self.home_position)
		end
		self.is_landed = self:recall("is_landed") or false
		if not self.home_position then
			local pos = self.object:get_pos()
			local nests = minetest.find_nodes_in_area_under_air(
				vector.add(pos, 4),
				vector.subtract(pos, 4),
				{"hades_animalia:nest_song_bird"}
			)
			if nests[1]
			and minetest.get_natural_light(nests[1]) > 0 then
				self.home_position = self:memorize("home_position", nests[1])
			end
		end
	end,
	step_func = function(self)
		animalia.step_timers(self)
		animalia.do_growth(self, 60)
		animalia.update_lasso_effects(self)
		animalia.rotate_to_pitch(self)
		if self:timer(random(10,15)) then
			if animalia.is_day then
				if self.texture_no == 1 then
					self:play_sound("cardinal")
				elseif self.texture_no == 2 then
					self:play_sound("eastern_blue")
				else
					self:play_sound("goldfinch")
				end
			end
			if random(4) < 2 then
				self.is_landed = not self.is_landed
			end
			local home = self.home_position
			if home
			and creatura.get_node_def(home).name ~= "hades_animalia:nest_song_bird" then
				local nodes = minetest.find_nodes_in_area_under_air(
					{x = home.x, y = home.y - 12, z = home.z},
					{x = home.x, y = home.y + 12, z = home.z},
					{"hades_animalia:nest_song_bird"}
				)
				if nodes[1] then
					self.home_position = self:memorize("home_position", nodes[1])
				end
			end
		end
		if not self.is_landed
		or not self.touching_ground then
			self.speed = 4
		else
			self.speed = 1
		end
	end,
	death_func = function(self)
		if self:get_utility() ~= "hades_animalia:die" then
			self:initiate_utility("hades_animalia:die", self)
		end
	end,
	deactivate_func = function(self)
		if self:get_utility()
		and self:get_utility() == "hades_animalia:return_to_nest" then
			local pos = self.home_position
			local node = minetest.get_node_or_nil(pos)
			if node
			and node.name == "hades_animalia:nest_song_bird"
			and minetest.get_natural_light(pos) > 0 then
				self:memorize("_tp2home", true)
			end
		end
	end,
	on_rightclick = function(self, clicker)
		if animalia.feed(self, clicker, false, false) then
			return
		end
		if animalia.set_nametag(self, clicker) then
			return
		end
		animalia.add_libri_page(self, clicker, {name = "bird", form = "pg_bird;Birds"})
	end,
	on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
		creatura.basic_punch_func(self, puncher, time_from_last_punch, tool_capabilities, direction, damage)
	end
})

creatura.register_spawn_egg("hades_animalia:bird", "ae2f2f", "f3ac1c")

minetest.register_abm({
	label = "hades_animalia:nest_cleanup",
	nodenames = "hades_animalia:nest_song_bird",
	interval = 900,
	action = function(pos)
		minetest.remove_node(pos)
	end
})
