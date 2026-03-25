--
-- Zidar - Build system scripts
-- Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
-- License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
--

-- A lightweight unit testing framework for C++
-- https://github.com/unittest-cpp/unittest-cpp

local params		= { ... }
local UNIT_TEST_ROOT = params[1]

local UNITTEST_FILES_WIN = {
	UNIT_TEST_ROOT .. "/UnitTest++/Win32/**.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/Win32/**.h",
}

local UNITTEST_FILES_POSIX = {
	UNIT_TEST_ROOT .. "/UnitTest++/Posix/**.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/Posix/**.h" 
}

local UNIT_TEST_FILES_COMMON = {
	UNIT_TEST_ROOT .. "/UnitTest++/AssertException.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/AssertException.h",
	UNIT_TEST_ROOT .. "/UnitTest++/CheckMacros.h",
	UNIT_TEST_ROOT .. "/UnitTest++/Checks.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/Checks.h",
	UNIT_TEST_ROOT .. "/UnitTest++/CompositeTestReporter.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/CompositeTestReporter.h",
	UNIT_TEST_ROOT .. "/UnitTest++/Config.h",
	UNIT_TEST_ROOT .. "/UnitTest++/CurrentTest.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/CurrentTest.h",
	UNIT_TEST_ROOT .. "/UnitTest++/DeferredTestReporter.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/DeferredTestReporter.h",
	UNIT_TEST_ROOT .. "/UnitTest++/DeferredTestResult.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/DeferredTestResult.h",
	UNIT_TEST_ROOT .. "/UnitTest++/ExceptionMacros.h",
	UNIT_TEST_ROOT .. "/UnitTest++/ExecuteTest.h",
	UNIT_TEST_ROOT .. "/UnitTest++/HelperMacros.h",
	UNIT_TEST_ROOT .. "/UnitTest++/MemoryOutStream.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/MemoryOutStream.h",
	UNIT_TEST_ROOT .. "/UnitTest++/ReportAssert.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/ReportAssert.h",
	UNIT_TEST_ROOT .. "/UnitTest++/ReportAssertImpl.h",
	UNIT_TEST_ROOT .. "/UnitTest++/RequiredCheckException.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/RequiredCheckException.h",
	UNIT_TEST_ROOT .. "/UnitTest++/RequiredCheckTestReporter.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/RequiredCheckTestReporter.h",
	UNIT_TEST_ROOT .. "/UnitTest++/RequireMacros.h",
	UNIT_TEST_ROOT .. "/UnitTest++/Test.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/Test.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TestDetails.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/TestDetails.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TestList.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/TestList.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TestMacros.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TestReporter.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/TestReporter.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TestReporterStdout.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/TestReporterStdout.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TestResults.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/TestResults.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TestRunner.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/TestRunner.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TestSuite.h",
	UNIT_TEST_ROOT .. "/UnitTest++/ThrowingTestReporter.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/ThrowingTestReporter.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TimeConstraint.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/TimeConstraint.h",
	UNIT_TEST_ROOT .. "/UnitTest++/TimeHelpers.h",
	UNIT_TEST_ROOT .. "/UnitTest++/UnitTest++.h",
	UNIT_TEST_ROOT .. "/UnitTest++/UnitTestPP.h",
	UNIT_TEST_ROOT .. "/UnitTest++/XmlTestReporter.cpp",
	UNIT_TEST_ROOT .. "/UnitTest++/XmlTestReporter.h"
}

local UNIT_TEST_FILES_ALL = {}
if os.is("windows") then
	UNIT_TEST_FILES_ALL = mergeTables(UNIT_TEST_FILES_COMMON, UNITTEST_FILES_WIN);
else
	UNIT_TEST_FILES_ALL = mergeTables(UNIT_TEST_FILES_COMMON, UNITTEST_FILES_POSIX);
end

function projectExtraConfig_unittest_cpp()
	includedirs { UNIT_TEST_ROOT .. "/UnitTest++" }
end

function projectAdd_unittest_cpp()
	addProject_3rdParty_lib("unittest-cpp", UNIT_TEST_FILES_ALL, true)
end

function projectSource_unittest_cpp()
	return "https://github.com/unittest-cpp/unittest-cpp"
end
