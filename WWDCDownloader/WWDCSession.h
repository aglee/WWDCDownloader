//
//  WVSession.h
//  WWDCVideoBrowser
//
//  Created by Andy Lee on 6/5/14.
//  Copyright (c) 2014 Andy Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! Info about one WWDC session. */
@interface WWDCSession : NSObject

@property (nonatomic, assign) NSInteger sessionNumber;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *track;
@property (nonatomic, copy) NSString *platform;
@property (nonatomic, copy) NSString *blurb;
@property (nonatomic, copy) NSURL *highDefVideoURL;
@property (nonatomic, copy) NSURL *standardDefVideoURL;
@property (nonatomic, copy) NSURL *slidesPDFURL;

@end
