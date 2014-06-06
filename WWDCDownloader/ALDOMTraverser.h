//
//  ALDOMTraverser.h
//  WWDCVideoBrowser
//
//  Created by Andy Lee on 6/5/14.
//  Copyright (c) 2014 Andy Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

// [agl] Add error-handling.

@class DOMHTMLElement;

@interface ALDOMTraverser : NSObject

/*! Recursively (depth-first) visits element and element's descendants. */
- (void)traverseRootElement:(DOMHTMLElement *)element;
- (void)willTraverseElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth;
- (void)didTraverseElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth;

- (void)visitElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth;
- (void)willVisitElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth;
- (void)didVisitElement:(DOMHTMLElement *)element atDepth:(NSInteger)depth;

@end
