--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- A multi core friendly rigid body physics and collision detection library
-- https://github.com/jrouwe/JoltPhysics

local params		= { ... }
local JOLT_ROOT		= params[1]

local JOLT_FILES		= {
	JOLT_ROOT .. "/Jolt/AABBTree/**.cpp",
	JOLT_ROOT .. "/Jolt/Core/**.cpp",
	JOLT_ROOT .. "/Jolt/Geometry/**.cpp",
	JOLT_ROOT .. "/Jolt/Math/**.cpp",
	JOLT_ROOT .. "/Jolt/ObjectStream/**.cpp",
	JOLT_ROOT .. "/Jolt/Renderer/**.cpp",
	JOLT_ROOT .. "/Jolt/Skeleton/**.cpp",
	JOLT_ROOT .. "/Jolt/TriangleGrouper/**.cpp",
	JOLT_ROOT .. "/Jolt/TriangleSplitter/**.cpp",
	JOLT_ROOT .. "/Jolt/RegisterTypes.cpp",
	JOLT_ROOT .. "/Jolt/**.h"
}

local JOLT_FILES_SPLIT	= {
	JOLT_ROOT .. "/Jolt/Physics/**.cpp"
}

function projectExtraConfig_jolt_split()
	projectExtraConfig_jolt()
end

function projectDependencies_jolt()
	-- cmd line lenth limitation, split project into 2 libs
	if os.is("windows") and not actionUsesMSVC() then
		return  { "jolt_split" }
	end
end

function projectExtraConfig_jolt()
	includedirs { JOLT_ROOT }
	defines {
		"JPH_CROSS_PLATFORM_DETERMINISTIC"
	}
end

function projectAdd_jolt_split()
	addProject_3rdParty_lib("jolt_split", JOLT_FILES_SPLIT)
end

function projectAdd_jolt()
	-- cmd line lenth limitation, split project into 2 libs
	if os.is("windows") and not actionUsesMSVC() then
		addProject_3rdParty_lib("jolt", JOLT_FILES)
	else
		local FILES = mergeTables(JOLT_FILES, JOLT_FILES_SPLIT)
		addProject_3rdParty_lib("jolt", FILES)
	end
end

function projectSource_jolt()
	return "https://github.com/jrouwe/JoltPhysics"
end
