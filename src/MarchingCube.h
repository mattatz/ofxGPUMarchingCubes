#pragma once

#include "ofMain.h"

#define MARCHING_CUBE_GROUP_SIZE 8
#define CLEAR_GROUP_SIZE 1024

struct Grid {
	ofVec4f position;
	ofVec4f normal;
};

struct Voxel {
	float value;
};

class MarchingCube
{
	int count;
	int width, height, depth;

	ofShader marchingCubeShader, clearShader, noiseShader, renderShader;

	vector<Grid> grids;
	vector<Voxel> voxels;
	vector<int> indices;

	ofBufferObject voxelBuffer, gridBuffer, indexBuffer;
	ofBufferObject cubeEdgeFlagsBuffer, triangleConnectionTableBuffer;
	ofVbo vbo;

public:
	MarchingCube();
	~MarchingCube();

	void setup(const int resolution);
	void setup(const int w, const int h, const int d);
	void update(float threshold = 0.5f);
	void draw();

	void updateField(float time, float scale);
	void clear();
};

