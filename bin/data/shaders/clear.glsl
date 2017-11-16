#version 430

#define THREAD 1024

struct Grid {
	vec4 position;
	vec4 normal;
};

uniform int uCount;

layout(std430, binding=0) buffer grids {
	Grid grid[];
};

layout(local_size_x = THREAD, local_size_y = 1, local_size_z = 1) in;
void main() {
	uint idx = gl_GlobalInvocationID.x;
	if (idx >= uCount) return;

	// init
	grid[idx].position.xyz = vec3(0, 0, 0);
	grid[idx].normal.xyz = vec3(0, 0, 0);
}
