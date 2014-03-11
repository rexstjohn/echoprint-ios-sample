//
//  echoprintViewController.m
//  echoprint
//
//  Created by Brian Whitman on 6/13/11.
//  Copyright 2011 The Echo Nest. All rights reserved.
//

#import "echoprintViewController.h"
#import "ASIHTTPRequest.h"

@implementation echoprintViewController

- (IBAction)pickSong:(id)sender {
	NSLog(@"Pick song");
	MPMediaPickerController* mediaPicker = [[[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic] autorelease];
	mediaPicker.delegate = self;
	[self presentViewController:mediaPicker animated:YES completion:nil];
	
}
- (IBAction) startMicrophone:(id)sender {
	if(recording) {
		recording = NO;
		[recorder stopRecording];
		[recordButton setTitle:@"Record" forState:UIControlStateNormal];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = paths[0];
		NSString *filePath =[documentsDirectory stringByAppendingPathComponent:@"output.caf"];
		[statusLine setText:@"analysing..."];
		[statusLine setNeedsDisplay];
		[self.view setNeedsDisplay];
        NSString* fpCode = [FPGenerator generateFingerprintForFile:filePath];
        [self getSong:fpCode];
	} else {
		[statusLine setText:@"recording..."];
		recording = YES;
		[recordButton setTitle:@"Stop" forState:UIControlStateNormal];
		[recorder startRecording];
		[statusLine setNeedsDisplay];
		[self.view setNeedsDisplay];
	}
	NSLog(@"what");

}


- (void)mediaPicker:(MPMediaPickerController *)mediaPicker 
  didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
	[self dismissViewControllerAnimated:YES completion:nil];
	for (MPMediaItem* item in mediaItemCollection.items) {
		NSString* title = [item valueForProperty:MPMediaItemPropertyTitle];
		NSURL* assetURL = [item valueForProperty:MPMediaItemPropertyAssetURL];
		NSLog(@"title: %@, url: %@", title, assetURL);
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = paths[0];

		NSURL* destinationURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"temp_data"]];
		[[NSFileManager defaultManager] removeItemAtURL:destinationURL error:nil];
		TSLibraryImport* import = [[TSLibraryImport alloc] init];
		[import importAsset:assetURL toURL:destinationURL completionBlock:^(TSLibraryImport* import) {
			//check the status and error properties of
			//TSLibraryImport
			NSString *outPath = [documentsDirectory stringByAppendingPathComponent:@"temp_data"];
			NSLog(@"done now. %@", outPath);
			[statusLine setText:@"analysing..."];
			
            NSString* fpCode = [FPGenerator generateFingerprintForFile:outPath];
            
			[statusLine setNeedsDisplay];
			[self.view setNeedsDisplay];
			[self getSong:fpCode];
		}];
		
	}
}


- (void) getSong: (NSString*) fpCode {
	NSLog(@"Done %@", fpCode);

    NSString *apiString = [NSString stringWithFormat:@"http://%@/api/v4/song/identify?api_key=%@&version=4.11&code=%@&format=json", API_HOST, API_KEY, fpCode];
    
    NSURL *url = [NSURL URLWithString:apiString];
	
    ASIHTTPRequest * request = [ASIHTTPRequest requestWithURL:url];
	[request setAllowCompressedResponse:NO];
	[request startSynchronous];
	NSError *error = [request error];
	if (!error) {
		NSString *response = [[NSString alloc] initWithData:[request responseData] encoding:NSUTF8StringEncoding];
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[response dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
		NSLog(@"%@", dictionary);
		NSArray *songList = dictionary[@"response"][@"songs"];
		if([songList count]>0) {
			NSString * song_title = songList[0][@"title"];
			NSString * artist_name = songList[0][@"artist_name"];
			[statusLine setText:[NSString stringWithFormat:@"%@ - %@", artist_name, song_title]];
		} else {
			[statusLine setText:@"no match"];
		}
	} else {
		[statusLine setText:@"some error"];
		NSLog(@"error: %@", error);
	}
	[statusLine setNeedsDisplay];
	[self.view setNeedsDisplay];
}



- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
	[self dismissViewControllerAnimated:YES completion:nil];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	recorder = [[MicrophoneInput alloc] init];
	recording = NO;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
