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

	NSUInteger _numberOfHD;
	NSUInteger _numberOfSD;
	NSUInteger _numberOfPDF;

	NSUInteger _totalNumberToDownload;
	NSUInteger _numberCompleted;
	NSUInteger _numberFailed;
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

#pragma mark -

- (IBAction) download:(id) sender {
	if (_sessions.count == 0) {
		return;
	}

	_totalNumberToDownload = _numberCompleted = _numberFailed = 0;

    for (WWDCSession *session in _sessions) {
		// Updates _totalNumberToDownload.
        [self findDownloadsForSession:session];
    }

	// Update UI.
	self.downloadProgressBar.minValue = 0;
	self.downloadProgressBar.doubleValue = 0;
	self.downloadProgressBar.maxValue = _totalNumberToDownload;
	[self putNumberCompletedInStatusField];

	if (_totalNumberToDownload > 0) {
		[self.HDCheckbox setEnabled:NO];
		[self.SDCheckbox setEnabled:NO];
		[self.PDFCheckbox setEnabled:NO];

		self.downloadButton.title = @"Quit";
		self.downloadButton.target = nil;
		self.downloadButton.action = @selector(terminate:);

		[self.downloadProgressBar setHidden:NO];
		[self.downloadProgressBar startAnimation:nil];
	}
}

- (void) putNumberCompletedInStatusField {
	self.statusTextField.stringValue = [NSString stringWithFormat:@"%@ done, %@ failed, %@ remaining", @(_numberCompleted), @(_numberFailed), @(_totalNumberToDownload - _numberCompleted - _numberFailed)];
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

	_totalNumberToDownload++;

	NSString *saveFileName = [NSString stringWithFormat:@"%@ %@.%@", @(session.sessionNumber), session.title, sourceURL.pathExtension];
	NSString *saveFilePath = [downloadsFolder stringByAppendingPathComponent:saveFileName];
	NSString *tempFilePath = [saveFilePath stringByAppendingPathExtension:@"download"];

	if ([[NSFileManager defaultManager] fileExistsAtPath:saveFilePath]) {
		// Looks like we already downloaded this file.
		_numberCompleted++;
		[self updateDownloadProgressBar];
		return;
	}

	__weak typeof(self) weakSelf = self;
	WWDCURLRequest *request = [WWDCURLRequest requestWithRemoteAddress:sourceURL.absoluteString savePath:tempFilePath];

	request.successBlock = ^(WWDCURLRequest *request, WWDCURLResponse *response, NSError *error) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		NSLog(@"done downloading \"%@\" to \"%@\"", sourceURL, saveFilePath);
		_numberCompleted++;
		[strongSelf updateDownloadProgressBar];
		[[NSFileManager defaultManager] moveItemAtPath:tempFilePath toPath:saveFilePath error:NULL];
	};

	request.failureBlock = ^(WWDCURLRequest *request, WWDCURLResponse *response, NSError *error) {
		__strong typeof(weakSelf) strongSelf = weakSelf;
		NSLog(@"failed downloading \"%@\" to \"%@\"", sourceURL, saveFilePath);
		_numberFailed++;
		[strongSelf updateDownloadProgressBar];
		[[NSFileManager defaultManager] removeItemAtPath:tempFilePath error:NULL];
	};
    
	[[NSOperationQueue requestQueue] addOperation:request];
}

- (void) updateDownloadProgressBar
{
	self.downloadProgressBar.doubleValue = _numberCompleted + _numberFailed;
	if (_numberCompleted + _numberFailed == _totalNumberToDownload) {
		[self.downloadProgressBar setHidden:YES];
	}

	[self putNumberCompletedInStatusField];
}

- (void) findDownloadsForSession:(WWDCSession *)session {

    if (self.HDCheckbox.state == NSOnState) {
        [self downloadWithURL:session.highDefVideoURL forSession:session];
    }

    if (self.SDCheckbox.state == NSOnState) {
        [self downloadWithURL:session.standardDefVideoURL forSession:session];
    }

    if (self.PDFCheckbox.state == NSOnState) {
        [self downloadWithURL:session.slidesPDFURL forSession:session];
    }
}

- (void) countAvailableFiles {
	_numberOfHD = _numberOfSD = _numberOfPDF = 0;
	for (WWDCSession *session in _sessions) {
		if (session.highDefVideoURL) {
			_numberOfHD++;
		}
		if (session.standardDefVideoURL) {
			_numberOfSD++;
		}
		if (session.slidesPDFURL) {
			_numberOfPDF++;
		}
	}
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
	[self putCount:_numberOfHD inCheckbox:self.HDCheckbox];
	[self putCount:_numberOfSD inCheckbox:self.SDCheckbox];
	[self putCount:_numberOfPDF inCheckbox:self.PDFCheckbox];
	[self.HDCheckbox setEnabled:YES];
	[self.SDCheckbox setEnabled:YES];
	[self.PDFCheckbox setEnabled:YES];
	[self.downloadButton setEnabled:YES];

    [self.gettingSessionInfoSpinner setHidden:YES];
    [self.gettingSessionInfoSpinner stopAnimation:nil];
	self.statusTextField.stringValue = [NSString stringWithFormat:@"Found %@ sessions", @(_sessions.count)];
}

@end
