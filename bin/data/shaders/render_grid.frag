#version 430

uniform vec4 globalColor;

in vec3 oNormal;
out vec4 color;

void main() {
	color = vec4((oNormal + 1.0) * 0.5, 1);
}
