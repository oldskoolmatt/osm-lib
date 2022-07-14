local OSM_core = {}

-- Index prototype base properties
function OSM_core.index_properties()
	
	-- Index icons
	local function index_icons()
		
		if not OSM.log.missing_icons then OSM.log.missing_icons = {} end
	
		local function index_icon(prototype, external_prototype)
		
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
			table.insert(OSM.log.missing_icons, "Could not index icon for: ("..prototype.type..") "..'"'..prototype.name..'"')
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
							goto done
						end
					end
				end
				::done::
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
	
	-- Index subgroups
	local function index_subgroups()
	
		if not OSM.log.missing_subgroup then OSM.log.missing_subgroup = {} end
		
		local function index_subgroup(prototype, external_prototype)
				
			local subgroup = prototype.subgroup
			local order = prototype.order
	
			if not OSM.table.prototype_index[prototype.type] then OSM.table.prototype_index[prototype.type] = {} end
			if not OSM.table.prototype_index[prototype.type][prototype.name] then OSM.table.prototype_index[prototype.type][prototype.name] = {} end
			
			if external_prototype then
				if external_prototype.subgroup then subgroup = external_prototype.subgroup end
				if external_prototype.order then order = external_prototype.order end
			end
			
			if subgroup then OSM.table.prototype_index[prototype.type][prototype.name].subgroup = subgroup end
			if order then OSM.table.prototype_index[prototype.type][prototype.name].order = order end
	
			if not OSM.table.prototype_index[prototype.type][prototype.name].subgroup then
				table.insert(OSM.log.missing_subgroup, "Could not index subgroup for: ("..prototype.type..") "..'"'..prototype.name..'"')
			end
		end
		
		-- Scan items and fluids for missing subgroups
		for _, item in pairs(OSM.item_types) do
			if data.raw[item][prototype_name] or data.raw.fluid[prototype_name] then
	
				local prototype = data.raw[item][prototype_name] or data.raw.fluid[prototype_name]
				local prototype_type = "Item: ("..prototype.type..") "
	
				if prototype.type == "fluid" then prototype_type = "Fluid: "end
	
				if not prototype.subgroup then table.insert(OSM.log.missing_subgroup, prototype_type..'"'..prototype.name..'"'.." does not have a subgroup") end
			end
		end	
	
		-- Entities
		for _, item_type in pairs(OSM.item_types) do -- from item place_result
			for _, item in pairs(data.raw[item_type]) do
				if item.place_result and item.subgroup then
					
					local entity = OSM.lib.get_entity_prototype(item.place_result, true)				
	
					if entity and not entity.subgroup and not entity.placeable_by then
					index_subgroup(entity, item)
				end
				end
			end
		end
	
		for _, entity_type in pairs(OSM.entity_types) do -- from entity placeable_by
			for _, entity in pairs(data.raw[entity_type]) do		
				if entity.placeable_by and not entity.subgroup then
				
					local item = OSM.lib.get_item_prototype(entity.placeable_by.item, true)
					
					if item and item.place_result then
						index_subgroup(entity, item)
					end
				end
			end
		end
	
		-- Recipes
		for _, recipe in pairs(data.raw.recipe) do
			if not recipe.subgroup then
	
				local result = OSM.lib.get_main_result_prototype(recipe.name, true)
	
				-- Assign subgroup to recipe
				if result and result.subgroup then
					index_subgroup(recipe, result)
				end
			end
		end
	end

	-- Index technology unlocks
	local function index_unlocks()
		for _, technology in pairs(data.raw.technology) do
			if technology.effects then

				if not OSM.table.prototype_index[technology.type] then OSM.table.prototype_index[technology.type] = {} end
				if not OSM.table.prototype_index[technology.type][technology.name] then OSM.table.prototype_index[technology.type][technology.name] = {} end
				
				OSM.table.prototype_index[technology.type][technology.name].effects = technology.effects
			end
		end
	end

	index_icons()
	index_subgroups()
	index_unlocks()
	
	if OSM.debug_mode then
		
		-- Appoint temporary prototype sub_type
		local function assign_OSM_subtypes()
		
			for _, fluid in pairs(data.raw.fluid) do
				fluid.OSM_type = "fluid"
			end
			
			for _, item_type in pairs(OSM.item_types) do
				for _, item in pairs(data.raw[item_type]) do
					item.OSM_type = "item"
				end
			end
			
			for _, entity_type in pairs(OSM.entity_types) do
				for _, entity in pairs(data.raw[entity_type]) do		
					entity.OSM_type = "entity"
				end
			end
		
			for _, recipe in pairs(data.raw.recipe) do
				recipe.OSM_type = "recipe"
			end
		end
	
		assign_OSM_subtypes()
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
		technology.order = "OSM-removed"
		
		if not OSM.debug_mode then technology.hidden = true end
		if OSM.debug_mode then technology.visible_when_disabled = true end

		-- Removes technology from other techs prerequisites
		for _, tech in pairs(data.raw.technology) do
			if tech.prerequisites then
				for i, prerequisite in pairs (tech.prerequisites) do
					if prerequisite == technology.name then
						technology.prerequisites[i] = nil
						table.insert(OSM.log.technology, '"OSM-Lib Core Script"'..": Disabled: "..'"'..technology.name..'"'.." and removed it from: "..'"'..tech.name..'"'.." prerequisites because it was disabled by: "..'"'..mod_name..'"')
					end
				end
			end
		end
		table.insert(OSM.log.disabled_prototypes, '"'..mod_name..'"'..": Successfully disabled technology: "..'"'..technology.name..'"')
	end

	local function disable_recipe(recipe)
		if data.raw.recipe[recipe.name] then
	
			local mod_name = recipe.mod_name
			local recipe = data.raw.recipe[recipe.name]

			recipe.subgroup = "OSM-removed"
			recipe.category = "OSM-crafting-void"
			recipe.OSM_removed = true
			recipe.OSM_regenerate = true
	
			recipe.enabled = false

			recipe.localised_name = {"", recipe.name}
			recipe.localised_description = {"", "Disabled by: "..mod_name}
			
			if not OSM.debug_mode then recipe.hidden = true end

			if recipe.normal then
				recipe.normal.ingredients = {}
				recipe.normal.results = {}
				recipe.normal.main_product = ""
				recipe.normal.result = nil
			end

			if recipe.expensive then
				recipe.expensive.ingredients = {}
				recipe.expensive.results = {}
				recipe.expensive.main_product = ""
				recipe.expensive.result = nil
			end
			
			if recipe.ingredients then
				recipe.ingredients = {}
				recipe.results = {}
				recipe.main_product = ""
				recipe.result = nil
			end

			-- Removes recipe from technology unlock
			for _, technology in pairs(data.raw.technology) do
				if technology.effects then
					for i, effect in pairs(technology.effects) do
						if effect.type == "unlock-recipe" and effect.recipe == recipe.name then
							technology.effects[i] = nil
							table.insert(OSM.log.technology, '"OSM-Lib Core Script"'..": Successfully removed unlock from technologies for: "..'"'..recipe.name..'"'.." because it was disabled by: "..'"'..mod_name..'"')
						end
					end
				end
			end

			-- Remove recipe from module limitation
			for _, module in pairs(data.raw.module) do
				if module.limitation then
					for i, limitation in pairs(module.limitation) do
						if limitation == recipe.name then
							module.limitation[i] = nil
							table.insert(OSM.log.technology, '"OSM-Lib Core Script"'..": Successfully removed: "..'"'..recipe.name..'"'.." from module limitation list because it was disabled by: "..'"'..mod_name..'"')
						end
					end
				end
			end
			
			table.insert(OSM.log.disabled_prototypes, '"'..mod_name..'"'..": Successfully disabled recipe: "..'"'..recipe.name..'"')
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
			
			table.insert(OSM.log.disabled_prototypes, '"'..mod_name..'"'..": Successfully disabled item: ("..item.type..") "..'"'..item.name..'"')
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

			table.insert(OSM.log.disabled_prototypes, '"'..mod_name..'"'..": Successfully disabled fluid: "..'"'..fluid.name..'"')
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
			
			table.insert(OSM.log.disabled_prototypes, '"'..mod_name..'"'..": Successfully disabled entity: ("..entity.type..") "..'"'..entity.name..'"')
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
				
				table.insert(OSM.log.disabled_prototypes, '"'..mod_name..'"'..": Successfully disabled resource: "..'"'..resource_name..'"')
			end
		end
	end

	-- Function recall
	local function enable_enlisted_prototypes()

		for _, prototype in pairs(OSM.table.enabled_prototypes["technology"]) do
			if OSM.table.disabled_prototypes["technology"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["technology"][prototype.name]

				OSM.table.disabled_prototypes["technology"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, '"'..prototype.mod_name..'"'..": Prevents disabling of technology: "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["recipe"]) do
			if OSM.table.disabled_prototypes["recipe"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["recipe"][prototype.name]

				OSM.table.disabled_prototypes["recipe"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, '"'..prototype.mod_name..'"'..": Prevents disabling of recipe: "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["item"]) do
			if OSM.table.disabled_prototypes["item"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["item"][prototype.name]

				OSM.table.disabled_prototypes["item"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, '"'..prototype.mod_name..'"'..": Prevents disabling of item: ("..prototype.type..") "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["fluid"]) do
			if OSM.table.disabled_prototypes["fluid"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["fluid"][prototype.name]

				OSM.table.disabled_prototypes["fluid"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, '"'..prototype.mod_name..'"'..": Prevents disabling of fluid: "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["entity"]) do
			if OSM.table.disabled_prototypes["entity"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["entity"][prototype.name]

				OSM.table.disabled_prototypes["entity"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, '"'..prototype.mod_name..'"'..": Prevents disabling of entity: ("..prototype.type..") "..'"'..prototype.name..'"')
			end
		end
		
		for _, prototype in pairs(OSM.table.enabled_prototypes["resource"]) do
			if OSM.table.disabled_prototypes["resource"][prototype.name] then

				local prototype = OSM.table.disabled_prototypes["resource"][prototype.name]

				OSM.table.disabled_prototypes["resource"][prototype.name] = nil
				table.insert(OSM.log.enabled_prototypes, '"'..prototype.mod_name..'"'..": Prevents disabling of resource: "..'"'..prototype.name..'"')
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
			
			-- Avoid "other" and "ee-tools" subgroups [ee-tools from Raiguard editor extension tools]
			local recipe_prototype_result = OSM.lib.get_main_result_prototype(recipe_prototype.name, true)
			if recipe_prototype.subgroup == "other" or recipe_prototype.subgroup == "ee-tools" then goto skip end
			if recipe_prototype_result and (recipe_prototype_result.subgroup == "other" or recipe_prototype_result.subgroup == "ee-tools") then goto skip end

			-- Scan ingredients and results for disabled entries
			for i, recipe in pairs(recipe_difficulty) do
			
				-- Look for disabled single result
				if recipe.result then

					local result = OSM.lib.get_result_prototype(recipe.result, true)
						
					if result and result.OSM_removed then
						recipe.ingredients = OSM.void_recipe
						recipe_prototype.category = "OSM-crafting-void"
						recipe_prototype.enabled = true
				
						recipe_prototype.OSM_result_warning = true
						recipe_prototype.OSM_soft_removed = true
						recipe_prototype.OSM_regenerate = true
		
						if not OSM.debug_mode then recipe_prototype.hidden = true end
					end
				end
			
				-- Look for disabled multiple results
				if recipe.results then
					for i, result in pairs(recipe.results) do
			
						result = OSM.lib.get_result_prototype(result.name or result[1], true)
				
						if result and result.OSM_removed then
							recipe.ingredients = OSM.void_recipe
							recipe_prototype.category = "OSM-crafting-void"
							recipe_prototype.enabled = true
						
							recipe_prototype.OSM_result_warning = true
							recipe_prototype.OSM_regenerate = true
						end
					end
				end
			
				-- Look for disabled ingredients
				if recipe.ingredients then
					for i, ingredient in pairs(recipe.ingredients) do

						ingredient = OSM.lib.get_ingredient_prototype(ingredient.name or ingredient[1], true)

						if ingredient and ingredient.OSM_removed then
							recipe.ingredients = OSM.void_recipe
							recipe_prototype.category = "OSM-crafting-void"
							recipe_prototype.enabled = true
			
							recipe_prototype.OSM_ingredient_warning = true
							recipe_prototype.OSM_regenerate = true
						end
					end
				end
			end
			
			-- Check if recipe is soft locked
			if not recipe_prototype.enabled then
				for index_name, technology_index in pairs(OSM.table.prototype_index.technology) do
					if technology_index.effects and data.raw.technology[index_name].OSM_removed then
						for _, effect_index in pairs(technology_index.effects) do
							if effect_index.recipe == recipe_prototype.name then
								
								local soft_lock = true
								
								for _, technology in pairs(data.raw.technology) do
									if technology.effects then
										for _, effect in pairs(technology.effects) do
											if effect.recipe == recipe_prototype.name then soft_lock = false end
										end
									end
								end
								
								if soft_lock then
									recipe_prototype.category = "OSM-crafting-void"
									recipe_prototype.enabled = true
								
									recipe_prototype.OSM_unlock_warning = true
									recipe_prototype.OSM_regenerate = true
								end
							end
						end
					end
				end
			end
		::skip::
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
						item.OSM_regenerate = true
		
						if not OSM.debug_mode then item.flags = {"hidden"} end
					end

					-- Entity
					if item.OSM_removed and not place_result.OSM_removed then
						place_result.OSM_soft_removed = true
						place_result.OSM_regenerate = true
					end
				end
			end
		end
	end
end

-- Regenerate properties
function OSM_core.regenerate_properties()

	if not OSM.log.regenerated_subgroups then OSM.log.regenerated_subgroups = {} end
	if not OSM.log.regenerated_icons then OSM.log.regenerated_icons = {} end

	local function regenerate_properties(prototype)
		
		if not prototype.OSM_regenerate then return end
		if not OSM.table.prototype_index[prototype.type] then return end
		if not OSM.table.prototype_index[prototype.type][prototype.name] then return end

		-- Regenerate icons
		if OSM.table.prototype_index[prototype.type][prototype.name].icons then
		
			local icons_path = OSM.lib.icons_path
			local ban_icon = icons_path.."ban.png"
			local yellow_warn = icons_path.."yellow-warning.png"
			local orange_warn = icons_path.."orange-warning.png"
			local red_warn = icons_path.."red-warning.png"
				
			prototype.icons = OSM.table.prototype_index[prototype.type][prototype.name].icons
		
			prototype.icon = nil
--			prototype.icon_size = nil		-- used by dark_background_icon
			prototype.icon_mipmaps = nil
			prototype.scale = nil
			prototype.tint = nil
			prototype.shift = nil
	
			-- Layer ban icon
			if prototype.OSM_removed then
				table.insert(prototype.icons, {icon=ban_icon, icon_size=128, scale=0.25})
			end
			
			-- Layer result warning icon
			if prototype.OSM_result_warning and not prototype.OSM_removed then
				table.insert(prototype.icons, {icon=yellow_warn, icon_size=128, scale=0.25})
			end
			
			-- Layer unlock warning icon
			if prototype.OSM_unlock_warning and not prototype.OSM_removed then
				table.insert(prototype.icons, {icon=orange_warn, icon_size=128, scale=0.25})
			end
			
			-- Layer ingredient warning icon
			if prototype.OSM_ingredient_warning and not prototype.OSM_removed then
				table.insert(prototype.icons, {icon=red_warn, icon_size=128, scale=0.25})
			end
	
			-- Log icon actions
			table.insert(OSM.log.regenerated_icons, "Regenerated icon for: ("..prototype.type..") "..'"'..prototype.name..'"')
		end

		-- Regenerate subgroups
		if OSM.table.prototype_index[prototype.type][prototype.name].subgroup and not prototype.OSM_removed then
		
			prototype.subgroup = OSM.table.prototype_index[prototype.type][prototype.name].subgroup
			
			if OSM.table.prototype_index[prototype.type][prototype.name].order then
				prototype.order = OSM.table.prototype_index[prototype.type][prototype.name].order
			end
			
			-- Log subgroup actions
			table.insert(OSM.log.regenerated_subgroups, "Regenerated subgroup for: ("..prototype.type..") "..'"'..prototype.name..'"')
		end

		-- Log warnings and errors
		if prototype.OSM_soft_removed and not prototype.OSM_removed then
			if prototype.OSM_type == "fluid" then
				table.insert(OSM.log.warnings, "WARNING!!! Fluid: "..'"'..prototype.name..'"'.." had its "..'"place_result"'.." disabled by another mod")
			
			elseif prototype.OSM_type == "item" then
				table.insert(OSM.log.warnings, "WARNING!!! Item: ("..prototype.type..") "..'"'..prototype.name..'"'.." had its "..'"place_result"'.." disabled by another mod")
				
			elseif prototype.OSM_type == "entity" then
				table.insert(OSM.log.warnings, "WARNING!!! Entity: ("..prototype.type..") "..'"'..prototype.name..'"'.." had its "..'"placeable_by"'.." disabled by another mod")

			elseif prototype.OSM_type == "recipe" then
				table.insert(OSM.log.warnings, "WARNING!!! Recipe: "..'"'..prototype.name..'"'.." had ALL of its "..'"ingredients"'.." and/or "..'"results"'.." disabled by another mod")
			end
		end
		
		if prototype.OSM_ingredient_warning and not prototype.OSM_soft_removed then
			table.insert(OSM.log.warnings, "WARNING!!! Recipe: "..'"'..prototype.name..'"'.." had one or more of its "..'"ingredients"'.." disabled by another mod")
		end
		
		if prototype.OSM_result_warning and not prototype.OSM_soft_removed then
			table.insert(OSM.log.warnings, "WARNING!!! Recipe: "..'"'..prototype.name..'"'.." had one or more of its "..'"results"'.." disabled by another mod")
		end
		
		if prototype.OSM_unlock_warning then
			table.insert(OSM.log.warnings, "WARNING!!! Recipe: "..'"'..prototype.name..'"'.." had the only technology unlocking it disabled by another mod")
		end

		-- Add tooltips to faulty prototypes
		if prototype.OSM_soft_removed or prototype.OSM_result_warning or prototype.OSM_unlock_warning or prototype.OSM_ingredient_warning then
			prototype.localised_description = {"", "[font=default-bold][color=#ffe6c0]Prototype type:[/color][/font] "..prototype.type}

			if prototype.OSM_ingredient_warning then
				table.insert(prototype.localised_description, {"string.red-warning"})
			end
			if prototype.OSM_result_warning then
				table.insert(prototype.localised_description, {"string.yellow-warning"})
			end
			if prototype.OSM_unlock_warning then
				table.insert(prototype.localised_description, {"string.orange-warning"})
			end
		end

		-- Do the dishes...
		if not OSM.debug_mode then
			prototype.OSM_type = nil
			prototype.OSM_removed = nil
			prototype.OSM_soft_removed = nil
			prototype.OSM_result_warning = nil
			prototype.OSM_unlock_warning = nil
			prototype.OSM_ingredient_warning = nil
			prototype.OSM_regenerate = nil
		end
	end

	-- Scan prototypes
	for _, sub_type in pairs(OSM.data_types) do
		for _, prototype in pairs(data.raw[sub_type]) do
			regenerate_properties(prototype)
		end
	end
end

-- Debugging tools
function OSM_core.debug_mode()

	-- View internal names
	local function view_internal_names(prototype)
		if prototype.name and not string.find(prototype.name, "OSM-hoffman-void", 1, true) then 
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
	
	-- Regroup and log faulty prototypes
	local function view_flawed_prototypes(prototype)
		if prototype.OSM_type then
			if prototype.OSM_soft_removed or prototype.OSM_result_warning or prototype.OSM_unlock_warning or prototype.OSM_ingredient_warning then
				prototype.subgroup = "OSM-warning"
				prototype.order = prototype.name
				if prototype.hidden then prototype.hidden = false end
				if prototype.flags then
					for i, flag in pairs(prototype.flags) do
						if flag == "hidden" then 
							prototype.flags[i] = nil
						end
					end
				end
			end
		end
	end

	-- Execute
	for _, sub_type in pairs(OSM.data_types) do
		for _, prototype in pairs(data.raw[sub_type]) do
			view_internal_names(prototype)
			view_flawed_prototypes(prototype)
		end
	end
end

--Print log
function OSM_core.print_log()

	local function print_log(log_table)
		for i, message in pairs(log_table) do
			log(message)
		end
	end

	if OSM.debug_mode then
		log("------------------------------------------------------------------------------------------------------------")
		log("----   DEBUG MODE IS ON   ----   DEBUG MODE IS ON   ----   DEBUG MODE IS ON   ----   DEBUG MODE IS ON   ----")
		log("------------------------------------------------------------------------------------------------------------")
	end

	-- Log warnings and errors
	print_log(OSM.log.errors)
	print_log(OSM.log.warnings)
	
	-- Log disabled prototypes
	print_log(OSM.log.disabled_prototypes)
	
	-- Log enabled prototypes
	print_log(OSM.log.enabled_prototypes)
	
	-- log prototype changes
	print_log(OSM.log.technology)
	print_log(OSM.log.recipe)
	print_log(OSM.log.item)
	print_log(OSM.log.fluid)
	
	if OSM.debug_mode then
	
		-- Log regenerated properties
		print_log(OSM.log.regenerated_subgroups)
		print_log(OSM.log.regenerated_icons)

		-- Log missing subgroups
		print_log(OSM.log.missing_subgroup)
		
		-- Log missing icons
		print_log(OSM.log.missing_icons)
	end
end

return OSM_core