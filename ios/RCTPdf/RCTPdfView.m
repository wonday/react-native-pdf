//
//  RCTPdfView.m
//  
//
//  Created by Wonday on 17/4/21.
//  Copyright (c) wonday.org All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "RCTPdfView.h"
#import "WPdfView.h"

#if __has_include(<React/RCTAssert.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>
#import <React/RCTLog.h>
#else
#import "RCTBridgeModule.h"
#import "RCTEventDispatcher.h"
#import "UIView+React.h"
#import "RCTLog.h"
#endif

@implementation RCTPdfView {

    WPdfView *wPdfView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.clipsToBounds = TRUE;
        wPdfView = [[WPdfView alloc] initWithFrame:self.bounds];
        [self addSubview:wPdfView];
        
    }
    return self;
}

- (void)setPath:(NSString *)path
{
    
    [wPdfView setPath:path];
    
}

- (void)setPage:(int)page
{
    
    [wPdfView setPage:page];
    
}

- (void)setScale:(float)scale
{
    if (scale ==0) return;
    [wPdfView setScale:scale];

}

- (void)setHorizontal:(BOOL)horizontal
{

    [wPdfView setHorizontal:horizontal];
    
}

- (void)setOnChange:(RCTBubblingEventBlock)onChange
{
    
    [wPdfView setOnChange:onChange];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    NSLog(@"super bunds.size:%f,%f", self.bounds.size.width, self.bounds.size.height);
    
    [wPdfView updateBounds];

}


@end
