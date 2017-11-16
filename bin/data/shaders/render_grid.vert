#version 430

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat4 projectionMatrix;

layout(location = 0) in vec4 position;
layout(location = 1) in vec4 normal;

out vec3 oNormal;

void main() {
	vec4 mPosition = modelViewMatrix * vec4(position.xyz, 1.0);
	gl_Position = projectionMatrix * mPosition;

	oNormal = normal.xyz;
}
