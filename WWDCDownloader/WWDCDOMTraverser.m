//
//  WVDOMTraverser.m
//  WWDCVideoBrowser
//
//  Created by Andy Lee on 6/5/14.
//  Copyright (c) 2014 Andy Lee. All rights reserved.
//

#import "WWDCDOMTraverser.h"
#import "WWDCSession.h"
#import <WebKit/WebKit.h>

@interface WWDCDOMTraverser ()
@property (nonatomic, strong) WWDCSession *currentSession;
@property (nonatomic, strong) NSMutableArray *mutableSessions;
@property (nonatomic, strong) DOMHTMLElement *currentSessionElement;  // class="session"
@property (nonatomic, strong) DOMHTMLElement *currentDescriptionActiveElement;  // class="description active"
@property (nonatomic, strong) DOMHTMLElement *currentDownloadElement;  // class="download"
@end

@implementation WWDCDOMTraverser

#pragma mark - Getters and setters

- (NSArray *)sessions
{
	return [NSArray arrayWithArray:self.mutableSessions];
}

#pragma mark - ALDOMTraverser methods

- (void)traverseRootElement:(DOMHTMLElement *)element
{
	self.currentSession = nil;
	self.mutableSessions = [[NSMutableArray alloc] init];

	self.currentSessionElement = nil;
	self.currentDescriptionActiveElement = nil;
	self.currentDownloadElement = nil;

	[super traverseRootElement:element];
}

/*!
	The following illustrates the part of the page structure we're looking for:

	li class=[session] id=[207-video]   <== Case 1
		ul
			li class=[title]   <== Case 2
			li class=[track]   <== Case 3
			li class=[platform]   <== Case 4
		div class=[details]
			div class=[description active]   <== Case 5
				p textContent=[OS X is known for...]   <== Case 6
				p class=[download]   <== Case 7
					a href=[http://devstreaming.apple.com/videos/wwdc/2014/207xx270npvffao/207/207_hd_accessibility_on_os_x.mov?dl=1]   <== Case 8
					a href=[http://devstreaming.apple.com/videos/wwdc/2014/207xx270npvffao/207/207_sd_accessibility_on_os_x.mov?dl=1]   <== Case 9
					a href=[http://devstreaming.apple.com/videos/wwdc/2014/207xx270npvffao/207/207_accessibility_on_os_x.pdf?dl=1]   <== Case 10
 */
- (void)willTraverseElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth
{
	if ([self _element:element matchesTag:@"li" andClass:@"session"])
	{
		// Case 1, li class=[session] id=[207-video]
		NSString *sessionNumberString = [[element getAttribute:@"id"] componentsSeparatedByString:@"-"][0];

		self.currentSession = [[WWDCSession alloc] init];
		self.currentSession.sessionNumber = sessionNumberString.integerValue;
		[self.mutableSessions addObject:self.currentSession];

		self.currentSessionElement = element;
		self.currentDescriptionActiveElement = nil;
		self.currentDownloadElement = nil;
	}
	else if ([self _element:element matchesTag:@"li" andClass:@"title"] && (self.currentSessionElement != nil))
	{
		// Case 2, li class=[title]
		self.currentSession.title = element.textContent;
	}
	else if ([self _element:element matchesTag:@"li" andClass:@"track"] && (self.currentSessionElement != nil))
	{
		// Case 3, li class=[track]
		self.currentSession.track = element.textContent;
	}
	else if ([self _element:element matchesTag:@"li" andClass:@"platform"] && (self.currentSessionElement != nil))
	{
		// Case 4, li class=[platform]
		self.currentSession.platform = element.textContent;
	}
	else if ([self _element:element matchesTag:@"div" andClass:@"description active"])
	{
		// Case 5, div class=[description active]
		self.currentDescriptionActiveElement = element;
	}
	else if ([self _element:element matchesTag:@"p" andClass:nil] && (self.currentDescriptionActiveElement != nil))
	{
		// Case 6, p textContent=[OS X is known for...]
		self.currentSession.blurb = element.textContent;
	}
	else if ([self _element:element matchesTag:@"p" andClass:@"download"])
	{
		// Case 7, p class=[download]
		self.currentDownloadElement = element;
	}
	else if ([self _element:element matchesTag:@"a" andClass:nil] && (self.currentDownloadElement != nil))
	{
		NSURL *url = [NSURL URLWithString:[element getAttribute:@"href"]];

		if ([self _looksLikeHDVideo:url])
		{
			// Case 8
			self.currentSession.highDefVideoURL = url;
		}
		else if ([self _looksLikeSDVideo:url])
		{
			// Case 9
			self.currentSession.standardDefVideoURL = url;
		}
		else if ([self _looksLikePDF:url])
		{
			// Case 10
			self.currentSession.slidesPDFURL = url;
		}
	}
}

- (BOOL)_element:(DOMHTMLElement *)element matchesTag:(NSString *)tagToMatch andClass:(NSString *)classToMatch
{
	NSString *tagName = element.tagName.lowercaseString;
	if (tagName.length == 0) {
		tagName = nil;
	}

	if (tagToMatch.length) {
		if (![tagName isEqualToString:tagToMatch.lowercaseString]) {
			return NO;
		}
	} else {
		if (tagName) {
			return NO;
		}
	}

	NSString *classAttribute = [element getAttribute:@"class"];
	if (classAttribute.length == 0) {
		classAttribute = nil;
	}

	if (classToMatch.length) {
		if (![classAttribute isEqualToString:classToMatch]) {
			return NO;
		}
	} else {
		if (classAttribute) {
			return NO;
		}
	}

	return YES;
}

- (BOOL)_looksLikeHDVideo:(NSURL *)url
{
	return [url.pathExtension isEqualToString:@"mov"] && ([url.lastPathComponent rangeOfString:@"_hd_"].location != NSNotFound);
}

- (BOOL)_looksLikeSDVideo:(NSURL *)url
{
	return [url.pathExtension isEqualToString:@"mov"] && ([url.lastPathComponent rangeOfString:@"_sd_"].location != NSNotFound);
}

- (BOOL)_looksLikePDF:(NSURL *)url
{
	return [url.pathExtension isEqualToString:@"pdf"];
}

- (void)didTraverseElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth
{
	if (element == self.currentSessionElement)
	{
		self.currentSessionElement = nil;
	}
	else if (element == self.currentDescriptionActiveElement)
	{
		self.currentDescriptionActiveElement = nil;
	}
	else if (element == self.currentDownloadElement)
	{
		self.currentDownloadElement = nil;
	}
}

@end
