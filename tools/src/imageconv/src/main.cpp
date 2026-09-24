/*
 * Zidar - Build system scripts.
 * Copyright (c) 2025-2026 Milos Tosic, Rudji Games. All rights reserved.
 * License: https://github.com/RudjiGames/zidar/blob/master/LICENSE
 */

// NB:	VERY FRAGILE - assumes a lot about input
//		No argument verification, destination file ext must be lower case,
//		(almost) no error checks, etc.

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_RESIZE_IMPLEMENTATION
#define STBIR_DEFAULT_FILTER_DOWNSAMPLE STBIR_FILTER_BOX
#include "stb_image_resize2.h"

#define FPNG_DISABLE_DECODE_CRC32_CHECKS
#include "fpng.h"

#include <stdio.h>
#include <string.h>

int main(int argc, char* argv[])
{
	if (argc != 5)
		return 1;

	const char* src	= argv[1];
	const char* dst	= argv[2];
	int width		= atoi(argv[3]);
	int height		= atoi(argv[4]);

	if ((width <= 0) || (height <= 0))
	{
		fprintf(stderr, "imageconv: invalid destination size %sx%s\n", argv[3], argv[4]);
		return 1;
	}

	fpng::fpng_init();

	std::vector<uint8_t> pixels;
	uint32_t srcW = 0, srcH = 0;
	uint32_t channels;
	uint32_t desired_channels = 4;
	int res = fpng::fpng_decode_file(src, pixels, srcW, srcH, channels, desired_channels);
	if (res != fpng::FPNG_DECODE_SUCCESS)
	{
		// fpng can only decode PNG files that were written by fpng
		fprintf(stderr, "imageconv: failed to decode '%s' (fpng error %d%s)\n", src, res,
			res == fpng::FPNG_DECODE_NOT_FPNG ? ", PNG was not written by fpng" : "");
		return 1;
	}

	unsigned char* dstData = new unsigned char[(size_t)width*height*4];

	if ((srcW == (uint32_t)width) && (srcH == (uint32_t)height))
	{
		memcpy(dstData, pixels.data(), width * height * 4);
	}
	else
	{
		stbir_resize(pixels.data(), srcW, srcH, srcW*4,
					 dstData, width, height, width*4,
					 STBIR_4CHANNEL, STBIR_TYPE_UINT8,
					 STBIR_EDGE_CLAMP, STBIR_FILTER_BOX);
	}

	bool ok = fpng::fpng_encode_image_to_file(dst, dstData, width, height, 4);
	delete[] dstData;

	if (!ok)
	{
		fprintf(stderr, "imageconv: failed to write '%s'\n", dst);
		return 1;
	}

	return 0;
}
