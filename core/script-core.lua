local OSM_core = {}

-- Index prototype base properties
function OSM_core.index_icons()

	local function index_icon(prototype, external_prototype)
		
		if not OSM.log.missing_icons then OSM.log.missing_icons = {} end
		
		local icons_index = {}

		local icon_size = false
		local icon_mipmaps = false
		local scale = false
		local tint = false
		local shift = false

		if prototype.icon_size or (external_prototype and external_prototype.icon_size) then icon_size = prototype.icon_size or external_prototype.icon_size end
		if prototype.icon_mipmaps or (external_prototype and external_prototype.icon_mipmaps) then icon_mipmaps = prototype.icon_mipmaps or external_prototype.icon_mipmaps end
		if prototype.scale or (external_prototype and external_prototype.scale) then scale = prototype.scale or external_prototype.scale end
		if prototype.tint or (external_prototype and external_prototype.tint) then tint = prototype.tint or external_prototype.tint end
		if prototype.shift or (external_prototype and external_prototype.shift) then shift = prototype.shift or external_prototype.shift end
		
		if prototype.icons then
			icons_index = prototype.icons
		elseif prototype.icon then
			icons_index =
			{
				{
					icon=prototype.icon,
					scale=prototype.scale,
					icon_size=prototype.icon_size,
					icon_mipmaps=prototype.icon_mipmaps,
					tint=prototype.tint,
					shift=prototype.shift
				}
			}
		end
		
		if external_prototype and not prototype.icons and not prototype.icon then
			if external_prototype.icons then
				icons_index = external_prototype.icons
			elseif external_prototype.icon then
				icons_index =
				{
					{
						icon=external_prototype.icon,
						scale=external_prototype.scale,
						icon_size=external_prototype.icon_size,
						icon_mipmaps=external_prototype.icon_mipmaps,
						tint=external_prototype.tint,
						shift=external_prototype.shift
					}
				}
			end
		end
		
		for i, _ in pairs(icons_index) do
			if icon_size and not icons_index[i].icon_size then
				icons_index[i].icon_size = icon_size
			end
			if icon_mipmaps and not icons_index[i].icon_mipmaps then
				icons_index[i].icon_mipmaps = icon_mipmaps
			end
			if scale and not icons_index[i].scale then
				icons_index[i].scale = scale
			end
			if tint and not icons_index[i].tint then
				icons_index[i].tint = tint
			end
			if shift and not icons_index[i].shift then
				icons_index[i].shift = shift
			end
		end
		
		if icons_index[1] then
			
			if not OSM.table.prototype_index[prototype.type] then OSM.table.prototype_index[prototype.type] = {} end
			if not OSM.table.prototype_index[prototype.type][prototype.name] then OSM.table.prototype_index[prototype.type][prototype.name] = {} end
			
			OSM.table.prototype_index[prototype.type][prototype.name].icons = icons_index

		else
			table.insert(OSM.log.missing_icons, "Failed to index icon for: ("..prototype.type..") "..'"'..prototype.name..'"')
		end
	end

	for _, fluid in pairs(data.raw.fluid) do
		index_icon(fluid)
	end
	
	for _, item_type in pairs(OSM.item_types) do
		for _, item in pairs(data.raw[item_type]) do
			index_icon(item)
		end
	end
	
	for _, entity_type in pairs(OSM.entity_types) do
		for _, entity in pairs(data.raw[entity_type]) do		
			if entity.flags then
				for _, flag in pairs(entity.flags) do
					if flag == "placeable-neutral" or "placeable-player" or "placeable-enemy" then
						index_icon(entity)
						goto jump
					end
				end
			end
			::jump::
		end
	end

	for _, recipe in pairs(data.raw.recipe) do
		if recipe.icon or recipe.icons then
			index_icon(recipe)
		elseif not recipe.icon and not recipe.icons then

			local result = OSM.lib.get_main_result_prototype(recipe.name, true)
			
			if result then
				index_icon(recipe, result)
			end
		end
	end
end

-- Generate missing subgroups
function OSM_core.generate_subgroups()

	if not OSM.log.missing_subgroup then OSM.log.missing_subgroup = {} end

	for _, fluid in pairs(data.raw.fluid) do
		if not fluid.subgroup then
			table.insert(OSM.log.missing_subgroup, "Fluid: "..'"'..fluid.name..'"'.." does not have a subgroup")
		end
	end

	for _, item_type in pairs(OSM.item_types) do
		for _, item in pairs(data.raw[item_type]) do
			if not item.subgroup then
				table.insert(OSM.log.missing_subgroup, "Item: ("..item.type..") "..'"'..item.name..'"'.." does not have a subgroup")
			end

			-- Check entities
			if item.subgroup and item.place_result then
				
				local entity = OSM.lib.get_entity_prototype(item.place_result)				

				if entity then
					if not entity.placeable_by and not entity.subroup then
						entity.subgroup = item.subgroup
						if item.order then
							entity.order = item.order
						else
							entity.order = nil
						end
						
						if not entity.subgroup then
							table.insert(OSM.log.missing_subgroup, "Failed to assign subgroup to entity: "..entity.name.." placeable by: "..item.name)
						end
					end
				end
			end
		end
	end
	
	for _, entity_type in pairs(OSM.entity_types) do
		for _, entity in pairs(data.raw[entity_type]) do		
			if entity.placeable_by then
			
				local item = OSM.lib.get_item_prototype(entity.placeable_by.item)
				
				if item then
					if item.place_result and entity.name ~= item.place_result then
						entity.subgroup = item.subgroup
						if item.order then
							entity.order = item.order
						else
							entity.order = nil
						end
					end
					if not entity.subgroup then
						table.insert(OSM.log.missing_subgroup, "Failed to assign subgroup to entity: ("..entity.type..") "..'"'..entity.name..'"'.." placed by: "..'"'..item.name..'"')
					end
				end
			end
		end
	end

	for _, recipe in pairs(data.raw.recipe) do
		if not recipe.subgroup then

			local result = OSM.lib.get_main_result_prototype(recipe.name)

			-- Assign subgroup to recipe
			if result and result.subgroup then
				recipe.subgroup = result.subgroup
				if result.order then
					recipe.order = result.order
				else
					recipe.order = nil
				end
	
				if not recipe.subgroup then
					table.insert(OSM.log.missing_subgroup, "Failed to assign a subgroup to recipe: "..'"'..recipe.name..'"'.." from result: "..'"'..result.name..'"')
				end
			end
		end
	end
end

-- Disable prototypes
function OSM_core.disable_prototypes()

	OSM.log.disabled_prototypes = {}
	OSM.log.enabled_prototypes = {}

	local function disable_technology(technology)

		if not data.raw.technology[technology.name] then return end

		local mod_name = technology.mod_name
		local technology = data.raw.technology[technology.name]
		
		technology.enabled = false
		technology.OSM_removed = true
		technology.OSM_regenerate = true

		technology.icon = "__osm-lib__/graphics/ban-technology.png"
		technology.icon_size = 128
		technology.icon_mipmaps = nil
		technology.effects = {}
		technology.icons = nil
		technology.max_level  = nil
		technology.prerequisites = {}
		technology.localised_name = {"", technology.name}
		technology.localised_description = {"", "Disabled by: "..mod_name}
		
		if not OSM.debug_mode then technology.hidden = true end
		if OSM.debug_mode then technology.visible_when_disabled = true end

		-- Removes technology from other techs prerequisites
		for _, tech in pairs(data.raw.technology) do
			if tech.prerequisites then
				for i, prerequisite in pairs (tech.prerequisites) do
					if prerequisite == technology.name then

						table.insert(OSM.log.technology, "Mod: "..'"'..mod_name..'"'..": Successfully removed prerequisite: "..'"'..technology.name..'"'.." from technology: "..'"'..tech.name..'"')
						table.remove(technology.prerequisites, i)
					end
				end
			end
		end
		table.insert(OSM.log.disabled_prototypes, "Mod: "..'"'..mod_name..'"'..": Successfully disabled technology: "..'"'..technology.name..'"')
	end

	local function disable_recipe(recipe)
		if data.raw.recipe[recipe.name] then
	
			local mod_name = recipe.mod_name
			local recipe = data.raw.recipe[recipe.name]

			recipe.subgroup = "OSM-removed"
			recipe.OSM_removed = true
			recipe.OSM_regenerate = true
	
			recipe.enabled = false
			recipe.category = nil

			recipe.localised_name = {"", recipe.name}
			recipe.localised_description = {"", "Disabled by: "..mod_name}
			
			if not OSM.debug_mode then recipe.hidden = true end

			if recipe.normal and recipe.normal.ingredients then
				recipe.normal.ingredients = {}
				recipe.normal.results = OSM.void_results
				recipe.normal.main_product = ""
				recipe.normal.result = nil
			end

			if recipe.expensive and recipe.expensive.ingredients then
				recipe.expensive.ingredients = {}
				recipe.expensive.results = OSM.void_results
				recipe.expensive.main_product = ""
				recipe.expensive.result = nil
			end
			
			if recipe.ingredients then
				recipe.ingredients = {}
				recipe.results = OSM.void_results
				recipe.main_product = ""
				recipe.result = nil
			end
			
			OSM.mod = "OSM-Lib"
			OSM.lib.technology_remove_unlock(recipe.name)
			OSM.lib.recipe_remove_module_limitation(recipe.name)
			OSM.mod = nil
			
			table.insert(OSM.log.disabled_prototypes, "Mod: "..'"'..mod_name..'"'..": Successfully disabled recipe: "..'"'..recipe.name..'"')
		end
	end

	local function disable_item(item)
		if data.raw[item.type][item.name] then

			local mod_name = item.mod_name
			local item = data.raw[item.type][item.name]

			item.subgroup = "OSM-removed"
			item.OSM_removed = true
			item.OSM_regenerate = true

			item.place_result = nil

			item.localised_name = {"", item.name}
			item.localised_description = {"", "Disabled by: "..mod_name}
			
			if not OSM.debug_mode then item.flags = {"hidden"} end
			
			table.insert(OSM.log.disabled_prototypes, "Mod: "..'"'..mod_name..'"'..": Successfully disabled item: ("..item.type..") "..'"'..item.name..'"')
		end
	end
	
	local function disable_fluid(fluid)
		if data.raw.fluid[fluid.name] then

			local mod_name = fluid.mod_name
			local fluid = data.raw.fluid[fluid.name]

			fluid.place_result = nil
			fluid.subgroup = "OSM-removed"
			fluid.OSM_removed = true
			fluid.OSM_regenerate = true

			fluid.localised_name = {"", fluid.name}
			fluid.localised_description = {"", "Disabled by: "..mod_name}
			
			if not OSM.debug_mode then fluid.hidden = true end

			table.insert(OSM.log.disabled_prototypes, "Mod: "..'"'..mod_name..'"'..": Successfully disabled fluid: "..'"'..fluid.name..'"')
		end
	end

	local function disable_entity(entity)
		if data.raw[entity.type][entity.name] then

			local mod_name = entity.mod_name
			local entity = data.raw[entity.type][entity.name]
			
			local result = {}
			if (entity.minable and entity.minable.result) or entity.placeable_by then
				result = entity.minable.result or entity.placeable_by
				entity.minable.result = nil
			else
				result = nil
			end

			entity.subgroup = "OSM-removed"
			entity.OSM_removed = true
			entity.OSM_regenerate = true
			entity.next_upgrade = nil
			entity.placeable_by = nil

			entity.localised_name = {"", entity.name}
			entity.localised_description = {"", "Disabled by: "..mod_name}
			
			if not OSM.debug_mode then entity.flags = {"hidden"} end
			
			table.insert(OSM.log.disabled_prototypes, "Mod: "..'"'..mod_name..'"'..": Successfully disabled entity: ("..entity.type..") "..'"'..entity.name..'"')
		end
	end

	local function disable_resource(resource)

		local mod_name = resource.mod_name
		local resource_name = resource.name
		
		for _, resource in pairs(data.raw.resource) do
			if string.find(resource.name, resource_name, 1, true) then
				
				data.raw.resource[resource.name] = nil
				data.raw["autoplace-control"][resource.name] = nil
	
				for _, preset in pairs(data.raw["map-gen-presets"]["default"]) do
					if preset and preset.basic_settings and preset.basic_settings.autoplace_controls and preset.basic_settings.autoplace_controls[resource.name] then
						preset.basic_settings.autoplace_controls[resource.name] = nil
					end
				end

				if resource.name ~= resource_name then
					table.insert(OSM.table.disabled_prototypes.resources, {prototype_name=resource.name, mod_name=mod_name})
				end
				
				table.insert(OSM.log.disabled_prototypes, "Mod: "..'"'..mod_name..'"'..": Successfully disabled resource: "..'"'..resource_name..'"')
			end
		end
	end

	local function enable_enlisted_prototypes()

		for _, prototype in pairs(OSM.table.enabled_prototypes["technology"]) do
			if OSM.table.disabled_prototypes["technology"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["technology"][prototype.name]

				OSM.table.disabled_prototypes["technology"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, "Mod: "..'"'..prototype.mod_name..'"'..": Prevents disabling of technology: "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["recipe"]) do
			if OSM.table.disabled_prototypes["recipe"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["recipe"][prototype.name]

				OSM.table.disabled_prototypes["recipe"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, "Mod: "..'"'..prototype.mod_name..'"'..": Prevents disabling of recipe: "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["item"]) do
			if OSM.table.disabled_prototypes["item"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["item"][prototype.name]

				OSM.table.disabled_prototypes["item"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, "Mod: "..'"'..prototype.mod_name..'"'..": Prevents disabling of item: ("..prototype.type..") "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["fluid"]) do
			if OSM.table.disabled_prototypes["fluid"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["fluid"][prototype.name]

				OSM.table.disabled_prototypes["fluid"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, "Mod: "..'"'..prototype.mod_name..'"'..": Prevents disabling of fluid: "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["entity"]) do
			if OSM.table.disabled_prototypes["entity"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["entity"][prototype.name]

				OSM.table.disabled_prototypes["entity"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, "Mod: "..'"'..prototype.mod_name..'"'..": Prevents disabling of entity: ("..prototype.type..") "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["resource"]) do
			if OSM.table.disabled_prototypes["resource"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["resource"][prototype.name]

				OSM.table.disabled_prototypes["resource"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, "Mod: "..'"'..prototype.mod_name..'"'..": Prevents disabling of resource: "..'"'..prototype.name..'"')
			end
		end
	end

	local function disable_enlisted_prototypes()
		for _, prototype in pairs(OSM.table.disabled_prototypes["technology"]) do
			disable_technology(prototype)
		end
		
		for _, prototype in pairs(OSM.table.disabled_prototypes["recipe"]) do
			disable_recipe(prototype)
		end
		
		for _, prototype in pairs(OSM.table.disabled_prototypes["item"]) do
			disable_item(prototype)
		end
		
		for _, prototype in pairs(OSM.table.disabled_prototypes["fluid"]) do
			disable_fluid(prototype)
		end
		
		for _, prototype in pairs(OSM.table.disabled_prototypes["entity"]) do
			disable_entity(prototype)
		end
		
		for _, prototype in pairs(OSM.table.disabled_prototypes["resource"]) do
			disable_resource(prototype)
		end
	end
	
	-- Execute
	enable_enlisted_prototypes()
	disable_enlisted_prototypes()
end

-- Finalise prototypes
function OSM_core.finalise_prototypes()

	-- Recipe
	for _, recipe_prototype in pairs(data.raw.recipe) do
		if not recipe_prototype.OSM_removed then

			local recipe_difficulty = {recipe_prototype}

			if recipe_prototype.normal then table.insert(recipe_difficulty, recipe_prototype.normal) end
			if recipe_prototype.expensive then table.insert(recipe_difficulty, recipe_prototype.expensive) end

			-- Scan ingredients and results for disabled entries
			for i, recipe in pairs(recipe_difficulty) do
			
				-- Look for disabled single result
				if recipe.result then

					local result = OSM.lib.get_result_prototype(recipe.result, true)
					if result.type ~= "fluid" then result.type = "item" end
						
					if result and result.OSM_removed then
						
						recipe.ingredients = OSM.void_ingredients
						recipe.results = {{type=result.type, name=result.name, amount=1, probability=0}}
						recipe.result = nil
				
						recipe_prototype.OSM_result_warning = true
						recipe_prototype.OSM_soft_removed = true
						recipe_prototype.recipe.OSM_regenerate = true
		
						if not OSM.debug_mode then recipe_prototype.hidden = true end
					end
				end
			
				-- Look for disabled multiple results
				if recipe.results then
					for i, result in pairs(recipe.results) do
			
						result = OSM.lib.get_result_prototype(result.name or result[1], true)
						if result.type ~= "fluid" then result.type = "item" end
				
						if result and result.OSM_removed then
						
							recipe_prototype.OSM_result_warning = true
							recipe_prototype.recipe.OSM_regenerate = true
						
							if recipe.results[2] then
								recipe.results[i] = nil
							else
								recipe.ingredients = OSM.void_ingredients
								recipe.results[i] = {type=result.type, name=result.name, amount=1, probability=0}
								
								recipe_prototype.OSM_soft_removed = true
		
								if not OSM.debug_mode then recipe_prototype.hidden = true end
							end
						end
					end
				end
			
				-- Look for disabled ingredients
				if recipe.ingredients then
					for i, ingredient in pairs(recipe.ingredients) do

						ingredient = OSM.lib.get_ingredient_prototype(ingredient.name or ingredient[1], true)

						if ingredient and ingredient.OSM_removed then
			
							recipe_prototype.OSM_ingredient_warning = true
							recipe_prototype.recipe.OSM_regenerate = true
		
							if recipe.ingredients[2] then
								recipe.ingredients[i] = nil
							else
								recipe.ingredients = OSM.void_ingredients
								
								recipe_prototype.OSM_soft_removed = true
		
								if not OSM.debug_mode then recipe_prototype.hidden = true end
							end
						end
					end
				end
			end
		end
	end

	-- Item
	for _, sub_type in pairs(OSM.item_types) do
		for _, item in pairs(data.raw[sub_type]) do
			if item and item.place_result then
				
				local place_result = OSM.lib.get_entity_prototype(item.place_result)
				
				if place_result then
				
					if not item.OSM_removed and place_result.OSM_removed then

						item.place_result = nil 
						item.OSM_soft_removed = true
						item.recipe.OSM_regenerate = true
		
						if not OSM.debug_mode then item.flags = {"hidden"} end
					end

					-- Entity
					if item.OSM_removed and not place_result.OSM_removed then
						place_result.OSM_soft_removed = true
						place_result.recipe.OSM_regenerate = true
					end
				end
			end
		end
	end
end

-- Regenerate properties
function OSM_core.regenerate_properties()

	local function regenerate_icons()

		local function rebuild_icon(prototype)
			
			if not prototype.OSM_regenerate then return end
			if not OSM.table.prototype_index[prototype.type] then return end
			if not OSM.table.prototype_index[prototype.type][prototype.name] then return end
			if not OSM.table.prototype_index[prototype.type][prototype.name].icons then return end
			
			if not OSM.log.regenerated_icons then OSM.log.regenerated_icons = {} end
			
			local icons_path = OSM.lib.icons_path
			local ban_icon = icons_path.."ban.png"
			local ban_warn = icons_path.."soft-ban.png"
			local yellow_warn = icons_path.."yellow-warning.png"
			local orange_warn = icons_path.."orange-warning.png"
			local red_warn = icons_path.."red-warning.png"
				
			prototype.icons = OSM.table.prototype_index[prototype.type][prototype.name].icons
		
			prototype.icon = nil
	--		prototype.icon_size = nil -- used by dark_background_icon
			prototype.icon_mipmaps = nil
			prototype.scale = nil
			prototype.tint = nil
			prototype.shift = nil
	
			-- Layer ban icon
			if prototype.OSM_removed then
				table.insert(prototype.icons, {icon=ban_icon, icon_size=128, scale=0.25})
			end
			
			if prototype.OSM_soft_removed and not prototype.OSM_removed then
				table.insert(prototype.icons, {icon=ban_warn, icon_size=128, scale=0.25})
			end
			
			-- Layer result warning icon
			if prototype.OSM_result_warning and prototype.OSM_result_warning then
				table.insert(prototype.icons, {icon=yellow_warn, icon_size=128, scale=0.25})
			end
			
			-- Layer unlock warning icon
			if prototype.OSM_unlock_warning and prototype.OSM_unlock_warning then
				table.insert(prototype.icons, {icon=orange_warn, icon_size=128, scale=0.25})
			end
			
			-- Layer ingredient warning icon
			if prototype.OSM_ingredient_warning and prototype.OSM_ingredient_warning then
				table.insert(prototype.icons, {icon=red_warn, icon_size=128, scale=0.25})
			end
	
			table.insert(OSM.log.regenerated_icons, "Regenerated icon for: ("..prototype.type..") "..'"'..prototype.name..'"')
		end
	
		for _, fluid in pairs(data.raw.fluid) do
			rebuild_icon(fluid)
		end
	
		for _, item_type in pairs(OSM.item_types) do
			for _, item in pairs(data.raw[item_type]) do
				rebuild_icon(item)
			end
		end
	
		for _, entity_type in pairs(OSM.entity_types) do
			for _, entity in pairs(data.raw[entity_type]) do		
				if entity.flags then
					for _, flag in pairs(entity.flags) do
						if flag == "placeable-neutral" or "placeable-player" or "placeable-enemy" then
							rebuild_icon(entity)
							goto done
						end
					end
				end
				::done::
			end
		end
	
		for _, recipe in pairs(data.raw.recipe) do
			rebuild_icon(recipe)
		end
	end
	
	regenerate_icons()
end

--Print log
function OSM_core.print_log()

	local function print_log(log_table)
		for i, message in pairs(log_table) do
			log(message)
		end
	end
	
	-- Log regenerated icons
	print_log(OSM.log.regenerated_icons)
	
	-- Log disabled prototypes
	print_log(OSM.log.disabled_prototypes)
	
	-- Log enabled prototypes
	print_log(OSM.log.enabled_prototypes)
	
	-- log prototype changes
	print_log(OSM.log.technology)
	print_log(OSM.log.recipe)
	print_log(OSM.log.item)
	print_log(OSM.log.fluid)

	-- Log warnings and errors
	print_log(OSM.log.errors)
	
	if OSM.debug_mode then
		-- Log missing subgroups
		for i, message in pairs(OSM.log.missing_subgroup) do
			log(message)
		end
		
		-- Log missing icons
		for i, message in pairs(OSM.log.missing_icons) do
			log(message)
		end
	end
end

-- Debugging tools
function OSM_core.debug_mode()

	-- View prototype internal names
	local function view_internal_names()

		for _, sub_type in pairs(OSM.data_types) do
			for _, prototype in pairs(data.raw[sub_type]) do
				if prototype.name then
					if prototype.hidden then
						prototype.localised_name = {"", prototype.name.." [color=#8e0d79][HIDDEN][/color]"}
					else
						prototype.localised_name = {"", prototype.name}
					end
					if prototype.flags then
						for _, flag in pairs(prototype.flags) do
							if flag == "hidden" then 
								prototype.localised_name = {"", prototype.name.."[color=#8e0d79] [HIDDEN][/color]"}
							end
						end
					end
				end
			end
		end
	end

	view_internal_names()
end

return OSM_core