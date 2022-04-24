if not OSM.utils then OSM.utils = {} end

-- Convert single image to stripe
function OSM.utils.make_stripes(count, filename)
	local stripe = {filename=filename, width_in_frames=1, height_in_frames=1}
	local stripes = {}
	for i = 1, count do
		stripes[i] = stripe
	end
	return stripes
end

-- Make empty sprite [frame count is optional]
function OSM.utils.make_empty_sprite(frame_count)
	if not frame_count then frame_count = 1 end
	return
	{
		filename = "__core__/graphics/empty.png",
		size=1,
		frame_count=frame_count
	}
end

-- Make item subgroup
function OSM.utils.make_item_subgroup(subgroup_name, subgroup_order, group_name)
	if not data.raw["item-subgroup"][subgroup_name] then
		local prototype_subgroup =
		{
			group = group_name,
			type = "item-subgroup",
			name = subgroup_name,
			order = subgroup_order,
		}	data:extend({prototype_subgroup})
	end
end

-- Make item placeholder
function OSM.utils.make_placeholder(placeholder_name)
	local OSM_placeholder =
	{
		type = "item",
		name = placeholder_name,
		icon = "__osm-lib__/graphics/albert-hofmann.png",
		icon_size = 64,
		OSM_placeholder = true,
		subgroup = "OSM-placeholder",
		flags = {"hidden"},
		order = "8==D",
		stack_size = 1
	}	data:extend({OSM_placeholder})
end
