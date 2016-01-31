# TheEyeTribe Tracker Reverse Engineering

This repo contains the dumps, notes and scripts created by me in the process of reverse engineering the protocol used by the [Eye Tribe Tracker](http://theeyetribe.com/)

## Why am I doing this?

A large part of why I'm doing this is that I wanted to learn and try my hand at reverse engineering and disassembling some closed source software. But there is also the fact that it is the only forseeable path to being able to use the (albeit only $100) eye tracker I bought which is currently a mostly useless brick on my desk:

### Backstory

I can’t use the Eye Tribe tracker that I purchased a year ago for my research because I always get +/- 5 cm of jitter. This even happens with 5 star calibration when I get it, although half the time I try and use my tracker I can’t get a calibration it will accept even after a dozen tries. I’ve tried it many times in many places, with multiple OSX computers and a Windows VM, with glasses, contacts and no lenses, many people, different calibration types etc. Not to mention I have to captured video through it of me looking around and it looks perfect, pupils and glints are sharp and eminently trackable. I had to use my own external IR illuminators since activating the built in IR LEDs by starting the server blocks my ability to grab frames from the camera.

The only reasons I can think of for why I could be getting such bad results are that the built in illuminators aren’t as good as the illuminators I tested with, or there is something wrong with the proprietary computer vision code that isn’t working very well in my situation. I can’t test either hypothesis because the program is closed source and there is no debug view where I can see what is going wrong with the tracking.

I’ve seen demo videos of Eye Tribe trackers working with +/- 1cm level precision in YouTube videos so I know it is possible. At the moment I’m using a [Pupil Labs](http://pupil-labs.com/pupil/) eye tracker for my research and that one works fine. I've even tried out a webcam-based eye tracker on a laptop that got better results than I have ever gotten with my Eye Tribe (https://xlabsgaze.com/).But nevertheless my Eye Tribe is useless and judging by forum posts (and even an academic paper which mentioned it) others are getting similarly terrible results.

### But why reverse engineer?

I want to be able to stream the output of the tracker with its own IR illuminators on. I can't grab frames while the proprietary server is running, and I can't turn the illuminators on with a standard webcam app. I want to be able to do this for two potential reasons:

1. To diagnose why I (and likely others) get such bad tracking results. I hope that by viewing the same camera stream with the same illuminators as the proprietary server does I'll be able to see what might be failing in the eye tracking algorithm. Perhaps the illuminators are too dim or the glints are small and hard to detect?
2. To potentially write my own open source cross-platform (including Linux) eye tracking software for the Eye Tribe tracker. I've read a bunch of papers on how to implement head-pose invariant gaze trackers using similar hardware and figure I should be able to get better accuracy than the Eye Tribe software (but then again the Eye Tribe software is supposed to get better results than it does). This would be potentially useful for others facing accuracy issues and Linux users. As well as being fun and interesting!

Sidenote: Yes I did try contacting The Eye Tribe and asked for help and offering my assistance debugging, but alas I recieved no response (it has been one week, they could still get back to me).

## Progress so far

During most of these steps I copy-pasted things into the `eyetribe.h` file, which started out as a dumped header but ended up being dumped everything.

- Ran the OSX USB Prober dev tool and found that there is a UVC (USB Camera spec) control endpoint as part of the eye tracker
- Disassembled the OSX version of the server
- Found out they use a modified version of [this open-source Obj-C class](https://github.com/HBehrens/CamHolderApp/blob/master/CamHolderApp%2FUVCCameraControl.m) to send control messages.
- Tried using dtrace to log USB messages, but that didn't get me the message contents, only that the message occured
- Looked through dtrace call stacks and [Apple's open source USB control message internals](http://www.opensource.apple.com/source/IOUSBFamily/IOUSBFamily-203.4.7/IOUSBLib/Classes/IOUSBInterfaceClass.cpp) for good points to intercept the message data.
- Ran the Eye Tribe server under LLDB and set breakpoints based on the disassembly I had done to find where control messages were sent, poked around until I found a register pointing to a [IOUSBDevRequest](https://developer.apple.com/library/mac/documentation/Kernel/Reference/USB_kernel_header_reference/index.html#//apple_ref/c/tdef/IOUSBDevRequest).
- Attached a script to an LLDB breakpoint on `IOUSBInterfaceClass::interfaceControlRequest(void*, unsigned char, IOUSBDevRequest*) + 12` which printed out the bytes of the UIUSBDevRequest as integers and the data pointed to by the data pointer. (See log2.txt and log3.txt for output)
- Wrote a Ruby script to extract the control request fields and names from the LLDB logs (`parsedump.rb`). It took reading the [UVC Spec](http://www.cajunbot.com/wiki/images/8/85/USB_Video_Class_1.1.pdf), the USB Prober output (found in `USBProber.txt`), and the aformentioned [UVCCameraControl.m](https://github.com/HBehrens/CamHolderApp/blob/master/CamHolderApp%2FUVCCameraControl.m) to figure out where fields were and how they corresponded to items in the spec.

Status: I've discovered the extension selectors and data sent during initial connection and when turning on the camera lights.

Next step: Write an app that first gets the raw camera stream without lights on, and then try adding extension unit messages from the logs until the lights turn on.

Current fears: When disassembling I found that the CryptoPP library was linked into the code. I don't know if/how they use it but I sure hope that the USB protocol isn't authenticated.
