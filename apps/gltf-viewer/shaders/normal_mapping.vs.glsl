#version 330

layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec3 aNormal;
layout(location = 2) in vec2 aTexCoords;
layout(location = 3) in vec3 aTangent;

out vec3 vViewSpacePosition;
out vec2 vTexCoords;
out mat3 vTBNMatrix;

uniform mat4 uModelViewProjMatrix;
uniform mat4 uModelViewMatrix;

void main() {
	vViewSpacePosition = vec3(uModelViewMatrix * vec4(aPosition, 1));
	vTexCoords = aTexCoords;
    gl_Position =  uModelViewProjMatrix * vec4(aPosition, 1);

	vec3 normal = normalize(vec3(uModelViewMatrix * vec4(aNormal, 0)));
	vec3 tangent = normalize(vec3(uModelViewMatrix * vec4(aTangent, 0)));
	tangent = normalize(tangent - dot(tangent, normal) * normal);
	vec3 bitangent = cross(normal, tangent);
	vTBNMatrix = mat3(tangent, bitangent, normal);
}
