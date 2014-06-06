//
//  WVDOMTraverser.h
//  WWDCVideoBrowser
//
//  Created by Andy Lee on 6/5/14.
//  Copyright (c) 2014 Andy Lee. All rights reserved.
//

#import "ALDOMTraverser.h"

/*! After you call traverseRootElement:, self.sessions contains an array of WVSession. */
@interface WWDCDOMTraverser : ALDOMTraverser

@property (nonatomic, strong, readonly) NSArray *sessions;

@end
