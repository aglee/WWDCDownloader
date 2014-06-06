//
//  WWDCBrowserWindowController.m
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

#import "WWDCWebsiteInteractionController.h"

#import "WWDCURLRequest.h"

#import "DOMIteration.h"

#import "DOMIteration.h"

#import "WWDCDOMTraverser.h"
#import "WWDCSession.h"

#import <WebKit/WebKit.h>

enum {
	WWDCVideoQualityNone = 0,
	WWDCVideoQualitySD = (1 << 0),
	WWDCVideoQualityHD = (1 << 1),
	WWDCVideoQualityBoth = (WWDCVideoQualitySD | WWDCVideoQualityHD)
};

@implementation WWDCWebsiteInteractionController {
	NSArray *_sessions;
}

- (id) init {
	return (self = [super initWithWindowNibName:@"WWDCWebsiteInteractionController"]);
}

#pragma mark -

- (void) awakeFromNib {
	[super awakeFromNib];

	NSURL *WWDCVideosURL = [NSURL URLWithString:@"https://developer.apple.com/videos/wwdc/2014/"];  //[agl] Do I need to hard-code the 2014?

	[self.webView setHidden:NO];
	[self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:WWDCVideosURL]];

	self.webView.frameLoadDelegate = self;
	self.webView.resourceLoadDelegate = self;

	[self.videoPopUpButton selectItemAtIndex:WWDCVideoQualityHD];

	[self.downloadButton setEnabled:NO];
	[self.downloadProgressBar setHidden:YES];
}

#pragma mark -

- (IBAction) download:(id) sender {
	if (_sessions.count == 0) {
		return;
	}

	[self.downloadButton setEnabled:NO];
	[self.downloadProgressBar setHidden:NO];

    for (WWDCSession *session in _sessions) {
        [self findDownloadsForSession:session];
    }
}

#pragma mark -

- (void) downloadWithURL:(NSURL *)sourceURL forSession:(WWDCSession *) session {
    if (sourceURL == nil) {
        return;
    }

	static NSString *downloadsFolder = nil;
	if (!downloadsFolder) {
		NSString *temporaryFolder = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		downloadsFolder = [[temporaryFolder stringByAppendingPathComponent:@"WWDC 2014/"] copy];

		if (![[NSFileManager defaultManager] fileExistsAtPath:downloadsFolder]) {
			[[NSFileManager defaultManager] createDirectoryAtPath:downloadsFolder withIntermediateDirectories:YES attributes:nil error:NULL];
		}
	}

	NSString *saveLocation = [NSString stringWithFormat:@"%ld %@.%@", (long)session.sessionNumber, session.title, sourceURL.pathExtension];
	saveLocation = [downloadsFolder stringByAppendingPathComponent:saveLocation];

	__weak typeof(self) weakSelf = self;
	WWDCURLRequest *request = [WWDCURLRequest requestWithRemoteAddress:sourceURL.absoluteString savePath:saveLocation];
	request.completionBlock = ^{
		__strong typeof(weakSelf) strongSelf = weakSelf;
		NSLog(@"done downloading \"%@\" to %@", saveLocation.lastPathComponent, saveLocation);

		strongSelf.downloadProgressBar.doubleValue++;
	};

	[[NSOperationQueue requestQueue] addOperation:request];

	self.downloadProgressBar.maxValue++;
}

// see above for the element that is passed in
- (void) findDownloadsForSession:(WWDCSession *)session {

    if ((self.videoPopUpButton.indexOfSelectedItem & WWDCVideoQualityHD) == WWDCVideoQualityHD) {
        [self downloadWithURL:session.highDefVideoURL forSession:session];
    }

    if ((self.videoPopUpButton.indexOfSelectedItem & WWDCVideoQualitySD) == WWDCVideoQualitySD) {
        [self downloadWithURL:session.standardDefVideoURL forSession:session];
    }

    if (self.PDFCheckbox.state == NSOnState) {
        [self downloadWithURL:session.slidesPDFURL forSession:session];
    }
}

#pragma mark -

- (void) webView:(WebView *) sender didFinishLoadForFrame:(WebFrame *) frame {
	self.window.title = frame.name;

    WWDCDOMTraverser *domTraverser = [[WWDCDOMTraverser alloc] init];
    [domTraverser traverseRootElement:self.webView.mainFrameDocument.body];
	_sessions = domTraverser.sessions;

	self.numberOfSessionsField.stringValue = [NSString stringWithFormat:@"Found %ld sessions", (long)_sessions.count];
	if (_sessions.count) {
		[self.downloadButton setEnabled:YES];
	}
}

@end
