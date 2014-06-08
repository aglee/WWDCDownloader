//
//  ALProgressIndicator.m
//  ALUtilities
//
//  Created by Andy Lee on 6/7/14.
//

#import "ALProgressIndicator.h"

@interface ALProgressIndicator ()
@property (nonatomic, assign) BOOL isAnimating;
@end

@implementation ALProgressIndicator

- (id)initWithCoder:(NSCoder *)aDecoder
{
	return [[super initWithCoder:aDecoder] _ALProgressIndicator_commonInit];
}

- (id)initWithFrame:(NSRect)frameRect
{
	return [[super initWithFrame:frameRect] _ALProgressIndicator_commonInit];
}

- (id)_ALProgressIndicator_commonInit
{
	// Needs to be layer-backed in order for overriding drawRect: to work.
	// Has something to do with the fact that NSProgressIndicator doesn't
	// use drawRect: to draw its animation.  When I was debugging drawing,
	// this is where I got the clue that we need to be layer-backed:
	// <http://stackoverflow.com/questions/18464814/subclass-nsprogressindicator>
	self.wantsLayer = YES;
	self.bezeled = NO;
	self.displayedWhenStopped = YES;
	self.indeterminate = NO;
	self.style = NSProgressIndicatorBarStyle;

	self.backgroundColor = [NSColor grayColor];

	return self;
}

#pragma mark - NSProgressIndicator methods

- (void)startAnimation:(id)sender
{
	[super startAnimation:sender];
	self.isAnimating = YES;
	[self setNeedsDisplay:YES];
}

- (void)stopAnimation:(id)sender
{
	[super stopAnimation:sender];
	self.isAnimating = NO;
}

#pragma mark - NSView methods

- (void)drawRect:(NSRect)dirtyRect
{
	if (self.isAnimating) {
		[super drawRect:dirtyRect];
	} else {
		[self.backgroundColor set];
		NSRectFill(dirtyRect);
	}
}

@end
