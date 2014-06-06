//
//  WWDCBrowserWindowController.m
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

#import "WWDCWebsiteInteractionController.h"
#import "WWDCURLRequest.h"
#import "DOMIteration.h"
#import "WWDCDOMTraverser.h"
#import "WWDCSession.h"
#import <WebKit/WebKit.h>

@implementation WWDCWebsiteInteractionController {
	NSArray *_sessions;  // WWDCSession
	NSTimeInterval _startTimestamp;
}

- (id) init {
	return (self = [super initWithWindowNibName:@"WWDCWebsiteInteractionController"]);
}

#pragma mark -

- (void) awakeFromNib {
	[super awakeFromNib];

	NSURL *WWDCVideosURL = [NSURL URLWithString:@"https://developer.apple.com/videos/wwdc/2014/"];

	[self.webView setHidden:YES];
	[self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:WWDCVideosURL]];

	self.webView.frameLoadDelegate = self;

	// Update UI.
    [self.HDCheckbox setEnabled:NO];
    [self.SDCheckbox setEnabled:NO];
    [self.PDFCheckbox setEnabled:NO];
    [self.downloadButton setEnabled:NO];

	[self.gettingSessionInfoSpinner setHidden:NO];
    [self.gettingSessionInfoSpinner startAnimation:nil];
	[self.downloadProgressBar setHidden:YES];
}

- (NSInteger)totalNumberToDownload {
	return self.numberAlreadyDownloaded + self.numberCompleted + self.numberFailed + self.numberRemaining;
}

#pragma mark -

- (IBAction) download:(id) sender {
	if (_sessions.count == 0) {
		return;
	}

	_startTimestamp = [[NSDate date] timeIntervalSince1970];
	self.numberAlreadyDownloaded = self.numberCompleted = self.numberFailed = self.numberRemaining = 0;

    for (WWDCSession *session in _sessions) {
		// Updates numberAlreadyDownloaded and numberRemaining.
        [self findDownloadsForSession:session];
    }

	// Update UI.
	self.downloadProgressBar.minValue = 0;
	self.downloadProgressBar.maxValue = self.totalNumberToDownload;
	[self updateDownloadProgressBar];

	self.statusTextField.stringValue = [NSString stringWithFormat:@"Downloading %@ files", @(self.totalNumberToDownload)];

	if (self.totalNumberToDownload > 0) {
		[self.HDCheckbox setEnabled:NO];
		[self.SDCheckbox setEnabled:NO];
		[self.PDFCheckbox setEnabled:NO];

		[self.downloadButton setEnabled:NO];
//		self.downloadButton.title = @"Quit";
//		self.downloadButton.target = nil;
//		self.downloadButton.action = @selector(terminate:);

		[self.downloadProgressBar setHidden:NO];
		[self.downloadProgressBar startAnimation:nil];
	}
}

#pragma mark -

- (void) downloadHDVideoForSession:(WWDCSession *) session {
	NSURL *sourceURL = session.highDefVideoURL;
	NSString *fileName = [NSString stringWithFormat:@"%@ %@ (HD).%@", @(session.sessionNumber), session.title, sourceURL.pathExtension];

	[self downloadFromURL:sourceURL toFileName:fileName];
}

- (void) downloadSDVideoForSession:(WWDCSession *) session {
	NSURL *sourceURL = session.standardDefVideoURL;
	NSString *fileName = [NSString stringWithFormat:@"%@ %@ (SD).%@", @(session.sessionNumber), session.title, sourceURL.pathExtension];

	[self downloadFromURL:sourceURL toFileName:fileName];
}

- (void) downloadPDFVideoForSession:(WWDCSession *) session {
	NSURL *sourceURL = session.slidesPDFURL;
	NSString *fileName = [NSString stringWithFormat:@"%@ %@.%@", @(session.sessionNumber), session.title, sourceURL.pathExtension];

	[self downloadFromURL:sourceURL toFileName:fileName];
}

- (void) downloadFromURL:(NSURL *)sourceURL toFileName:(NSString *)fileName {
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

	NSString *saveFilePath = [downloadsFolder stringByAppendingPathComponent:fileName];
	NSString *tempFilePath = [saveFilePath stringByAppendingPathExtension:@"download"];

	if ([[NSFileManager defaultManager] fileExistsAtPath:saveFilePath]) {
		// Looks like we already downloaded this file.
		self.numberAlreadyDownloaded++;
		return;
	} else {
		self.numberRemaining++;
	}

	__weak typeof(self) weakSelf = self;
	WWDCURLRequest *request = [WWDCURLRequest requestWithRemoteAddress:sourceURL.absoluteString savePath:tempFilePath];

	request.successBlock = ^(WWDCURLRequest *request, WWDCURLResponse *response, NSError *error) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		NSLog(@"done downloading \"%@\" to \"%@\"", sourceURL, saveFilePath);
		self.numberCompleted++;
		self.numberRemaining--;
		[strongSelf updateDownloadProgressBar];
		[[NSFileManager defaultManager] moveItemAtPath:tempFilePath toPath:saveFilePath error:NULL];
	};

	request.failureBlock = ^(WWDCURLRequest *request, WWDCURLResponse *response, NSError *error) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		NSLog(@"failed downloading \"%@\" to \"%@\"", sourceURL, saveFilePath);
		self.numberFailed++;
		self.numberRemaining--;
		[strongSelf updateDownloadProgressBar];
		[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:NULL];
	};
    
	[[NSOperationQueue requestQueue] addOperation:request];
}

- (void) updateDownloadProgressBar
{
	if (self.numberRemaining == 0) {
		[self.downloadProgressBar setHidden:YES];
	} else {
		self.downloadProgressBar.doubleValue = self.totalNumberToDownload - self.numberRemaining;
	}
	[self updateTimeElapsedField];
}

- (void) updateTimeElapsedField {
	NSTimeInterval endTimestamp = [[NSDate date] timeIntervalSince1970];
	self.timeElapsedTextField.stringValue = [self stringForTimeInterval:(endTimestamp - _startTimestamp)];
}

- (NSString *)stringForTimeInterval:(NSTimeInterval)interval
{
	long totalSeconds = interval;
	long hours = totalSeconds / (60*60);
	long remainder = totalSeconds % (60*60);
	long minutes = remainder / 60;
	long seconds = remainder % 60;

	return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", hours, minutes, seconds];
}

- (void) findDownloadsForSession:(WWDCSession *)session {

    if (self.HDCheckbox.state == NSOnState) {
        [self downloadHDVideoForSession:session];
    }

    if (self.SDCheckbox.state == NSOnState) {
        [self downloadSDVideoForSession:session];
    }

    if (self.PDFCheckbox.state == NSOnState) {
        [self downloadPDFVideoForSession:session];
    }
}

- (void) countAvailableFiles {
	NSInteger numberOfHD = 0;
	NSInteger numberOfSD = 0;
	NSInteger numberOfPDF = 0;

	for (WWDCSession *session in _sessions) {
		if (session.highDefVideoURL) {
			numberOfHD++;
		}
		if (session.standardDefVideoURL) {
			numberOfSD++;
		}
		if (session.slidesPDFURL) {
			numberOfPDF++;
		}
	}

	[self putCount:numberOfHD inCheckbox:self.HDCheckbox];
	[self putCount:numberOfSD inCheckbox:self.SDCheckbox];
	[self putCount:numberOfPDF inCheckbox:self.PDFCheckbox];
}

- (void) putCount:(NSUInteger)count inCheckbox:(NSButton *)checkbox
{
	checkbox.title = [NSString stringWithFormat:@"%@ (%@)", checkbox.title, @(count)];
	[checkbox sizeToFit];
}

#pragma mark - <WebFrameLoadDelegate> methods

- (void) webView:(WebView *) sender didFinishLoadForFrame:(WebFrame *) frame {
	// Scrape the DOM.
    WWDCDOMTraverser *domTraverser = [[WWDCDOMTraverser alloc] init];
    [domTraverser traverseRootElement:self.webView.mainFrameDocument.body];
	_sessions = domTraverser.sessions;
	[self countAvailableFiles];

	// Update UI.
	[self.HDCheckbox setEnabled:YES];
	[self.SDCheckbox setEnabled:YES];
	[self.PDFCheckbox setEnabled:YES];
	[self.downloadButton setEnabled:YES];

	self.timeElapsedTextField.stringValue = [self stringForTimeInterval:0];

    [self.gettingSessionInfoSpinner setHidden:YES];
    [self.gettingSessionInfoSpinner stopAnimation:nil];
	self.statusTextField.stringValue = [NSString stringWithFormat:@"Found %@ WWDC sessions", @(_sessions.count)];
}

@end
