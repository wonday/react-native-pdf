/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
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

#ifndef __OPTIMIZE__
// only output log when debug
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

// output log both debug and release
#define ALog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#define MIN_SCALE 1    //min scale

@implementation WPdfView
{
    
    CGPDFDocumentRef _pdfDoc;
    int _numberOfPages;
    int _isContiniousTap;
    BOOL _isLoadCompleteNoticed;
    
    CGRect _pdfPageRect;
    double _basePageWidth;
    double _basePageHeight;
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    
    if (self) {
        _page = 1;
        _horizontal = FALSE;
        _fitWidth = FALSE;
        _scale = 1.0f;
        _spacing = 10;
        _password = @"";
        
        _numberOfPages = 0;
        _isContiniousTap = TRUE;
        
        _pdfPageRect = CGRectMake(0, 0, 0, 0);
        _basePageWidth = 0;
        _basePageHeight = 0;
        
        self.backgroundColor = UIColor.clearColor;
        
        [self bindPan];
        [self bindPinch];
        [self bindTap];
    }
    
    return self;
    
}

- (void)setPath:(NSString *)path
{
    
    if (![path isEqual:_path]) {
        
        _path = [path copy];
        
        if (_path == nil || _path.length == 0) {
            
            DLog(@"null path");
            
        }
    }
    
}

- (void)setPassword:(NSString *)password
{
    
    if (![password isEqual:_password]) {
        
        _password = [password copy];
        
        if (_password == nil || _password.length == 0) {
            
            DLog(@"null password");
            
        }
    }
    
}

- (void)setPage:(int)page
{
    
    if (page != _page) {
        
        NSLog(@"setPage %d -> %d", _page, page);
        _page = page;
    }
    
}

- (void)setScale:(float)scale
{
    
    scale = scale < MIN_SCALE ? MIN_SCALE : scale;
    
    if (scale != _scale) {
        
        NSLog(@"setScale %f -> %f", _scale, scale);
        
        _scale = scale;
        
        self.transform = CGAffineTransformMakeScale(_scale, _scale);
        
    }
    
}

- (void)setHorizontal:(BOOL)horizontal
{
    
    if (horizontal != _horizontal) {
        
        NSLog(@"setHorizontal %d -> %d", _horizontal, horizontal);
        
        _horizontal = horizontal;
        
    }
    
}

- (void)setFitWidth:(BOOL)fitWidth
{
    
    if (fitWidth != _fitWidth) {
        
        NSLog(@"setFitWidth %d -> %d", _fitWidth, fitWidth);
        
        _fitWidth = fitWidth;
    }
    
}

- (void)setSpacing:(int)spacing
{
    
    if (spacing != _spacing) {
        
        NSLog(@"setSpacing %d -> %d", _spacing, spacing);
        
        _spacing = spacing;
        
    }
    
}

- (void) loadPdf {
    if (_path != nil && _path.length != 0) {
        if (_pdfDoc != NULL) CGPDFDocumentRelease(_pdfDoc);
        
        NSURL *pdfURL = [NSURL fileURLWithPath:_path];
        _pdfDoc = CGPDFDocumentCreateWithURL((__bridge CFURLRef) pdfURL);
        
        if (_pdfDoc != NULL && CGPDFDocumentIsEncrypted(_pdfDoc)) {
            bool isUnlocked = CGPDFDocumentUnlockWithPassword(_pdfDoc, [_password UTF8String]);
            if (!isUnlocked) {
                if(_onChange){
                    ALog(@"error|Password required or incorrect password.");
                    
                    _onChange(@{ @"message": @"error|Password required or incorrect password."});
                    _isLoadCompleteNoticed = TRUE;
                    
                }
                return;
            }
            
        }
        
        if (_pdfDoc == NULL) {
            if(_onChange){
                ALog(@"error|load pdf failed.");
                
                _onChange(@{ @"message": @"error|Load pdf failed."});
                _isLoadCompleteNoticed = TRUE;
                
            }
            return;
        }
        
        _numberOfPages = (int)CGPDFDocumentGetNumberOfPages(_pdfDoc);
        
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(_pdfDoc, 1);
        _pdfPageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFTrimBox);
        
        [self noticeLoadComplete];
        [self setNeedsLayout];
        [self setNeedsDisplay];
        
    } else {
        DLog(@"null path");
    }
}


- (void)noticePageChanged
{
    
    if(_onChange){
        static int lastPage = -1;
        
        if (lastPage!=_page) {
            
            DLog(@"pageChanged,%d,%d", _page, _numberOfPages);
            
            _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"pageChanged|%d|%d", _page, _numberOfPages]]});
            _isLoadCompleteNoticed = TRUE;
            lastPage = _page;
        }
    }
    
}

- (void)noticeLoadComplete
{
    
    DLog(@"loadComplete,%d", _numberOfPages);
    
    _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"loadComplete|%d",_numberOfPages]]});
    
}

- (void)drawRect:(CGRect)rect
{
    
    if (_pdfDoc != NULL) {
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system
        // before we start drawing.
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGRect basePageRect = CGRectMake(0, 0, _basePageWidth, _basePageHeight);
        
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(_pdfDoc, _page);
        
        
        // draw current page
        if (pdfPage != NULL) {
            CGContextSaveGState(context);
            
            CGRect curPageBounds= CGRectMake(0, 0, basePageRect.size.width, basePageRect.size.height);
            
            // caculate offset
            curPageBounds.origin.x += 0;
            curPageBounds.origin.y -= basePageRect.size.height;
            
            
            // Fill the background with white.
            CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
            CGContextFillRect(context, curPageBounds);
            
            CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFTrimBox, curPageBounds, 0, true);
            CGContextConcatCTM(context, pdfTransform);
            
            CGContextDrawPDFPage(context, pdfPage);
            
            
            CGContextRestoreGState(context);
            
            // draw previous page
            if (_page > 1) {
                
                CGPDFPageRef pdfPrePage = CGPDFDocumentGetPage(_pdfDoc, _page-1);
                
                if (pdfPrePage != NULL) {
                    
                    CGContextSaveGState(context);
                    CGRect prePageBounds= curPageBounds;
                    if (_horizontal){
                        prePageBounds.origin.x -= basePageRect.size.width + _spacing;
                    } else {
                        prePageBounds.origin.y += basePageRect.size.height + _spacing;
                    }
                    
                    // Fill the background with white.
                    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
                    CGContextFillRect(context, prePageBounds);
                    
                    CGAffineTransform prePageTransform = CGPDFPageGetDrawingTransform(pdfPrePage, kCGPDFTrimBox, prePageBounds, 0, true);
                    CGContextConcatCTM(context, prePageTransform);
                    
                    CGContextDrawPDFPage(context, pdfPrePage);
                    
                    
                    
                    CGContextRestoreGState(context);
                }
            }
            
            // draw next page
            if (_page < _numberOfPages) {
                
                CGPDFPageRef pdfNextPage = CGPDFDocumentGetPage(_pdfDoc, _page+1);
                
                if (pdfNextPage != NULL) {
                    
                    CGContextSaveGState(context);
                    CGRect nextPageBounds= curPageBounds;
                    if (_horizontal){
                        
                        nextPageBounds.origin.x += basePageRect.size.width + _spacing;
                        
                    } else {
                        
                        nextPageBounds.origin.y -= basePageRect.size.height + _spacing;
                        
                    }
                    
                    // Fill the background with white.
                    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
                    CGContextFillRect(context, nextPageBounds);
                    
                    CGAffineTransform nextTransform = CGPDFPageGetDrawingTransform(pdfNextPage, kCGPDFTrimBox, nextPageBounds, 0, true);
                    CGContextConcatCTM(context, nextTransform);
                    
                    CGContextDrawPDFPage(context, pdfNextPage);
                    CGContextRestoreGState(context);
                }
            }
            
        }
        
        [self noticePageChanged];
    }
    
}

/**
 *  reset bounds with scale
 *
 *
 */
- (void)updateBounds
{
    
    CGRect bounds = self.superview.bounds;
    if (bounds.size.width == 0 || bounds.size.height == 0) return;
    
    _basePageWidth = self.superview.bounds.size.width;
    _basePageHeight = self.superview.bounds.size.height;
    
    if (_fitWidth && _basePageHeight<_pdfPageRect.size.height*_basePageWidth/_pdfPageRect.size.width) {
        _basePageHeight = _pdfPageRect.size.height*_basePageWidth/_pdfPageRect.size.width;
    }
    
    if (_horizontal == TRUE) {
        
        bounds.origin.x = - _basePageWidth - _spacing;
        bounds.size.width = _basePageWidth*3 + _spacing*2;
        bounds.size.height = _basePageHeight;
        
    } else {
        
        bounds.origin.y = - _basePageHeight - _spacing;
        bounds.size.width = _basePageWidth;
        bounds.size.height = _basePageHeight*3 + _spacing*2;
        
    }
    
    // we will set a 3-pages rect to frame and bounds
    [self setFrame:bounds];
    [self setBounds:bounds];
    [self setNeedsDisplay];
    
}

// Clean up.
- (void)dealloc
{
    if(_pdfDoc != NULL) CGPDFDocumentRelease(_pdfDoc);
}


#pragma mark - GestureRecognize operation
/**
 *  Pan
 *
 *  @param recognizer
 */
- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    //stop animation
    [recognizer.view.layer removeAllAnimations];
    
    _isContiniousTap = FALSE;
    
    [recognizer.view.superview bringSubviewToFront:recognizer.view];
    
    CGPoint translation = [recognizer translationInView:self];
    //    NSLog(@"translation %f,%f", translation.x, translation.y);
    
    
    CGPoint center = recognizer.view.center;
    CGPoint finalCenter = center;
    
    finalCenter.x += translation.x;
    finalCenter.y += translation.y;
    
    float pageHeight = _basePageHeight*_scale;
    float pageWidth = _basePageWidth*_scale;
    
    
    // end animation
    while (_numberOfPages > 1
           && recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint velocity = [recognizer velocityInView:self];
        
        // if low velocity not start end animation, only do a drag/move
        if (_horizontal==TRUE) {
            
            if (abs((int)velocity.x) < 200) {
                break;
            }
            
            if (_page<=2 && velocity.x>0) break;
            if (_page>=_numberOfPages-1 && velocity.x<0) break;
            
            if (_page<=3 && velocity.x>0) {
                velocity.x = pageWidth;
            }
            
            if (_numberOfPages-_page<=3 && velocity.x<0) {
                velocity.x = -pageWidth;
            }
            
        } else {
            
            if (abs((int)velocity.y) < 200) {
                break;
            }
            
            if (_page<=2 && velocity.y>0) break;
            if (_page>=_numberOfPages-1 && velocity.y<0) break;
            
            if (_page<=3 && velocity.y>0){
                velocity.y = pageHeight;
            }
            
            if (_numberOfPages-_page<=3 && velocity.y<0) {
                velocity.y = -pageHeight;
            }
            
        }
        
        
        
        // set finalCenter to do an animation
        if (_horizontal==TRUE) {
            
            if (velocity.x>2*pageWidth) velocity.x = 2*pageWidth;
            if (velocity.x<-2*pageWidth) velocity.x = -2*pageWidth;
            
            finalCenter.x += velocity.x;
            
        } else {
            
            if (velocity.y>2*pageHeight) velocity.y = 2*pageHeight;
            if (velocity.y<-2*pageHeight) velocity.y = -2*pageHeight;

            finalCenter.y += velocity.y;
            
        }


        //use animation to slip to end
        [UIView animateWithDuration:1.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             recognizer.view.center = finalCenter;
                         }
                         completion:^(BOOL finished){
                             [self setNeedsDisplay];
                         }];
        // break while
        break;
    }
    
    if (_horizontal) {
        
        // control X for not moving out
        if (_page == 1) {
            
            if (finalCenter.x > pageWidth/2) finalCenter.x = pageWidth/2;
            
        }
        
        
        if (_page == _numberOfPages) {
            
            if (finalCenter.x < self.superview.bounds.size.width - pageWidth/2) finalCenter.x = self.superview.bounds.size.width - pageWidth/2;
            
        }
        
        // control Y for not moving out
        if (finalCenter.y < (self.superview.bounds.size.height - pageHeight/2)){
            
            finalCenter.y = self.superview.bounds.size.height - pageHeight/2;
            
        }
        
        
        if (finalCenter.y > pageHeight/2){
            
            finalCenter.y = pageHeight/2;
            
        }

        while (_page>1 && finalCenter.x>self.bounds.size.width/2) {
            finalCenter.x -= pageWidth;
            _page --;
        }
        
        while (_page<_numberOfPages && finalCenter.x<(pageWidth-self.bounds.size.width/2)) {
            finalCenter.x += pageWidth;
            _page ++;
        }
        
    } else {
        
        // control Y for not moving out
        if (_page == 1) {
            
            if (finalCenter.y > pageHeight/2) finalCenter.y = pageHeight/2;
        }
        
        
        if (_page == _numberOfPages) {
            
            if (finalCenter.y < self.superview.bounds.size.height - pageHeight/2) finalCenter.y = self.superview.bounds.size.height - pageHeight/2;
            
        }

        // control X for not moving out
        if (finalCenter.x < (self.superview.bounds.size.width - pageWidth/2)){
            
            finalCenter.x = self.superview.bounds.size.width - pageWidth/2;
            
        }
        
        
        if (finalCenter.x > pageWidth/2){
            
            finalCenter.x = pageWidth/2;
            
        }

        while (_page>1 && finalCenter.y>self.bounds.size.height/2) {
            finalCenter.y -= pageHeight;
            _page --;
        }
        
        while (_page<_numberOfPages && finalCenter.y<(pageHeight-self.bounds.size.height/2)) {
            finalCenter.y += pageHeight;
            _page ++;
        }
        
    }
    
    
    // set center;
    recognizer.view.center = finalCenter;
    
    
    [recognizer setTranslation:CGPointZero inView:self];
    
    [self setNeedsDisplay];
    
}

/**
 *  Pinch
 *
 *  @param recognizer
 */
- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
    //stop animation
    [recognizer.view.layer removeAllAnimations];
    
    _isContiniousTap = FALSE;
    
    CGFloat scale = recognizer.scale;
    
    if (scale * _scale < MIN_SCALE) scale = MIN_SCALE / _scale;
    
    int touchCount = (int)recognizer.numberOfTouches;
    
    if (touchCount == 2) {
        
        CGPoint p1 = [recognizer locationOfTouch: 0 inView:self ];
        CGPoint p2 = [recognizer locationOfTouch: 1 inView:self ];
        
        CGPoint finalCenter = recognizer.view.center;
        finalCenter.x = (p1.x+p2.x)/2;
        finalCenter.y = (p1.y+p2.y)/2;
        
        _scale = scale * _scale;
        
        self.transform = CGAffineTransformMakeScale(_scale, _scale);
        recognizer.view.center = finalCenter;
        
        [self setNeedsDisplay];
        
    }
    
    recognizer.scale = 1.0;
    
}

/**
 *  Tap
 *  zoom reset or in
 *
 *  @param recognizer
 */
- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    //stop animation
    [recognizer.view.layer removeAllAnimations];
    
    if (_isContiniousTap) {
        
        // one tap add scale 1.2 times
        CGFloat scale = 1.2;
        
        _scale = _scale * scale;
        
        self.transform = CGAffineTransformMakeScale(_scale, _scale);
        
    } else {
        
        _scale = 1.0;
        _isContiniousTap = TRUE;
        _fitWidth = FALSE;
        
        self.transform = CGAffineTransformMakeScale(_scale, _scale);
        
        [self setNeedsLayout];
        
    }
    
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
    
    //stop animation
    [recognizer.view.layer removeAllAnimations];

    _isContiniousTap = FALSE;
}

#pragma mark - bind recognizer
/**
 *  Bind Pan
 *
 *
 */
- (void)bindPan
{
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handlePan:)];
    [self addGestureRecognizer:recognizer];
    
}


/**
 *  Bind pinch
 *
 *
 */
- (void)bindPinch {
    UIPinchGestureRecognizer *recognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handlePinch:)];
    [self addGestureRecognizer:recognizer];
    
}

/**
 *  Bind tap
 *
 *
 */
- (void)bindTap
{
    UITapGestureRecognizer *doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleTap:)];
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
