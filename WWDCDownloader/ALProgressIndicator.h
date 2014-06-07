//
//  ALProgressIndicator.h
//  ALUtilities
//
//  Created by Andy Lee on 6/7/14.
//

#import <Cocoa/Cocoa.h>

/*!
 * To make a thin progress bar in IB, drag in a Custom View, set its class to
 * this class, and make its height as small as you want.
 */
@interface ALProgressIndicator : NSProgressIndicator

@property (nonatomic, copy) NSColor *backgroundColor;

@end
