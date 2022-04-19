------------------------------
---- data-final-fixes.lua ----
------------------------------

-- Setup local host
local OSM_core = require("core.script-core")

-- Index properties
OSM_core.index_icons()

-- Assign subgroups
OSM_core.generate_subgroups()

-- Check for disabled prototypes
OSM_core.disable_prototypes()

-- Finalise properties
OSM_core.finalise_prototypes()

-- Regenerate properties
OSM_core.regenerate_icons()

-- Print log
OSM_core.print_log()

-- Debug mode
if OSM.debug_mode then OSM_core.debug_mode() end