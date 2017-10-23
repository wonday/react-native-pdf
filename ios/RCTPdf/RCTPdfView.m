/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
    BOOL _needUpdateBounds;
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = UIColor.grayColor;
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.userInteractionEnabled = YES;
        self.clipsToBounds = YES;
        self.delegate = self;
        self.minimumZoomScale = 1.0;
        self.maximumZoomScale = 3.0;
        self.bouncesZoom = NO;
        self.bounces = NO;
        
        // fix statusbar effect when statusbar show/hide
        if (@available(iOS 11.0, *)) {
            self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        } else {
            // Fallback on earlier versions
        }

        _needUpdateBounds = NO;
        
        wPdfView = [[WPdfView alloc] initWithFrame:self.bounds];
        [self addSubview:wPdfView];
        
        [self bindTap];
    }
    return self;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    
    return wPdfView;
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(CGFloat)scale
{
   
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [wPdfView scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{

    [wPdfView scrollViewWillEndDragging:velocity targetContentOffset:targetContentOffset];
       
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{

    [wPdfView scrollViewDidScroll:scrollView];
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [wPdfView scrollViewDidEndDecelerating:scrollView];
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

    self.zoomScale = scale;

}

- (void)setHorizontal:(BOOL)horizontal
{
    
    [wPdfView setHorizontal:horizontal];
    
}

- (void)setFitWidth:(BOOL)fitWidth
{
    
    [wPdfView setFitWidth:fitWidth];
    
}

- (void)setSpacing:(int)spacing
{
    
    [wPdfView setSpacing:spacing];
    
}

- (void)setPassword:(NSString *)password
{
    
    [wPdfView setPassword:password];
    
}

- (void)setOnChange:(RCTBubblingEventBlock)onChange
{
    
    [wPdfView setOnChange:onChange];
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (self.bounds.size.width>0 && self.bounds.size.height>0 && _needUpdateBounds) {
        [wPdfView updateBounds];
        _needUpdateBounds = NO;
    }
}

- (void)didSetProps:(NSArray<NSString *> *)changedProps
{
    [wPdfView loadPdf];
    _needUpdateBounds = YES;
    [self setNeedsLayout];
}

/**
 *  Tap
 *  zoom reset or in
 *
 *  @param recognizer
 */
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    
    // one tap add scale 1.2 times
    CGFloat scale = self.zoomScale*1.2;
    if (scale>self.maximumZoomScale) scale = 1;
    self.zoomScale = scale;
    _fitWidth = NO;
    
    [self setNeedsDisplay];
    
}

/**
 *  Single Tap
 *  stop zoom
 *
 *  @param recognizer
 */
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    
    if (self.zoomScale>1) {
        self.zoomScale = 1.0;
        _fitWidth = NO;
        [self setNeedsDisplay];
    }
    
}

/**
 *  Bind tap
 *
 *
 */
- (void)bindTap
{
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleDoubleTap:)];
    //trigger by one finger and double touch
    doubleTapRecognizer.numberOfTapsRequired = 2;
    doubleTapRecognizer.numberOfTouchesRequired = 1;
    
    [self addGestureRecognizer:doubleTapRecognizer];
    
    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleSingleTap:)];
    //trigger by one finger and one touch
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    
    [self addGestureRecognizer:singleTapRecognizer];
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
    
}
@end
