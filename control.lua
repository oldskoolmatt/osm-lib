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
		end
	end

	-- Reset technologies and recipes
	for _, force in pairs(game.forces) do
		for _, technology in pairs(game.technology_prototypes) do
			if force.technologies[technology.name] and technology.valid and not technology.enabled then
				
				local force_technology = force.technologies[technology.name]
				
				force_technology.researched = false
				force_technology.enabled = false

				if force.get_saved_technology_progress(technology.name) then force.set_saved_technology_progress(technology.name, nil) end
				if force.current_research == technology.name then force.cancel_current_research() end
			end
		end

		force.reset_technologies()
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