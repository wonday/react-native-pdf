/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#ifndef RNPDFPdfView_h
#define RNPDFPdfView_h

#if __has_include(<React/RCTAssert.h>)
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>
#else
#import "RCTEventDispatcher.h"
#import "UIView+React.h"
#endif

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTViewComponentView.h>
#endif

@class RCTEventDispatcher;

NS_CLASS_AVAILABLE_IOS(11_0) @interface RNPDFPdfView :
#ifdef RCT_NEW_ARCH_ENABLED
RCTViewComponentView
#else
UIView
#endif
<UIGestureRecognizerDelegate>
- (instancetype)initWithBridge:(RCTBridge *)bridge;

@property(nonatomic, strong) NSString *path;
@property(nonatomic) int page;
@property(nonatomic) float scale;
@property(nonatomic) float minScale;
@property(nonatomic) float maxScale;
@property(nonatomic) BOOL horizontal;
@property(nonatomic) BOOL showsVerticalScrollIndicator;
@property(nonatomic) BOOL showsHorizontalScrollIndicator;
@property(nonatomic) BOOL scrollEnabled;
@property(nonatomic) BOOL enablePaging;
@property(nonatomic) BOOL enableRTL;
@property(nonatomic) BOOL enableAnnotationRendering;
@property(nonatomic) BOOL enableDoubleTapZoom;
@property(nonatomic) int fitPolicy;
@property(nonatomic) int spacing;
@property(nonatomic, strong) NSString *password;
@property(nonatomic) BOOL singlePage;

@property(nonatomic, copy) RCTBubblingEventBlock onChange;


@end

#endif /* RNPDFPdfView_h */
