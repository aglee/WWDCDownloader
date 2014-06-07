//
//  WWDCBrowserWindowController.h
//  WWDCDownloader
//
//  Created by zach on 6/14/13.
//

@class WebView;

@interface WWDCWebsiteInteractionController : NSWindowController
@property (assign) IBOutlet WebView *webView;  // hidden -- used behind the scenes

@property (assign) IBOutlet NSButton *HDCheckbox;
@property (assign) IBOutlet NSButton *SDCheckbox;
@property (assign) IBOutlet NSButton *PDFCheckbox;

@property (assign) IBOutlet NSTextField *statusTextField;
@property (assign) IBOutlet NSProgressIndicator *gettingSessionInfoSpinner;

@property (assign) IBOutlet NSButton *downloadButton;
@property (assign) IBOutlet NSProgressIndicator *downloadProgressBar;

@property (assign) IBOutlet NSTextField *timeElapsedTextField;

@property (nonatomic, strong, readonly) NSArray *sessions;  // WWDCSession

@property (nonatomic, assign, readonly) NSUInteger numberAlreadyDownloaded;
@property (nonatomic, assign, readonly) NSUInteger numberCompleted;
@property (nonatomic, assign, readonly) NSUInteger numberFailed;
@property (nonatomic, assign, readonly) NSUInteger numberRemaining;

- (IBAction) download:(id) sender;

@end
