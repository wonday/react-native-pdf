/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTPdfView.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <PDFKit/PDFKit.h>

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

#ifndef __OPTIMIZE__
// only output log when debug
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

// output log both debug and release
#define RLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

@implementation RCTPdfView
{
    PDFDocument *_pdfDocument;
    PDFView *_pdfView;
    float _fixScaleFactor;
    float _lastScale;
    bool _initialed;
    
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        // init and config PDFView
        _pdfView = [[PDFView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
        _pdfView.displayMode = kPDFDisplaySinglePageContinuous;
        _pdfView.autoScales = YES;
        _pdfView.displaysPageBreaks = YES;
        _pdfView.displayBox = kPDFDisplayBoxMediaBox;
        _pdfView.backgroundColor = [UIColor colorWithRed:0.875 green:0.875 blue:0.875 alpha:1.0]; //#EEE
        
        _fixScaleFactor = -1.0f;
        _lastScale = -1.0;
        _initialed = NO;
        
        [self addSubview:_pdfView];
        

        // register notification
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(onDocumentChanged:) name:PDFViewDocumentChangedNotification object:_pdfView];
        [center addObserver:self selector:@selector(onPageChanged:) name:PDFViewPageChangedNotification object:_pdfView];
        [center addObserver:self selector:@selector(onScaleChanged:) name:PDFViewScaleChangedNotification object:_pdfView];

        [self bindTap];
    }
    
    return self;
}

- (void)didSetProps:(NSArray<NSString *> *)changedProps
{
    long int count = [changedProps count];
    for (int i = 0 ; i < count; i++) {
        if ([[changedProps objectAtIndex:i] isEqualToString:@"path"]) {
            
            NSURL *fileURL = [NSURL fileURLWithPath:_path];
            
            if (_pdfDocument != Nil) {
                //Release old doc
                _pdfDocument = Nil;
            }
            
            _pdfDocument = [[PDFDocument alloc] initWithURL:fileURL];
            
            if (_pdfDocument) {
                
                //check need password or not
                if (_pdfDocument.isLocked && ![_pdfDocument unlockWithPassword:_password]) {
                    
                    _onChange(@{ @"message": @"error|Password required or incorrect password."});
                    
                    _pdfDocument = Nil;
                    [_pdfView goToPage:[_pdfDocument pageAtIndex:_page-1]];
                    
                    return;
                }
                
                _pdfView.document = _pdfDocument;
            } else {
                
                _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"error|Load pdf failed. path=%s",_path.UTF8String]]});
                
                _pdfDocument = Nil;
                return;
            }
        }
        
        if (_pdfDocument && ([[changedProps objectAtIndex:i] isEqualToString:@"path"] || [[changedProps objectAtIndex:i] isEqualToString:@"page"])) {
            [_pdfView goToPage:[_pdfDocument pageAtIndex:_page-1]];
        }
        
        if (_pdfDocument && ([[changedProps objectAtIndex:i] isEqualToString:@"path"] || [[changedProps objectAtIndex:i] isEqualToString:@"spacing"])) {
            if (_horizontal) {
                _pdfView.pageBreakMargins = UIEdgeInsetsMake(0,_spacing,0,0);
            } else {
                _pdfView.pageBreakMargins = UIEdgeInsetsMake(0,0,_spacing,0);
            }
        }
        
        if (_pdfDocument && ([[changedProps objectAtIndex:i] isEqualToString:@"path"] || [[changedProps objectAtIndex:i] isEqualToString:@"fitPolicy"])) {
            
            if (_initialed) {
                PDFPage *page = [_pdfDocument pageAtIndex:0];
                CGRect pageRect = [page boundsForBox:kPDFDisplayBoxMediaBox];
                
                if (_fitPolicy == 0) {
                    _fixScaleFactor = _pdfView.frame.size.width/pageRect.size.width;
                    _pdfView.minScaleFactor = _fixScaleFactor/2;
                    _pdfView.maxScaleFactor = _fixScaleFactor*3;
                    _pdfView.scaleFactor = _fixScaleFactor;
                } else if (_fitPolicy == 1) {
                    _fixScaleFactor = _pdfView.frame.size.height/pageRect.size.height;
                    _pdfView.minScaleFactor = _fixScaleFactor/2;
                    _pdfView.maxScaleFactor = _fixScaleFactor*3;
                    _pdfView.scaleFactor = _fixScaleFactor;
                } else {
                    float pageAspect = pageRect.size.width/pageRect.size.height;
                    float reactViewAspect = self.frame.size.width/self.frame.size.height;
                    if (reactViewAspect>pageAspect) {
                        _fixScaleFactor = self.frame.size.height/pageRect.size.height;
                        _pdfView.minScaleFactor = _fixScaleFactor/2;
                        _pdfView.maxScaleFactor = _fixScaleFactor*3;
                        _pdfView.scaleFactor = _fixScaleFactor;
                    } else {
                        _fixScaleFactor = self.frame.size.width/pageRect.size.width;
                        _pdfView.minScaleFactor = _fixScaleFactor;
                        _pdfView.maxScaleFactor = _fixScaleFactor*3;
                        _pdfView.scaleFactor = _fixScaleFactor;
                    }
                }
            }
            
        }
        
        if (_pdfDocument && ([[changedProps objectAtIndex:i] isEqualToString:@"path"] || [[changedProps objectAtIndex:i] isEqualToString:@"scale"])) {
            if (_fixScaleFactor > 0.0f) {
                _pdfView.scaleFactor = _scale * _fixScaleFactor;
            }
        }
        
        if (_pdfDocument && ([[changedProps objectAtIndex:i] isEqualToString:@"path"] || [[changedProps objectAtIndex:i] isEqualToString:@"horizontal"])) {
            if (_horizontal) {
                _pdfView.displayDirection = kPDFDisplayDirectionHorizontal;
                _pdfView.pageBreakMargins = UIEdgeInsetsMake(0,_spacing,0,0);
            } else {
                _pdfView.displayDirection = kPDFDisplayDirectionVertical;
                _pdfView.pageBreakMargins = UIEdgeInsetsMake(0,0,_spacing,0);
            }
        }
    }
    
    [_pdfView.layer setNeedsDisplay];
    [self setNeedsDisplay];
}


- (void)reactSetFrame:(CGRect)frame
{
    [super reactSetFrame:frame];
    
    
    PDFPage *page = [_pdfDocument pageAtIndex:0];
    CGRect pageRect = [page boundsForBox:kPDFDisplayBoxMediaBox];
    
    // some pdf with rotation, then adjust it
    if (page.rotation == 90 || page.rotation == 270) {
        pageRect = CGRectMake(0, 0, pageRect.size.height, pageRect.size.width);
    }
    
    if (_fitPolicy == 0) {
        _fixScaleFactor = frame.size.width/pageRect.size.width;
        _pdfView.minScaleFactor = _fixScaleFactor/2;
        _pdfView.maxScaleFactor = _fixScaleFactor*3;
        _pdfView.scaleFactor = _fixScaleFactor;
    } else if (_fitPolicy == 1) {
        _fixScaleFactor = frame.size.height/pageRect.size.height;
        _pdfView.minScaleFactor = _fixScaleFactor/2;
        _pdfView.maxScaleFactor = _fixScaleFactor*3;
        _pdfView.scaleFactor = _fixScaleFactor;
    } else {
        float pageAspect = pageRect.size.width/pageRect.size.height;
        float reactViewAspect = frame.size.width/frame.size.height;
        if (reactViewAspect>pageAspect) {
            _fixScaleFactor = frame.size.height/pageRect.size.height;
            _pdfView.minScaleFactor = _fixScaleFactor/2;
            _pdfView.maxScaleFactor = _fixScaleFactor*3;
            _pdfView.scaleFactor = _fixScaleFactor;
        } else {
            _fixScaleFactor = frame.size.width/pageRect.size.width;
            _pdfView.minScaleFactor = _fixScaleFactor/2;
            _pdfView.maxScaleFactor = _fixScaleFactor*3;
            _pdfView.scaleFactor = _fixScaleFactor;
        }
    }
    
    _pdfView.frame = frame;
    [_pdfView goToPage:[_pdfDocument pageAtIndex:_page-1]];
    
    _initialed = YES;
}

- (void)dealloc{
    
    _pdfDocument = Nil;
    _pdfView = Nil;
    
    //Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewDocumentChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewPageChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewScaleChangedNotification" object:nil];

}

#pragma mark notification process
- (void)onDocumentChanged:(NSNotification *)noti
{
    
    if (_pdfDocument) {
        unsigned long numberOfPages = _pdfDocument.pageCount;
        PDFPage *page = [_pdfDocument pageAtIndex:0];
        CGSize pageSize = [_pdfView rowSizeForPage:page];
        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"loadComplete|%lu|%f|%f", numberOfPages, pageSize.width, pageSize.height]]});
    }

}

- (void)onPageChanged:(NSNotification *)noti
{
    
    if (_pdfDocument) {
        PDFPage *currentPage = _pdfView.currentPage;
        unsigned long page = [_pdfDocument indexForPage:currentPage];
        unsigned long numberOfPages = _pdfDocument.pageCount;
        
        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"pageChanged|%lu|%lu", page+1, numberOfPages]]});
    }
    
}

- (void)onScaleChanged:(NSNotification *)noti
{

    if (_initialed) {
        if (_lastScale != _pdfView.scaleFactor/_fixScaleFactor) {
            _lastScale = _pdfView.scaleFactor/_fixScaleFactor;
            _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"scaleChanged|%f", _lastScale]]});
        }
    }
}

#pragma mark gesture process

/**
 *  Tap
 *  zoom reset or zoom in
 *
 *  @param recognizer
 */
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    
    // one tap add scale 1.2 times
    CGFloat scale = _pdfView.scaleFactor*1.2;
    
    if (scale>_pdfView.maxScaleFactor){
        scale = _fixScaleFactor;
    }
    
    _pdfView.scaleFactor = scale;
    
    [self setNeedsDisplay];
    
}

/**
 *  Single Tap
 *  stop zoom
 *
 *  @param recognizer
 */
- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    
    if (_pdfView.scaleFactor>1*_fixScaleFactor) {
        _pdfView.scaleFactor = 1.0*_fixScaleFactor;
        [self setNeedsDisplay];
    } else {
        CGPoint point = [sender locationInView:self];
        PDFPage *pdfPage = [_pdfView pageForPoint:point nearest:NO];
        if (pdfPage) {
            unsigned long page = [_pdfDocument indexForPage:pdfPage];
            _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"pageSingleTap|%lu", page+1]]});
        }
    }
    
}

/**
 *  Pinch
 *
 *
 *  @param recognizer
 */
-(void)handlePinch:(UIPinchGestureRecognizer *)sender{
    [self onScaleChanged:Nil];
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
    
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handlePinch:)];
    [self addGestureRecognizer:pinchRecognizer];
    pinchRecognizer.delegate = self;

    
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer

{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}



@end
