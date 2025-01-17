--Hume2's Hiking mod

hiking = {}

hiking.base_material = xcompat.materials.dye_white

--You can add another colours here.
hiking.colours = {
	{name = "red", colour = "FF0000", material = xcompat.materials.dye_red},
	{name = "blue", colour = "0000FF", material = xcompat.materials.dye_blue},
	{name = "green", colour = "00C000", material = xcompat.materials.dye_green},
	{name = "yellow", colour = "FFFF00", material = xcompat.materials.dye_yellow},
	--Uncomment this line to add Polish black signs
	--{name = "black", colour = "000000", material = xcompat.materials.dye_black}
}

------------------------------------------------------------------------------------

hiking.sign_box = {
	type = "wallmounted",
	wall_top    = {-0.4375, 0.4375, -0.3125, 0.4375, 0.5, 0.3125},
	wall_bottom = {-0.4375, -0.5, -0.3125, 0.4375, -0.4375, 0.3125},
	wall_side   = {-0.5, -0.3125, -0.4375, -0.4375, 0.3125, 0.4375},
}

hiking.basic_properties = {
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "wallmounted",
	sunlight_propagates = true,
	is_ground_content = false,
	walkable = false,
	node_box = hiking.sign_box,
	groups = {snappy=1, oddly_breakable_by_hand=2, attached_node=1, nostomp=1, hiking=1},
	legacy_wallmounted = true,
	on_place = function(itemstack, placer, pointed_thing)
		local name = placer:get_player_name()
		if minetest.settings:get_bool("hiking.protect_signs", true) then
			local privs = minetest.get_player_privs(name)
			if not (privs.protection_bypass or privs.hiking) then
				minetest.chat_send_player(name, "Missing privilege: hiking")
				return itemstack
			end
		end

		return minetest.item_place(itemstack, placer, pointed_thing)
	end,
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_string("formspec", "field[text;;${text}]")
		meta:set_string("infotext", "")
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if minetest.is_protected(pos, sender:get_player_name()) then
			minetest.record_protection_violation(pos, sender:get_player_name())
			return
		end
		local meta = minetest.get_meta(pos)
		if not fields.text then return end
		minetest.log("action", (sender:get_player_name() or "").." wrote \""..fields.text..
				"\" to hiking sign at "..minetest.pos_to_string(pos))
		meta:set_string("text", fields.text)
		meta:set_string("infotext", fields.text)
	end,
}

local function merge(a, b)
	local c = {}
	for k, v in pairs(a) do
		c[k] = v
	end
	for k, v in pairs(b) do
		c[k] = v
	end
	return c
end

local function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

function hiking.get_texture(colour, style)
	return "((hiking_white.png^hiking_noise.png)^[mask:hiking_" .. style.id .. "_white.png)^(((hiking_white.png^[colorize:#" .. colour.colour .. ")^hiking_noise.png)^[mask:hiking_" .. style.id .. "_colour.png)"
end

function hiking.register_sign(colour, style, direction)
	local inv = hiking.get_texture(colour, style)
	local inv2 = "hiking_sign_pole.png^" .. inv
	local desc = firstToUpper(colour.name) .. " " .. style.title
	local my_groups = {snappy=1, oddly_breakable_by_hand=2, attached_node=1, nostomp=1, hiking=1}
	if (direction ~= nil) then
		desc = desc .. " " .. direction
		my_groups["hiking_turn_" .. colour.name] = 1
	end

	minetest.register_node("hiking:" .. style.id .. colour.name, merge(hiking.basic_properties, {
		description = desc,
		tiles = {inv},
		inventory_image = inv,
		wield_image = inv,
		groups = my_groups,
		use_texture_alpha = "blend",
	}))
end

function hiking.register_pole(colour, style)
	local inv = hiking.get_texture(colour, style)
	local desc = firstToUpper(colour.name) .. " " .. style.title
	local base_id = "hiking:" .. style.id .. colour.name
	local inv1 = "hiking_sign_pole.png^" .. inv
	local inv2 = "hiking_sign_pole_thin.png^" .. inv

	minetest.register_node("hiking:pole_" .. style.id .. colour.name, merge(hiking.basic_properties, {
		description = desc .. " on Pillar",
		tiles = {inv},
		inventory_image = inv1,
		wield_image = inv1,
		drawtype = "mesh",
		mesh = "hiking_pole.obj",
		selection_box = hiking.sign_box
	}))

	minetest.register_node("hiking:pole2_" .. style.id .. colour.name, merge(hiking.basic_properties, {
		description = desc .. " on Pole",
		tiles = {inv},
		inventory_image = inv2,
		wield_image = inv2,
		drawtype = "mesh",
		mesh = "hiking_pole_thin.obj",
		selection_box = hiking.sign_box
	}))

	minetest.register_craft({
		output = "hiking:pole_" .. style.id .. colour.name .. " 2",
		recipe = {{ base_id },
			  { base_id }}
	})

	minetest.register_craft({
		output = base_id,
		type = "shapeless",
		recipe = { "hiking:pole_" .. style.id .. colour.name}
	})

	minetest.register_craft({
		output = "hiking:pole2_" .. style.id .. colour.name .. " 3",
		recipe = {{ base_id },
			  { base_id },
			  { base_id }}
	})

	minetest.register_craft({
		output = "hiking:" .. style.id .. colour.name,
		type = "shapeless",
		recipe = { "hiking:pole2_" .. style.id .. colour.name}
	})
end

function hiking.register_sign_lr(colour, style)
	hiking.register_sign(colour, style, nil)
	hiking.register_sign(colour, {id = style.id .. "_left", title = style.title}, "Left")
	hiking.register_sign(colour, {id = style.id .. "_right", title = style.title}, "Right")
	hiking.register_pole(colour, style)

	local base_sign = "hiking:" .. style.id .. colour.name
	local left_sign = "hiking:" .. style.id .. "_left" .. colour.name
	local right_sign = "hiking:" .. style.id .. "_right" .. colour.name

	minetest.register_craft({
		output = right_sign .. " 6",
		recipe = {{ base_sign, base_sign, "" },
			  { base_sign, base_sign, colour.material },
			  { base_sign, base_sign, "" }}
	})

	minetest.register_craft({
		output = left_sign .. " 6",
		recipe = {{ "", base_sign, base_sign },
			  { colour.material, base_sign, base_sign },
			  { "", base_sign, base_sign }}
	})

end

-------------------------------------

for _, colour in pairs(hiking.colours) do
	hiking.register_sign_lr(colour, {id = "sign", title = "Hiking Sign"})
	hiking.register_sign(colour, {id = "end", title = "End Sign"}, nil)
	hiking.register_sign_lr(colour, {id = "local", title = "Local Hiking Sign"})
	hiking.register_sign_lr(colour, {id = "educational", title = "Educational Path"})
	hiking.register_sign_lr(colour, {id = "castle", title = "Castle Branch"})
	hiking.register_sign_lr(colour, {id = "curiosity", title = "Curiosity Branch"})
	hiking.register_sign_lr(colour, {id = "peak", title = "Peak Branch"})
	hiking.register_sign_lr(colour, {id = "spring", title = "Spring Branch"})

	local base_id = "hiking:sign" .. colour.name

	minetest.register_craft({
		output = base_id .. " 18",
		recipe = {{ hiking.base_material },
			  { colour.material },
			  { hiking.base_material }}
	})

	minetest.register_craft({
		output = "hiking:end" .. colour.name .. " 2",
		recipe = {{ base_id, base_id }}
	})

	minetest.register_craft({
		output = "hiking:local" .. colour.name .. " 3",
		recipe = {{ base_id, base_id },
			  { "", base_id }}
	})

	minetest.register_craft({
		output = "hiking:educational" .. colour.name .. " 2",
		recipe = {{ base_id, "" },
			  { "", base_id }}
	})

	minetest.register_craft({
		output = "hiking:castle" .. colour.name .. " 3",
		recipe = {{ base_id, "" },
			  { base_id, base_id }}
	})

	minetest.register_craft({
		output = "hiking:curiosity" .. colour.name .. " 4",
		recipe = {{ "", base_id, "" },
			  { base_id, base_id, base_id }}
	})

	minetest.register_craft({
		output = "hiking:peak" .. colour.name .. " 5",
		recipe = {{ "", base_id, "" },
			  { "", base_id, ""},
			  { base_id, base_id, base_id }}
	})

	minetest.register_craft({
		output = "hiking:spring" .. colour.name .. " 4",
		recipe = {{ base_id, base_id, base_id },
			  { "", base_id, "" }}
	})

	--recycling

	minetest.register_craft({
		output = base_id,
		type = "shapeless",
		recipe = {"hiking:end" .. colour.name}
	})

	minetest.register_craft({
		output = base_id,
		type = "shapeless",
		recipe = {"hiking:local" .. colour.name}
	})

	minetest.register_craft({
		output = base_id,
		type = "shapeless",
		recipe = {"hiking:educational" .. colour.name}
	})

	minetest.register_craft({
		output = base_id,
		type = "shapeless",
		recipe = {"hiking:castle" .. colour.name}
	})

	minetest.register_craft({
		output = base_id,
		type = "shapeless",
		recipe = {"hiking:curiosity" .. colour.name}
	})

	minetest.register_craft({
		output = base_id,
		type = "shapeless",
		recipe = {"hiking:peak" .. colour.name}
	})

	minetest.register_craft({
		output = base_id,
		type = "shapeless",
		recipe = {"hiking:spring" .. colour.name}
	})

	local gr = "group:hiking_turn_" .. colour.name

	minetest.register_craft({
		output = base_id .. " 12",
		type = "shapeless",
		recipe = {gr, gr, gr, hiking.base_material}
	})
end

minetest.register_privilege("hiking", {
	description = "Allows player to place and remove hiking signs and nodes right next to hiking signs.",
	give_to_singleplayer = true,
});

local hiking_directions = {
	[0] = {x=0, y=-1, z=0},
	[1] = {x=0, y=1, z=0},
	[2] = {x=-1, y=0, z=0},
	[3] = {x=1, y=0, z=0},
	[4] = {x=0, y=0, z=-1},
	[5] = {x=0, y=0, z=1},
}
local old_is_protected = minetest.is_protected

minetest.is_protected = function(pos, pname)
	if old_is_protected(pos, pname) then
		return true
	end

	if not minetest.settings:get_bool("hiking.protect_signs", true) then
		return false
	end
	
	if minetest.check_player_privs(pname, {protection_bypass = true}) or minetest.check_player_privs(pname, {hiking = true}) then
		return false
	end
	
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "hiking") > 0 then
		return true
	end
	
	for p2, dir in pairs(hiking_directions) do
		node = minetest.get_node(vector.add(pos, dir))
		if minetest.get_item_group(node.name, "hiking") > 0 and node.param2 == p2 then
			return true
		end
	end
	
	return false
end
