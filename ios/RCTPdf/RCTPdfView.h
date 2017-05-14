//
//  RCTPdfView.h
//
//
//  Created by Wonday on 17/4/21.
//  Copyright (c) wonday.org All rights reserved.
//

#if __has_include(<React/RCTAssert.h>)
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>
#else
#import "RCTEventDispatcher.h"
#import "UIView+React.h"
#endif


@class RCTEventDispatcher;

@interface RCTPdfView : UIView

@property(nonatomic, strong) NSString *path;
@property(nonatomic) int page;
@property(nonatomic) float scale;
@property(nonatomic) BOOL horizontal;


@property(nonatomic, copy) RCTBubblingEventBlock onChange;


@end
