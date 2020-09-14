/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>

#import "RCTPdfViewManager.h"
#import "RCTPdfView.h"


@implementation RCTPdfViewManager

RCT_EXPORT_MODULE()

- (UIView *)view
{
    if([[[UIDevice currentDevice] systemVersion] compare:@"11.0" options:NSNumericSearch] == NSOrderedDescending
       || [[[UIDevice currentDevice] systemVersion] compare:@"11.0" options:NSNumericSearch] == NSOrderedSame) {
        return [[RCTPdfView alloc] init];
    } else {
        return NULL;
    }
  
}

RCT_EXPORT_VIEW_PROPERTY(path, NSString);
RCT_EXPORT_VIEW_PROPERTY(page, int);
RCT_EXPORT_VIEW_PROPERTY(scale, float);
RCT_EXPORT_VIEW_PROPERTY(minScale, float);
RCT_EXPORT_VIEW_PROPERTY(maxScale, float);
RCT_EXPORT_VIEW_PROPERTY(horizontal, BOOL);
RCT_EXPORT_VIEW_PROPERTY(enablePaging, BOOL);
RCT_EXPORT_VIEW_PROPERTY(enableRTL, BOOL);
RCT_EXPORT_VIEW_PROPERTY(enableAnnotationRendering, BOOL);
RCT_EXPORT_VIEW_PROPERTY(fitPolicy, int);
RCT_EXPORT_VIEW_PROPERTY(spacing, int);
RCT_EXPORT_VIEW_PROPERTY(password, NSString);
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(singlePage, BOOL);

RCT_EXPORT_METHOD(supportPDFKit:(RCTResponseSenderBlock)callback)
{
    if([[[UIDevice currentDevice] systemVersion] compare:@"11.0" options:NSNumericSearch] == NSOrderedDescending
       || [[[UIDevice currentDevice] systemVersion] compare:@"11.0" options:NSNumericSearch] == NSOrderedSame) {
        callback(@[@YES]);
    } else {
        callback(@[@NO]);
    }
    
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}


- (void)dealloc{
}

@end