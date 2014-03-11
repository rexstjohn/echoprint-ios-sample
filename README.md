***** UPDATE *****

March 10th, 2014

Turns out many of the .h headers were not set to C++ and we needed to link against the C++ dylib. I have successfully used this to both select a song from my library and record an audio segment and correctly identify it now. 

(March 6th, 2014)

I just merged a pull request with a fix to the issues people were having previously, hopefully these are now resolved.
 There is a thread on Google Groups: https://groups.google.com/forum/#!topic/echoprint/Zi_ip49Xgds.


OVERVIEW

This is an upgraded version of the Echoprint Sample iOS Project.

- Works in XCode 5.0 + iOS 7
- Modernized Objective-C
- Modernized UIKit and other legacy project files
- Updated ASIHTTP to more current version
- Added Cocoapods
- Builds in the echoprint-codegen-ios library as a sub-project
- Added project dependency on lbstdc++.6.0.9.dylib that didn't seem to be required before

INSTALL / SETUP INSTRUCTIONS

- Sign up for an Echoprint API key on developer.echoprint.com and replace "API_KEY" in "echoprintViewController" with yours
- The project requires a depdendency on libechoprint-codegen-ios.a and thus needs to build the sub-project (see below)
- Run pod install to setup the pod files in the project root
- Download Boost 1.5+ and unzip it someplace useful like /Users/YOUR_USER_GOES_HERE_REPLACE_THIS/Development/boost
- Open the project workspace created by Cocoapods (not the main project)
- In "echoprint-codegen-ios.xcconfig" in the "echoprint-codegen-ios" sub-project, make sure this line points to your boost directory:

HEADER_SEARCH_PATHS = /Users/YOUR_USER_GOES_HERE_REPLACE_THIS/Development/boost

It should build for you. 


