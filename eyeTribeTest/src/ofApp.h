#pragma once

#include "ofMain.h"

#ifdef __OBJC__
@class UVCCameraControl;
#endif

class ofApp : public ofBaseApp{
	
	public:
		
		void setup();
		void update();
		void draw();
		
		void keyPressed(int key);
		void keyReleased(int key);
		void mouseMoved(int x, int y );
		void mouseDragged(int x, int y, int button);
		void mousePressed(int x, int y, int button);
		void mouseReleased(int x, int y, int button);
		void mouseEntered(int x, int y);
		void mouseExited(int x, int y);
		void windowResized(int w, int h);
		void dragEvent(ofDragInfo dragInfo);
		void gotMessage(ofMessage msg);		
		
		ofVideoGrabber 			vidGrabber;
		ofPtr<ofQTKitGrabber>	vidRecorder;
  
  int curGain;

#ifdef __OBJC__
  UVCCameraControl* cameraControl;
#else
  void* cameraControl;
#endif
  
    	ofVideoPlayer recordedVideoPlayback;
    
		void videoSaved(ofVideoSavedEventArgs& e);
	
    	vector<string> videoDevices;
	    vector<string> audioDevices;
    
        bool bLaunchInQuicktime;
};
