//
//  WPdfView.h
//
//
//  Created by Wonday on 17/4/21.
//  Copyright (c) wonday.org All rights reserved.
//

#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>


@class RCTEventDispatcher;

@interface WPdfView : UIView

@property(nonatomic, strong) NSString *asset;
@property(nonatomic, strong) NSString *path;
@property(nonatomic) int page;
@property(nonatomic) float scale;
@property(nonatomic) BOOL horizontal;


@property(nonatomic, copy) RCTBubblingEventBlock onChange;

- (void)updateBounds;

@end
