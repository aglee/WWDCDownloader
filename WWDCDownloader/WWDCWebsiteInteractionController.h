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

- (IBAction) download:(id) sender;

@end
