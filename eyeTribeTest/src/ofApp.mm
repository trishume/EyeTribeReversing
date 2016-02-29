#include "ofApp.h"
#import "UVCCameraControl.h"

//--------------------------------------------------------------
void ofApp::setup(){

    // This example shows how to use the OS X specific
    // video grabber to record synced video and audio to disk.

    ofEnableAlphaBlending();
    ofEnableSmoothing();

    ofSetFrameRate(30);
    ofSetVerticalSync(true);

    ofSetLogLevel(OF_LOG_VERBOSE);

    // 1. Create a new recorder object.  ofPtr will manage this
    // pointer for us, so no need to delete later.
    vidRecorder = ofPtr<ofQTKitGrabber>( new ofQTKitGrabber() );

    // 2. Set our video grabber to use this source.
    vidGrabber.setGrabber(vidRecorder);

    // 3. Make lists of our audio and video devices.
    videoDevices = vidRecorder->listVideoDevices();
    audioDevices = vidRecorder->listAudioDevices();

    // 3a. Optionally add audio to the recording stream.
    // vidRecorder->setAudioDeviceID(2);
    // vidRecorder->setUseAudio(true);

	// 4. Register for events so we'll know when videos finish saving.
	ofAddListener(vidRecorder->videoSavedEvent, this, &ofApp::videoSaved);

    // 4a.  If you would like to list available video codecs on your system,
    // uncomment the following code.
    // vector<string> videoCodecs = vidRecorder->listVideoCodecs();
    // for(size_t i = 0; i < videoCodecs.size(); i++){
    //     ofLogVerbose("Available Video Codecs") << videoCodecs[i];
    // }

	// 4b. You can set a custom / non-default codec in the following ways if desired.
    // vidRecorder->setVideoCodec("QTCompressionOptionsJPEGVideo");
    // vidRecorder->setVideoCodec(videoCodecs[2]);

    // 5. Initialize the grabber.
    vidGrabber.setup(1280, 720);

    // If desired, you can disable the preview video.  This can
    // help help speed up recording and remove recording glitches.
    // vidRecorder->setupWithoutPreview();

    // 6. Initialize recording on the grabber.  Call initRecording()
    // once after you've initialized the grabber.
    vidRecorder->initRecording();

    // 7. If you'd like to launch the newly created video in Quicktime
    // you can enable it here.
    bLaunchInQuicktime = true;

    // uvcControl.useCamera(10667, 251, 0);
    cameraControl = [[UVCCameraControl alloc] initWithVendorID:10667 productID:251 interfaceNum:0];
  curGain = 0;
  curLights = 0;
}


//--------------------------------------------------------------
void ofApp::update(){

	ofBackground(60, 60, 60);

	vidGrabber.update();

    if(recordedVideoPlayback.isLoaded()){
        recordedVideoPlayback.update();
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofRectangle previewWindow(20, 20, 1280, 720);
    ofRectangle playbackWindow(20+1280, 20, 640, 480);

    // draw the background boxes
    ofPushStyle();
    ofSetColor(0);
    ofFill();
    ofDrawRectangle(previewWindow);
    ofDrawRectangle(playbackWindow);
    ofPopStyle();

    // draw the preview if available
	if(vidRecorder->hasPreview()){
        ofPushStyle();
        ofFill();
        ofSetColor(255);
        // fit it into the preview window, but use the correct aspect ratio
        ofRectangle videoGrabberRect(0,0,vidGrabber.getWidth(),vidGrabber.getHeight());
        videoGrabberRect.scaleTo(previewWindow);
        vidGrabber.draw(videoGrabberRect);
        ofPopStyle();
    } else{
		ofPushStyle();
		// x out to show there is no video preview
        ofSetColor(255);
		ofSetLineWidth(3);
		ofDrawLine(20, 20, 640+20, 480+20);
		ofDrawLine(20+640, 20, 20, 480+20);
		ofPopStyle();
	}

    // draw the playback video
    if(recordedVideoPlayback.isLoaded()){
        ofPushStyle();
        ofFill();
        ofSetColor(255);
        // fit it into the preview window, but use the correct aspect ratio
        ofRectangle recordedRect(ofRectangle(0,0,recordedVideoPlayback.getWidth(),recordedVideoPlayback.getHeight()));
        recordedRect.scaleTo(playbackWindow);
        recordedVideoPlayback.draw(recordedRect);
        ofPopStyle();
    }

    ofPushStyle();
    ofNoFill();
    ofSetLineWidth(3);
    if(vidRecorder->isRecording()){
        //make a nice flashy red record color
        int flashRed = powf(1 - (sin(ofGetElapsedTimef()*10)*.5+.5),2)*255;
		ofSetColor(255, 255-flashRed, 255-flashRed);
    }
    else{
    	ofSetColor(255,80);
    }
    ofDrawRectangle(previewWindow);
    ofPopStyle();


    //draw instructions
    ofPushStyle();
    ofSetColor(255);
    ofDrawBitmapString("' ' space bar to toggle recording", 680, 540);
    ofDrawBitmapString("'v' switches video device", 680, 560);
    ofDrawBitmapString("'a' switches audio device", 680, 580);

    //draw video device selection
    ofDrawBitmapString("VIDEO DEVICE", 20, 540);
    for(int i = 0; i < videoDevices.size(); i++){
        if(i == vidRecorder->getVideoDeviceID()){
			ofSetColor(255, 100, 100);
        }
        else{
            ofSetColor(255);
        }
        ofDrawBitmapString(videoDevices[i], 20, 560+i*20);
    }

    //draw audio device;
    int startY = 580+20*videoDevices.size();
    ofDrawBitmapString("AUDIO DEVICE", 20, startY);
    startY += 20;
    for(int i = 0; i < audioDevices.size(); i++){
        if(i == vidRecorder->getAudioDeviceID()){
			ofSetColor(255, 100, 100);
        }
        else{
            ofSetColor(255);
        }
        ofDrawBitmapString(audioDevices[i], 20, startY+i*20);
    }
    ofPopStyle();
}


//--------------------------------------------------------------
void ofApp::keyPressed(int key){

	if(key == ' '){

        //if it is recording, stop
        if(vidRecorder->isRecording()){
            vidRecorder->stopRecording();
        }
        else {
            // otherwise start a new recording.
            // before starting, make sure that the video file
            // is already in use by us (i.e. being played), or else
            // we won't be able to record over it.
            if(recordedVideoPlayback.isLoaded()){
                recordedVideoPlayback.close();
            }
	        vidRecorder->startRecording("MyMovieFile.mov");
        }
    }
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){
	if(key == 'v'){
		vidRecorder->setVideoDeviceID( (vidRecorder->getVideoDeviceID()+1) % videoDevices.size() );
    }
	if(key == 'a'){
        vidRecorder->setAudioDeviceID( (vidRecorder->getAudioDeviceID()+1) % audioDevices.size() );
    }

  uvc_control_info_t *control = &([cameraControl getControls]->gain);
  uvc_control_info_t *irControl = &([cameraControl getControls]->irLights);
  if(key == 's'){
    curGain = (curGain+3) % 63;
    [cameraControl setData:curGain withLength:control->size forSelector:control->selector at:control->unit];
  }
  if(key == 'g' || key == 's'){
    uvc_range_t range = [cameraControl getRangeForControl:control];
    curGain = [cameraControl getDataFor:UVC_GET_CUR withLength:control->size fromSelector:control->selector at:control->unit];
    ofLog() << "Gain:" << curGain << " min: " << range.min << " max: " << range.max;
    ofLog() << "Brightness:" << [cameraControl getBrightness];
    ofLog() << "Exposure:" << [cameraControl getExposure];
    uvc_range_t lightRange = [cameraControl getRangeForControl:irControl];
    curLights = [cameraControl getDataFor:UVC_GET_CUR withLength:irControl->size fromSelector:irControl->selector at:irControl->unit];
    ofLog() << "Lights: " << curLights << " min: " << lightRange.min << " max: " << lightRange.max;
  }
  if(key == 'n'){
    [cameraControl setGain:0.5];
  }
  if(key == 'l' || key == 'o' || (key >= '1' && key < '9')){
    if(key == 'l') curLights = 15;
    else if(key == 'o') curLights = 0;
    else if(key >= '1' && key < '9') curLights ^= (1<<(key-'1'));
    [cameraControl setData:curLights withLength:2 forSelector:3 at:3];
  }
  if(key == 'b'){
    [cameraControl setBrightness:0.0];
    [cameraControl setExposure:0.998];
    // [cameraControl setExposure:0.5];
  }
}

//--------------------------------------------------------------
void ofApp::videoSaved(ofVideoSavedEventArgs& e){
	// the ofQTKitGrabber sends a message with the file name and any errors when the video is done recording
	if(e.error.empty()){
	    recordedVideoPlayback.load(e.videoPath);
	    recordedVideoPlayback.play();

        if(bLaunchInQuicktime) {
            ofSystem("open " + e.videoPath);
        }
	}
	else {
		ofLogError("videoSavedEvent") << "Video save error: " << e.error;
	}
}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){}
