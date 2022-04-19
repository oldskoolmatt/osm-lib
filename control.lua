---------------------
---- control.lua ----
---------------------

-- Parse indexing function
local function init_script()

	-- Index disabled items
	global.disabled_item_index = {}
	
	for i, item in pairs(game.item_prototypes) do
		if item.valid and (item.subgroup.name == "OSM-removed" or item.subgroup.name == "OSM-placeholder") then
			global.disabled_item_index[i] = {}
			global.disabled_item_index[i].name = item.name
			global.disabled_item_index[i].subgroup = item.subgroup.name
		end
	end

	-- Regenerate tech tree and recipes
	local researched_technologies = {}
	local infinite = 4294967295 -- FUCK YOU!

	for _, force in pairs(game.forces) do
		for i, technology in pairs(force.technologies) do
			for _, prototype in pairs(game.technology_prototypes) do
				if prototype.valid == true and prototype.name == technology.name and technology.enabled == true then
					if technology.researched == true then
						researched_technologies[i] = {}
						researched_technologies[i].name = technology.name
					elseif technology.researched == false and prototype.max_level == infinite then
						researched_technologies[i] = {}
						researched_technologies[i].name = technology.name
						researched_technologies[i].level = technology.level
					end
				end
			end
		end

		force.reset()

		for _, technology in pairs(researched_technologies) do
			if not technology.level then
				force.technologies[technology.name].researched = true
			elseif technology.level then
				force.technologies[technology.name].level = technology.level
			end
		end
	
		force.reset_technology_effects()
		force.reset_recipes()

	end
end

-- Init
script.on_init(function() init_script() end)
script.on_configuration_changed(function() init_script() end)

-- Remove disabled items from inventory
script.on_event(defines.events.on_player_toggled_alt_mode, function(event)

	if settings.startup["OSM-debug-mode"].value == true then return end
	
	local player = game.connected_players[event.player_index]
	local item_count = 0
	
	if player and player.valid then
		for _, item in pairs(global.disabled_item_index) do

			item_count = player.get_item_count(item.name)

			if item_count > 0 then
				player.remove_item({name=item.name, count=item_count})
			end
		end
	end
end)