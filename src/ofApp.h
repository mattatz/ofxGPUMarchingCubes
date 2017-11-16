#pragma once

#include "ofMain.h"
#include "ofxGUI.h"

#include "MarchingCube.h";

class ofApp : public ofBaseApp {

	ofEasyCam cam;

	MarchingCube mc;

	ofxPanel gui;
	ofxFloatSlider threshold, speed, scale;
	ofxLabel resolutionDisp, fpsDisp;

	public:
		void setup();
		void update();
		void draw();

		void keyPressed(int key);

};
