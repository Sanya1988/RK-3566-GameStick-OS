/*
    crt-pi - A Raspberry Pi friendly CRT shader.

    Copyright (C) 2015-2016 davej

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.
*/

#pragma parameter CURVATURE_X "Screen curvature - horizontal" 0.10 0.0 1.0 0.01
#pragma parameter CURVATURE_Y "Screen curvature - vertical" 0.15 0.0 1.0 0.01
#pragma parameter MASK_BRIGHTNESS "Mask brightness" 0.70 0.0 1.0 0.05
#pragma parameter SCANLINE_WEIGHT "Scanline weight" 4.0 0.0 15.0 0.1
#pragma parameter SCANLINE_GAP_BRIGHTNESS "Scanline gap brightness" 0.12 0.0 1.0 0.01
#pragma parameter BLOOM_FACTOR "Bloom factor" 1.0 0.0 5.0 0.05
#pragma parameter INPUT_GAMMA "Input gamma" 2.4 0.0 5.0 0.05
#pragma parameter OUTPUT_GAMMA "Output gamma" 2.2 0.0 5.0 0.05

#define SCANLINES
#define MULTISAMPLE
#define GAMMA
#define MASK_TYPE 1

#ifdef GL_ES
#define COMPAT_PRECISION mediump
precision mediump float;
#else
#define COMPAT_PRECISION
#endif

#ifdef PARAMETER_UNIFORM
uniform COMPAT_PRECISION float CURVATURE_X;
uniform COMPAT_PRECISION float CURVATURE_Y;
uniform COMPAT_PRECISION float MASK_BRIGHTNESS;
uniform COMPAT_PRECISION float SCANLINE_WEIGHT;
uniform COMPAT_PRECISION float SCANLINE_GAP_BRIGHTNESS;
uniform COMPAT_PRECISION float BLOOM_FACTOR;
uniform COMPAT_PRECISION float INPUT_GAMMA;
uniform COMPAT_PRECISION float OUTPUT_GAMMA;
#else
#define CURVATURE_X 0.10
#define CURVATURE_Y 0.25
#define MASK_BRIGHTNESS 0.70
#define SCANLINE_WEIGHT 6.0
#define SCANLINE_GAP_BRIGHTNESS 0.12
#define BLOOM_FACTOR 1.5
#define INPUT_GAMMA 2.4
#define OUTPUT_GAMMA 2.2
#endif

uniform vec2 TextureSize;
#if defined(CURVATURE)
varying vec2 screenScale;
#endif
varying vec2 TEX0;
varying float filterWidth;

#if defined(VERTEX)
uniform mat4 MVPMatrix;
attribute vec4 VertexCoord;
attribute vec2 TexCoord;
uniform vec2 InputSize;
uniform vec2 OutputSize;

void main()
{
#if defined(CURVATURE)
	screenScale = TextureSize / InputSize;
#endif
	filterWidth = (InputSize.y / OutputSize.y) / 3.0;
	TEX0 = TexCoord * 1.0001;
	gl_Position = MVPMatrix * VertexCoord;
}
#elif defined(FRAGMENT)

uniform sampler2D Texture;

#if defined(CURVATURE)
vec2 Distort(vec2 coord)
{
	vec2 curvature_distortion = vec2(CURVATURE_X, CURVATURE_Y);
	vec2 barrelScale = 1.0 - (0.23 * curvature_distortion);
	coord *= screenScale;
	coord -= vec2(0.5);
	float rsq = coord.x * coord.x + coord.y * coord.y;
	coord += coord * (curvature_distortion * rsq);
	coord *= barrelScale;
	if (abs(coord.x) >= 0.5 || abs(coord.y) >= 0.5)
		coord = vec2(-1.0);
	else
	{
		coord += vec2(0.5);
		coord /= screenScale;
	}

	return coord;
}
#endif

float CalcScanLineWeight(float dist)
{
	return max(1.0 - dist * dist * SCANLINE_WEIGHT, SCANLINE_GAP_BRIGHTNESS);
}

float CalcScanLine(float dy)
{
	float scanLineWeight = CalcScanLineWeight(dy);
#if defined(MULTISAMPLE)
	scanLineWeight += CalcScanLineWeight(dy - filterWidth);
	scanLineWeight += CalcScanLineWeight(dy + filterWidth);
	scanLineWeight *= 0.3333333;
#endif
	return scanLineWeight;
}

void main()
{
#if defined(CURVATURE)
	vec2 texcoord = Distort(TEX0);
	if (texcoord.x < 0.0)
		gl_FragColor = vec4(0.0);
	else
#else
	vec2 texcoord = TEX0;
#endif
	{
		vec2 texcoordInPixels = texcoord * TextureSize;
		float tempY = floor(texcoordInPixels.y) + 0.5;
		float yCoord = tempY / TextureSize.y;
		float dy = texcoordInPixels.y - tempY;
		float scanLineWeight = CalcScanLine(dy);
		float signY = sign(dy);
		dy = dy * dy;
		dy = dy * dy;
		dy *= 8.0;
		dy /= TextureSize.y;
		dy *= signY;
		vec2 tc = vec2(texcoord.x, yCoord + dy);
		vec3 colour = texture2D(Texture, tc).rgb;

#if defined(GAMMA)
		colour = pow(colour, vec3(INPUT_GAMMA));
#endif

#if MASK_TYPE == 0
		gl_FragColor = vec4(colour, 1.0);
#else
#if MASK_TYPE == 1
		float whichMask = fract((gl_FragCoord.x * 1.0001) * 0.5);
		vec3 mask;
		if (whichMask < 0.5)
			mask = vec3(MASK_BRIGHTNESS, 1.0, MASK_BRIGHTNESS);
		else
			mask = vec3(1.0, MASK_BRIGHTNESS, 1.0);
#else
		float whichMask = fract((gl_FragCoord.x * 1.0001) * 0.3333333);
		vec3 mask = vec3(MASK_BRIGHTNESS, MASK_BRIGHTNESS, MASK_BRIGHTNESS);
		if (whichMask < 0.3333333)
			mask.x = 1.0;
		else if (whichMask < 0.6666666)
			mask.y = 1.0;
		else
			mask.z = 1.0;
#endif

#if defined(GAMMA)
		colour = pow(colour, vec3(1.0 / OUTPUT_GAMMA));
#endif

#if defined(SCANLINES)
		scanLineWeight *= BLOOM_FACTOR;
		colour *= scanLineWeight;
#endif
		gl_FragColor = vec4(colour * mask, 1.0);
#endif
	}
}
#endif
