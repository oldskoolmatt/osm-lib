------------------
---- data.lua ----
------------------

-- Host local variables
local icons_path = OSM.lib.icons_path.."core/"

-- Make item group [removed items]
local item_group =
{
	type = "item-group",
	name = "OSM-removed",
	icon = icons_path.."OSM-removed.png",
	icon_size = 128,
	icon_mipmaps = 2,
	inventory_order = "zzzz",
	order = "zzzz",
	localised_name = {"", "Disabled prototypes"}
}	data:extend({item_group})

local item_subgroup =
{
	group = "OSM-removed",
	type = "item-subgroup",
	name = "OSM-removed",
	order = "a"
}	data:extend({item_subgroup})

local recipe_category =
{
    type = "recipe-category",
    name = "OSM-removed"
}	data:extend({recipe_category})

-- Make item group [placeholder items]
local item_group =
{
	type = "item-group",
	name = "OSM-placeholder",
	icon = icons_path.."LSD-25.png",
	icon_size = 128,
	icon_mipmaps = 2,
	inventory_order = "zzzz",
	order = "zzzz",
	localised_name = {"", "Placeholders"}
}	data:extend({item_group})

local item_subgroup =
{
	group = "OSM-placeholder",
	type = "item-subgroup",
	name = "OSM-placeholder",
	order = "a"
}	data:extend({item_subgroup})

local OSM_void =
{
	type = "item",
	name = "OSM-ingredient-void",
	icon = icons_path.."albert-hofmann.png",
	icon_size = 64,
	subgroup = "OSM-placeholder",
	flags = {"hidden"},
	order = "*19/04/1943-C20H25N3O*",
	stack_size = 250
}	data:extend({OSM_void})

local OSM_item_void =
{
	type = "item",
	name = "OSM-result-void",
	icon = icons_path.."result-void.png",
	icon_size = 64,
	subgroup = "OSM-placeholder",
	flags = {"hidden"},
	order = "zzz-void",
	stack_size = 1000
}	data:extend({OSM_item_void})