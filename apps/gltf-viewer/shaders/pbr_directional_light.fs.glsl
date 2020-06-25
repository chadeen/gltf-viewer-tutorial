#version 330

in vec3 vViewSpacePosition;
in vec3 vViewSpaceNormal;
in vec2 vTexCoords;

uniform vec3 uLightDirection;
uniform vec3 uLightIntensity;

uniform vec4 uBaseColorFactor;
uniform float uMetallicFactor;
uniform float uRoughnessFactor;
uniform vec3 uEmissiveFactor;

uniform sampler2D uBaseColorTexture;
uniform sampler2D uMetallicRoughnessTexture;
uniform sampler2D uEmissiveTexture;

out vec3 fColor;

// Constants
const float GAMMA = 2.2;
const float INV_GAMMA = 1. / GAMMA;
const float M_PI = 3.141592653589793;
const float M_1_PI = 1.0 / M_PI;

const vec3 dielectricSpecular = vec3(0.04);
const vec3 black = vec3(0);

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

void main()
{
  	vec3 N = normalize(vViewSpaceNormal);
  	vec3 L = uLightDirection;
	vec3 V = normalize(-vViewSpacePosition);
	vec3 H = normalize(L + V);

  	vec4 baseColorFromTexture = SRGBtoLINEAR(texture(uBaseColorTexture, vTexCoords));
  	vec4 metallicRoughnessFromTexture = texture(uMetallicRoughnessTexture, vTexCoords);

  	vec4 baseColor = uBaseColorFactor * baseColorFromTexture;
  	vec3 metallic = vec3(uMetallicFactor * metallicRoughnessFromTexture.b);
  	float roughness = uRoughnessFactor * metallicRoughnessFromTexture.g;

  	// https://github.com/KhronosGroup/glTF/blob/master/specification/2.0/README.md#pbrmetallicroughnessmetallicroughnesstexture
  	// "The metallic-roughness texture.The metalness values are sampled from the B channel.The roughness values are sampled from the G channel."

  	vec3 c_diffuse = mix(baseColor.rgb * (1 - dielectricSpecular.r), black, metallic);
  	vec3 f_0 = mix(dielectricSpecular, baseColor.rgb, metallic);
  	float alpha = roughness * roughness;

  	float VdotH = clamp(dot(V, H), 0, 1);
  	float baseShlickFactor = (1 - VdotH);
	float shlickFactor = baseShlickFactor * baseShlickFactor;
	shlickFactor *= shlickFactor;
	shlickFactor *= baseShlickFactor;
	vec3 F = f_0 + (vec3(1) - f_0) * shlickFactor;

	float alpha2 = alpha * alpha;
  	float NdotL = clamp(dot(N, L), 0, 1);
	float NdotV = clamp(dot(N, V), 0, 1);
	float Vis_den = 
		NdotL * sqrt(NdotV * NdotV * (1 - alpha2) + alpha2) + 
		NdotV * sqrt(NdotL * NdotL * (1 - alpha2) + alpha2);
	float Vis = Vis_den > 0. ? 0.5 / Vis_den : 0.;
  	
	float NdotH = clamp(dot(N, H), 0, 1);
	float D_aux = NdotH * NdotH * (alpha2 - 1) + 1;
	float D = M_1_PI * alpha2 / (D_aux * D_aux);

	vec3 f_specular = F * Vis * D;

	vec3 diffuse = c_diffuse * M_1_PI;
	
	vec3 f_diffuse = (1 - F) * diffuse;

	vec3 emissive = SRGBtoLINEAR(texture2D(uEmissiveTexture, vTexCoords)).rgb * uEmissiveFactor;

	vec3 f = f_diffuse + f_specular;

  	fColor = LINEARtoSRGB(f * uLightIntensity * NdotL + emissive);
}
