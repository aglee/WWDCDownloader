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

@interface WWDCWebsiteInteractionController ()
@property (nonatomic, strong) NSMutableArray *sessions;

@property (nonatomic, assign) NSUInteger numberAlreadyDownloaded;
@property (nonatomic, assign) NSUInteger numberCompleted;
@property (nonatomic, assign) NSUInteger numberFailed;
@property (nonatomic, assign) NSUInteger numberRemaining;
@end

@implementation WWDCWebsiteInteractionController {
	NSTimeInterval _startTimestamp;
}

- (id) init {
	return (self = [super initWithWindowNibName:@"WWDCWebsiteInteractionController"]);
}

- (void) awakeFromNib {
	[super awakeFromNib];

	[self refreshSessionInfo:nil];
}

#pragma mark - Getters and setters

- (NSInteger)totalNumberToDownload {
	return self.numberCompleted + self.numberFailed + self.numberRemaining;
}

#pragma mark - Action methods

- (IBAction) refreshSessionInfo:(id) sender {
	NSURL *WWDCVideosURL = [NSURL URLWithString:@"https://developer.apple.com/videos/wwdc/2014/"];

	self.sessions = nil;
	[self.webView.mainFrame loadRequest:[NSURLRequest requestWithURL:WWDCVideosURL]];

	// Update UI.
	[self updateControlsForGettingSessionInfo];
}

- (IBAction) download:(id) sender {
	if (self.sessions.count == 0) {
		return;
	}

	_startTimestamp = [[NSDate date] timeIntervalSince1970];
	self.numberAlreadyDownloaded = self.numberCompleted = self.numberFailed = self.numberRemaining = 0;

    for (WWDCSession *session in self.sessions) {
		// Updates numberAlreadyDownloaded and numberRemaining.
        [self queueDownloadsForSession:session];
    }

	// Update UI.
	[self updateControlsForDidStartDownloading];
}

#pragma mark - WebFrameLoadDelegate methods

- (void) webView:(WebView *) sender didFinishLoadForFrame:(WebFrame *) frame {
	if (frame != self.webView.mainFrame) {
		return;
	}

	// Scrape the DOM.
    WWDCDOMTraverser *domTraverser = [[WWDCDOMTraverser alloc] init];
    [domTraverser traverseRootElement:self.webView.mainFrameDocument.body];
	self.sessions = domTraverser.sessions;

	// Update UI.
	[self updateCountsOfAvailableFiles];
	[self updateControlsForReadyToDownload];
}

#pragma mark - Private methods - updating the UI

// We're waiting for a response with WWDC session info from apple.com.
- (void)updateControlsForGettingSessionInfo
{
	self.statusTextField.stringValue = @"Getting WWDC session info from apple.com...";
    [self.gettingSessionInfoSpinner startAnimation:nil];

    [self.HDCheckbox setEnabled:NO];
    [self.SDCheckbox setEnabled:NO];
    [self.PDFCheckbox setEnabled:NO];

	[self.refreshSessionsButton setEnabled:NO];
    [self.downloadButton setEnabled:NO];
}

// We've received and sorted through all the session info, and the
// user can now choose what files to download.
- (void)updateControlsForReadyToDownload
{
	self.statusTextField.stringValue = @"Ready to download selected files.";
    [self.gettingSessionInfoSpinner stopAnimation:nil];
	[self.downloadProgressBar stopAnimation:nil];

	[self.HDCheckbox setEnabled:YES];
	[self.SDCheckbox setEnabled:YES];
	[self.PDFCheckbox setEnabled:YES];

	[self.refreshSessionsButton setEnabled:YES];
	[self.downloadButton setEnabled:YES];

	self.timeElapsedTextField.stringValue = [self stringForTimeInterval:0];
}

// The user just asked us to start downloading.
- (void)updateControlsForDidStartDownloading
{
	self.downloadProgressBar.minValue = 0;
	self.downloadProgressBar.maxValue = self.totalNumberToDownload;
	self.downloadProgressBar.doubleValue = 0;

	if (self.totalNumberToDownload == 0) {
		if (self.numberAlreadyDownloaded == 0) {
			self.statusTextField.stringValue = @"No files to download.";
		} else {
			self.statusTextField.stringValue = [NSString stringWithFormat:@"All %@ files already downloaded.", @(self.numberAlreadyDownloaded)];
		}
	} else {
		if (self.numberAlreadyDownloaded == 0) {
			self.statusTextField.stringValue = [NSString stringWithFormat:@"Downloading %@ files.", @(self.totalNumberToDownload)];
		} else {
			self.statusTextField.stringValue = [NSString stringWithFormat:@"%@ already downloaded. Downloading %@ files.", @(self.numberAlreadyDownloaded), @(self.totalNumberToDownload)];
		}

		[self.downloadProgressBar startAnimation:nil];

		[self.HDCheckbox setEnabled:NO];
		[self.SDCheckbox setEnabled:NO];
		[self.PDFCheckbox setEnabled:NO];

		[self.refreshSessionsButton setEnabled:NO];
		[self.downloadButton setEnabled:NO];
	}
}

- (void) updateDownloadProgressBar
{
	self.downloadProgressBar.doubleValue = self.totalNumberToDownload - self.numberRemaining;
	[self updateTimeElapsedField];

	if (self.numberRemaining == 0) {
		[self updateControlsForReadyToDownload];
	}
}

- (void) updateCountsOfAvailableFiles {
	NSUInteger numberOfHD = 0;
	NSUInteger numberOfSD = 0;
	NSUInteger numberOfPDF = 0;

	for (WWDCSession *session in self.sessions) {
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

	self.HDCheckbox.title = [NSString stringWithFormat:@"Download HD videos (%@)", @(numberOfHD)];
	self.SDCheckbox.title = [NSString stringWithFormat:@"Download SD videos (%@)", @(numberOfSD)];
	self.PDFCheckbox.title = [NSString stringWithFormat:@"Download PDF videos (%@)", @(numberOfPDF)];
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

#pragma mark - Private methods - queuing downloads

- (void) queueDownloadsForSession:(WWDCSession *)session {

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
		[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:NULL];
		[strongSelf updateDownloadProgressBar];
	};

	[[NSOperationQueue requestQueue] addOperation:request];
}

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

@end
