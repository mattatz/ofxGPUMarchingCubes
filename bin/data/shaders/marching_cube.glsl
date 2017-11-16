#version 430

#define THREAD 8

struct Grid {
	vec4 position;
	vec4 normal;
};

struct Voxel {
	float value;
};

uniform float uThreshold;
uniform int uWidth, uHeight, uDepth;
uniform int uBorder;

layout(std430, binding=0) buffer grids {
	Grid grid[];
};

layout(std430, binding=1) buffer voxels {
	Voxel voxel[];
};

layout(std430, binding=2) buffer CubeEdgeFlag {
	int cubeEdgeFlags[];
};

layout(std430, binding=3) buffer TriangleConnectionTable {
	int triangleConnectionTable[];
};

// edgeConnection lists the index of the endpoint vertices for each of the 12 edges of the cube
const ivec2 edgeConnection[12] =
{
	ivec2(0,1), ivec2(1,2), ivec2(2,3), ivec2(3,0), ivec2(4,5), ivec2(5,6), ivec2(6,7), ivec2(7,4), ivec2(0,4), ivec2(1,5), ivec2(2,6), ivec2(3,7)
};

// edgeDirection lists the direction vector (vertex1-vertex0) for each edge in the cube
const vec3 edgeDirection[12] =
{
	vec3(1.0f, 0.0f, 0.0f), vec3(0.0f, 1.0f, 0.0f), vec3(-1.0f, 0.0f, 0.0f), vec3(0.0f, -1.0f, 0.0f),
	vec3(1.0f, 0.0f, 0.0f), vec3(0.0f, 1.0f, 0.0f), vec3(-1.0f, 0.0f, 0.0f), vec3(0.0f, -1.0f, 0.0f),
	vec3(0.0f, 0.0f, 1.0f), vec3(0.0f, 0.0f, 1.0f), vec3(0.0f, 0.0f, 1.0f),  vec3(0.0f,  0.0f, 1.0f)
};

// vertexOffset lists the positions, relative to vertex0, of each of the 8 vertices of a cube
const vec3 vertexOffset[8] =
{
	vec3(0, 0, 0), vec3(1, 0, 0), vec3(1, 1, 0), vec3(0, 1, 0),
	vec3(0, 0, 1), vec3(1, 0, 1), vec3(1, 1, 1), vec3(0, 1, 1)
};

void FillCube(uint x, uint y, uint z, out float cube[8])
{
	int wh = uWidth * uHeight;
	cube[0] = voxel[x + y * uWidth + z * wh].value;
	cube[1] = voxel[(x + 1) + y * uWidth + z * wh].value;
	cube[2] = voxel[(x + 1) + (y + 1) * uWidth + z * wh].value;
	cube[3] = voxel[x + (y + 1) * uWidth + z * wh].value;

	cube[4] = voxel[x + y * uWidth + (z + 1) * wh].value;
	cube[5] = voxel[(x + 1) + y * uWidth + (z + 1) * wh].value;
	cube[6] = voxel[(x + 1) + (y + 1) * uWidth + (z + 1) * wh].value;
	cube[7] = voxel[x + (y + 1) * uWidth + (z + 1) * wh].value;
}

// GetOffset finds the approximate point of intersection of the surface
// between two points with the values v1 and v2
float GetOffset(float v1, float v2)
{
	float delta = v2 - v1;
	return (delta == 0.0f) ? 0.5f : (uThreshold - v1) / delta;
}

layout(local_size_x = THREAD, local_size_y = THREAD, local_size_z = THREAD) in;
void main() {
	uint ix = gl_GlobalInvocationID.x;
	uint iy = gl_GlobalInvocationID.y;
	uint iz = gl_GlobalInvocationID.z;

	if (ix >= uWidth - 1 - uBorder) return;
	if (iy >= uHeight - 1 - uBorder) return;
	if (iz >= uDepth - 1 - uBorder) return;

	uint idx = ix + iy * uWidth + iz * uWidth * uHeight;
	vec3 pos = vec3(ix, iy, iz);

	vec3 centre = vec3(uWidth, uHeight, uDepth) * 0.5;

	float cube[8];
	FillCube(ix, iy, iz, cube);
	// if(cube[0] > 0.5) grid[idx].pos.xyz = pos.xyz; return;

	//Find which vertices are inside of the surface and which are outside
	int flagIndex = 0;
	for (int i = 0; i < 8; i++) {
		if (cube[i] <= uThreshold) {
			flagIndex |= (1 << i);
		}
	}

	//Find which edges are intersected by the surface
	int edgeFlags = cubeEdgeFlags[flagIndex];

	// no connections, return
	if (edgeFlags == 0) {
		return;
	}

	//Find the point of intersection of the surface with each edge
	vec3 edgeVertex[12];
	for (int i = 0; i < 12; i++) {
		//if there is an intersection on this edge
		if ((edgeFlags & (1 << i)) != 0) {
			float offset = GetOffset(cube[edgeConnection[i].x], cube[edgeConnection[i].y]);
			edgeVertex[i] = pos + (vertexOffset[edgeConnection[i].x] + offset * edgeDirection[i]);
		}
	}

	//Save the triangles that were found. There can be up to five per cube
	for (int i = 0; i < 5; i++) {
		//If the connection table is not -1 then this a triangle.
		if (triangleConnectionTable[flagIndex * 16 + 3 * i] >= 0) {
			uint ia = idx * 15 + (3 * i + 0);
			uint ib = idx * 15 + (3 * i + 1);
			uint ic = idx * 15 + (3 * i + 2);

			vec3 position = edgeVertex[triangleConnectionTable[flagIndex * 16 + (3 * i + 0)]];
			grid[ia].position.xyz = position - centre;

			position = edgeVertex[triangleConnectionTable[flagIndex * 16 + (3 * i + 1)]];
			grid[ib].position.xyz = position - centre;

			position = edgeVertex[triangleConnectionTable[flagIndex * 16 + (3 * i + 2)]];
			grid[ic].position.xyz = position - centre;

			vec3 ab = grid[ia].position.xyz - grid[ib].position.xyz;
			vec3 ac = grid[ia].position.xyz - grid[ic].position.xyz;
			vec3 normal = normalize(cross(ab, ac));
			grid[ia].normal.xyz = grid[ib].normal.xyz = grid[ic].normal.xyz = normal;
		}
	}

}
