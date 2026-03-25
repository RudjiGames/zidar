/*
 * Zidar - Build system scripts.
 * Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
 * License: http://www.opensource.org/licenses/BSD-2-Clause
 */

#include <stdio.h>
#include <02_hello_library/include/hello_library.h>

int main(int argc, char* argv[])
{
	(void)argc;
	(void)argv;

	printf("2 + 3 = %d \n", helloLibraryAdd(2, 3));
	
	return 0;
}
