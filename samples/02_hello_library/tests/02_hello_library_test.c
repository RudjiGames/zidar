/*
 * Zidar - Build system scripts.
 * Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
 * License: https://github.com/RudjiGames/rg_core/blob/master/LICENSE
 */

#include <rg_core_test_pch.h>

RG_UNIT_TEST_SETUP		(RG_UNIT_TEST_NO_SETUP)
RG_UNIT_TEST_TEARDOWN	(RG_UNIT_TEST_NO_TEARDOWN)

extern void rgCoreTest_atomic(void);
extern void rgCoreTest_cpu(void);
extern void rgCoreTest_cmdline(void);
extern void rgCoreTest_endianswap(void);
extern void rgCoreTest_hash(void);
extern void rgCoreTest_radixsort(void);
extern void rgCoreTest_random(void);
extern void rgCoreTest_semaphore(void);
extern void rgCoreTest_spinlock(void);
extern void rgCoreTest_string(void);
extern void rgCoreTest_mutex(void);
extern void rgCoreTest_path(void);
extern void rgCoreTest_thread(void);
extern void rgCoreTest_timer(void);
extern void rgCoreTest_uint32(void);

int main(int _argc, char* _argv[])
{
	RG_UNUSED(_argc, _argv);

	RG_UNIT_TEST_PRINT_TITLE("rg_core")

	UNITY_BEGIN();
	RUN_TEST(rgCoreTest_atomic);
	RUN_TEST(rgCoreTest_cpu);
	RUN_TEST(rgCoreTest_cmdline);
	RUN_TEST(rgCoreTest_endianswap);
	RUN_TEST(rgCoreTest_hash);
	RUN_TEST(rgCoreTest_radixsort);
	RUN_TEST(rgCoreTest_random);
	RUN_TEST(rgCoreTest_semaphore);
	RUN_TEST(rgCoreTest_spinlock);
	RUN_TEST(rgCoreTest_mutex);
	RUN_TEST(rgCoreTest_path);
	RUN_TEST(rgCoreTest_string);
	RUN_TEST(rgCoreTest_thread);
	RUN_TEST(rgCoreTest_timer);
	RUN_TEST(rgCoreTest_uint32);
	return UNITY_END();
}
