#version 330

in vec3 vViewSpacePosition;
in vec3 vViewSpaceNormal;
in vec2 vTexCoords;

uniform vec4 uBaseColorFactor;
uniform float uMetallicFactor;
uniform float uRoughnessFactor;

uniform sampler2D uBaseColorTexture;
uniform sampler2D uMetallicRoughnessTexture;

layout(location = 0) out vec3 gPosition;
layout(location = 1) out vec3 gNormal;
layout(location = 2) out vec3 gAlbedo;
layout(location = 3) out vec4 gSpecular;

// Constants
const float GAMMA = 2.2;
const float INV_GAMMA = 1. / GAMMA;

// We need some simple tone mapping functions
// Basic gamma = 2.2 implementation
// Stolen here: https://github.com/KhronosGroup/glTF-Sample-Viewer/blob/master/src/shaders/tonemapping.glsl

// linear to sRGB approximation
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec3 LINEARtoSRGB(vec3 color)
{
  return pow(color, vec3(INV_GAMMA));
}

// sRGB to linear approximation
// see http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html
vec4 SRGBtoLINEAR(vec4 srgbIn)
{
  return vec4(pow(srgbIn.xyz, vec3(GAMMA)), srgbIn.w);
}

void main() {
	gPosition = vViewSpacePosition;
	gNormal = normalize(vViewSpaceNormal);
	gAlbedo = LINEARtoSRGB(vec3(uBaseColorFactor * SRGBtoLINEAR(texture(uBaseColorTexture, vTexCoords))));

	vec4 metallicRoughnessFromTexture = texture(uMetallicRoughnessTexture, vTexCoords);
	vec3 metallic = vec3(uMetallicFactor * metallicRoughnessFromTexture.b);
  	float roughness = uRoughnessFactor * metallicRoughnessFromTexture.g;

  	gSpecular = vec4(metallic, roughness);
}