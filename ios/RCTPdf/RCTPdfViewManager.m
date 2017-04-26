//
//  RCTPdfViewManager.m
//
//
//  Created by Wonday on 17/4/21.
//  Copyright (c) wonday.org All rights reserved.
//

#import <Foundation/Foundation.h>
#import <React/RCTBridge.h>
#import "RCTPdfViewManager.h"
#import "RCTPdfView.h"
#import <React/RCTEventDispatcher.h>

@implementation RCTPdfViewManager

RCT_EXPORT_MODULE(RCTPdf)

- (UIView *)view
{
  return [RCTPdfView new];
}

RCT_EXPORT_VIEW_PROPERTY(path, NSString);
RCT_EXPORT_VIEW_PROPERTY(page, int);
RCT_EXPORT_VIEW_PROPERTY(scale, float);
RCT_EXPORT_VIEW_PROPERTY(horizontal, BOOL);
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock);

@end
