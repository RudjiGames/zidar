--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- A C++11 library for reading Microsoft Program DataBase PDB files
-- https://github.com/MolecularMatters/raw_pdb

local params		= { ... }
local RAWPDB_ROOT	= params[1]

local RAWPDB_FILES = {
	RAWPDB_ROOT .. "/src/Examples/ExampleMemoryMappedFile.cpp",
	RAWPDB_ROOT .. "/src/Examples/ExampleMemoryMappedFile.h",
	RAWPDB_ROOT .. "/src/Examples/ExampleMain.cpp",
	RAWPDB_ROOT .. "/src/Foundstion/PDB**.cpp",
	RAWPDB_ROOT .. "/src/Foundstion/PDB**.h",
	RAWPDB_ROOT .. "/src/PDB**.h",
	RAWPDB_ROOT .. "/src/PDB**.cpp"
}

function projectExtraConfig_raw_pdb()
	includedirs { RAWPDB_ROOT .. "/src/" }
	forcedincludes {"cstdlib"}
end

function projectAdd_raw_pdb()
	addProject_3rdParty_lib("raw_pdb", RAWPDB_FILES)
end

function projectSource_raw_pdb()
	return "https://github.com/MolecularMatters/raw_pdb"
end
