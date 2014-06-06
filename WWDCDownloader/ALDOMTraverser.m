//
//  ALDOMTraverser.m
//  WWDCVideoBrowser
//
//  Created by Andy Lee on 6/5/14.
//  Copyright (c) 2014 Andy Lee. All rights reserved.
//

#import "ALDOMTraverser.h"
#import "DOMIteration.h"

@implementation ALDOMTraverser

- (void)traverseRootElement:(DOMHTMLElement *)element
{
	[self _traverseElement:element atDepth:0];
}

- (void)willTraverseElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth
{
}

- (void)didTraverseElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth
{
}

- (void)willVisitElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth
{
}

- (void)visitElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth
{
}

- (void)didVisitElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth
{
}

#pragma mark - Private methods

- (void)_traverseElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth
{
	[self willTraverseElement:element atDepth:depth];
	{{
		[self willVisitElement:element atDepth:depth];
		{{
			[self visitElement:element atDepth:depth];
		}}
		[self didVisitElement:element atDepth:depth];

		[element.children enumerateObjectsUsingBlock:^(DOMHTMLElement *childElement, unsigned childIndex, BOOL *stopEnumeration) {
			[self _traverseElement:childElement atDepth:(depth + 1)];
		}];
	}}
	[self didTraverseElement:element atDepth:depth];
}

@end
