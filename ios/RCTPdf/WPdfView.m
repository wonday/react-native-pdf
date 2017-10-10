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
- (void)drawPage:(int) pageOffset
                :(CGContextRef) context
{
    if (_page+pageOffset<1 || _page+pageOffset>_numberOfPages) return;
    
    CGPDFPageRef pdfPage = CGPDFDocumentGetPage(_pdfDoc, _page+pageOffset);
    
    if (pdfPage != NULL) {
        
        CGContextSaveGState(context);
        CGRect pageBounds;
        
        if (_horizontal){
            if (_numberOfPages*_basePageWidth+(_numberOfPages-1)*_spacing<self.superview.bounds.size.width) {
                pageBounds = CGRectMake(_basePageWidth/2 - self.superview.bounds.size.width/2 + pageOffset*(_basePageWidth + _spacing),
                                        self.superview.bounds.size.height/2 - _basePageHeight/2  - _basePageHeight,
                                        _basePageWidth,
                                        _basePageHeight);
            } else {
                pageBounds = CGRectMake(pageOffset*(_basePageWidth + _spacing),
                                        self.superview.bounds.size.height/2 - _basePageHeight/2  - _basePageHeight,
                                        _basePageWidth,
                                        _basePageHeight);
            }

        } else {
            if (_numberOfPages*_basePageHeight+(_numberOfPages-1)*_spacing<self.superview.bounds.size.height) {
                pageBounds = CGRectMake(self.superview.bounds.size.width/2 - _basePageWidth/2,
                                        _basePageHeight/2 - self.superview.bounds.size.height/2 - pageOffset*(_basePageHeight + _spacing) - _basePageHeight,
                                        _basePageWidth,
                                        _basePageHeight);
            } else {
                pageBounds = CGRectMake(self.superview.bounds.size.width/2 - _basePageWidth/2,
                                        -pageOffset*(_basePageHeight + _spacing) - _basePageHeight,
                                        _basePageWidth,
                                        _basePageHeight);
            }
        }
        
        // Fill the background with white.
        CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
        CGContextFillRect(context, pageBounds);
        
        CGAffineTransform pageTransform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFTrimBox, pageBounds, 0, true);
        CGContextConcatCTM(context, pageTransform);
        
        CGContextDrawPDFPage(context, pdfPage);
        CGContextRestoreGState(context);
    }
}

- (void)drawRect:(CGRect)rect
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (_pdfDoc != NULL) {
        
        
        // PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system
        // before we start drawing.
        CGContextScaleCTM(context, 1.0, -1.0);
        
        [self drawPage:-2 :context];
        [self drawPage:-1 :context];
        [self drawPage:0 :context];
        [self drawPage:1 :context];
        [self drawPage:2 :context];

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
    
//    if (_fitWidth ) {
//        _basePageWidth = self.superview.bounds.size.width;
//        _basePageHeight = _pdfPageRect.size.height*_basePageWidth/_pdfPageRect.size.width;
//    } else {
//        if (_basePageHeight/_basePageWidth>_pdfPageRect.size.height/_pdfPageRect.size.width) {
//            _basePageWidth = self.superview.bounds.size.width;
//            _basePageHeight = _pdfPageRect.size.height*self.superview.bounds.size.width/_pdfPageRect.size.width;
//        } else {
//            _basePageWidth = _pdfPageRect.size.width*self.superview.bounds.size.height/_pdfPageRect.size.height;
//            _basePageHeight = self.superview.bounds.size.height;
//        }
//    }
    
    if (_horizontal) {
        
        bounds.origin.x = - (_basePageWidth + _spacing)*2;
        bounds.origin.y = 0;
        bounds.size.width = _basePageWidth*5 + _spacing*4;
        bounds.size.height = _basePageHeight;
        
    } else {
        
        bounds.origin.x = 0;
        bounds.origin.y = - (_basePageHeight + _spacing)*2;
        bounds.size.width = _basePageWidth;
        bounds.size.height = _basePageHeight*5 + _spacing*4;
        
    }
    
    // we will set a 5-pages rect to frame and bounds
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
    CGPoint finalCenter = recognizer.view.center;
    
    
    // end animation
    if(recognizer.state == UIGestureRecognizerStateEnded) {
        
        // animation duration seconds
        const int animationDuration = 1.5;
        float inertialDistance = 0;
        
        CGPoint velocity = [recognizer velocityInView:self];
        
        
        if (_horizontal) {
            
            // if speed less then 100 then not start animation
            if (abs((int)velocity.x) > 100) {
                
                // default inertial distance
                inertialDistance = velocity.x*animationDuration;
                
                if (velocity.x>0){
                    if (finalCenter.x+inertialDistance>self.bounds.size.width*_scale/2) {
                        finalCenter.x = self.bounds.size.width*_scale/2;
                    } else {
                        finalCenter.x += inertialDistance;
                    }
                } else if (velocity.x<0) {
                    if (finalCenter.x+inertialDistance<self.superview.bounds.size.width - self.bounds.size.width*_scale/2) {
                        finalCenter.x = self.superview.bounds.size.width - self.bounds.size.width*_scale/2;
                    } else {
                        finalCenter.x += inertialDistance;
                    }
                }
                
                if (_page==1 && finalCenter.x > self.bounds.size.width*_scale/2 - (_basePageWidth + _spacing)*_scale*2) {
                    finalCenter.x = self.bounds.size.width*_scale/2 - (_basePageWidth + _spacing)*_scale*2;
                }
                
                if (_page==2 && finalCenter.x > self.bounds.size.width*_scale/2 - (_basePageWidth + _spacing)*_scale) {
                    finalCenter.x = self.bounds.size.width*_scale/2 - (_basePageWidth + _spacing)*_scale;
                }
                
                if (_numberOfPages==1 && finalCenter.x <  self.superview.bounds.size.width + (_basePageWidth+_spacing)*_scale*2 - self.bounds.size.width*_scale/2) {
                    finalCenter.x = self.superview.bounds.size.width + (_basePageWidth+_spacing)*_scale*2 - self.bounds.size.width*_scale/2;
                }
                
                if (_numberOfPages==2 && finalCenter.x < self.superview.bounds.size.width + (_basePageWidth+_spacing)*_scale - self.bounds.size.width*_scale/2) {
                    finalCenter.x = self.superview.bounds.size.width + (_basePageWidth+_spacing)*_scale - self.bounds.size.width*_scale/2;
                }
                
                //use animation to slip to end
                [UIView animateWithDuration:animationDuration
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     recognizer.view.center = finalCenter;
                                 }
                                 completion:^(BOOL finished){
                                     [self fixPageOffset];
                                 }];
                
            } else {
                // set center;
                finalCenter.x += translation.x;
                finalCenter.y += translation.y;
                recognizer.view.center = finalCenter;
                
                [self fixPageOffset];
            }

            
        } else {
            
            // if speed less then 100 then not start animation
            if (abs((int)velocity.y) > 100) {
                
                // default inertial distance
                inertialDistance = velocity.y*animationDuration;

                if (velocity.y>0){
                    if (finalCenter.y+inertialDistance>self.bounds.size.height*_scale/2) {
                        finalCenter.y = self.bounds.size.height*_scale/2;
                    } else {
                        finalCenter.y += inertialDistance;
                    }
                } else if (velocity.y<0) {
                    if (finalCenter.y+inertialDistance<self.superview.bounds.size.height - self.bounds.size.height*_scale/2) {
                        finalCenter.y = self.superview.bounds.size.height - self.bounds.size.height*_scale/2;
                    } else {
                        finalCenter.y += inertialDistance;
                    }
                }
                
                if (_page==1 && finalCenter.y > self.bounds.size.height*_scale/2 - (_basePageHeight + _spacing)*_scale*2) {
                    finalCenter.y = self.bounds.size.height*_scale/2 - (_basePageHeight + _spacing)*_scale*2;
                }
                
                if (_page==2 && finalCenter.y > self.bounds.size.height*_scale/2 - (_basePageHeight + _spacing)*_scale) {
                    finalCenter.y = self.bounds.size.height*_scale/2 - (_basePageHeight + _spacing)*_scale;
                }
                
                if (_numberOfPages==1 && finalCenter.y <  self.superview.bounds.size.height + (_basePageHeight+_spacing)*_scale*2 - self.bounds.size.height*_scale/2) {
                    finalCenter.y = self.superview.bounds.size.height + (_basePageHeight+_spacing)*_scale*2 - self.bounds.size.height*_scale/2;
                }
                
                if (_numberOfPages==2 && finalCenter.y < self.superview.bounds.size.height + (_basePageHeight+_spacing)*_scale - self.bounds.size.height*_scale/2) {
                    finalCenter.y = self.superview.bounds.size.height + (_basePageHeight+_spacing)*_scale - self.bounds.size.height*_scale/2;
                }

                //use animation to slip to end
                [UIView animateWithDuration:animationDuration
                                      delay:0
                                    options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                                     recognizer.view.center = finalCenter;
                                 }
                                 completion:^(BOOL finished){
                                     [self fixPageOffset];
                                 }];
            
            } else {
                // set center;
                finalCenter.x += translation.x;
                finalCenter.y += translation.y;
                recognizer.view.center = finalCenter;
                
                [self fixPageOffset];
            }
        }


    } else {
        // set center;
        finalCenter.x += translation.x;
        finalCenter.y += translation.y;
        recognizer.view.center = finalCenter;
    
        [self fixPageOffset];
    }
    
    
    [recognizer setTranslation:CGPointZero inView:self];
    
    [self setNeedsDisplay];
    
}

- (void)fixPageOffset
{

    CGPoint finalCenter = self.center;
    
    if (_horizontal) {
        if (_page==1 && finalCenter.x > self.bounds.size.width*_scale/2 - (_basePageWidth + _spacing)*_scale*2) {
            finalCenter.x = self.bounds.size.width*_scale/2 - (_basePageWidth + _spacing)*_scale*2;
        }
        
        if (_page==2 && finalCenter.x > self.bounds.size.width*_scale/2 - (_basePageWidth + _spacing)*_scale) {
            finalCenter.x = self.bounds.size.width*_scale/2 - (_basePageWidth + _spacing)*_scale;
        }
        
        if (_numberOfPages==1 && finalCenter.x <  self.superview.bounds.size.width + (_basePageWidth+_spacing)*_scale*2 - self.bounds.size.width*_scale/2) {
            finalCenter.x = self.superview.bounds.size.width + (_basePageWidth+_spacing)*_scale*2 - self.bounds.size.width*_scale/2;
        }
        
        if (_numberOfPages==2 && finalCenter.x < self.superview.bounds.size.width + (_basePageWidth+_spacing)*_scale - self.bounds.size.width*_scale/2) {
            finalCenter.x = self.superview.bounds.size.width + (_basePageWidth+_spacing)*_scale - self.bounds.size.width*_scale/2;
        }
    } else {
        if (_page==1 && finalCenter.y > self.bounds.size.height*_scale/2 - (_basePageHeight + _spacing)*_scale*2) {
            finalCenter.y = self.bounds.size.height*_scale/2 - (_basePageHeight + _spacing)*_scale*2;
        }
        
        if (_page==2 && finalCenter.y > self.bounds.size.height*_scale/2 - (_basePageHeight + _spacing)*_scale) {
            finalCenter.y = self.bounds.size.height*_scale/2 - (_basePageHeight + _spacing)*_scale;
        }
        
        if (_numberOfPages==1 && finalCenter.y <  self.superview.bounds.size.height + (_basePageHeight+_spacing)*_scale*2 - self.bounds.size.height*_scale/2) {
            finalCenter.y = self.superview.bounds.size.height + (_basePageHeight+_spacing)*_scale*2 - self.bounds.size.height*_scale/2;
        }
        
        if (_numberOfPages==2 && finalCenter.y < self.superview.bounds.size.height + (_basePageHeight+_spacing)*_scale - self.bounds.size.height*_scale/2) {
            finalCenter.y = self.superview.bounds.size.height + (_basePageHeight+_spacing)*_scale - self.bounds.size.height*_scale/2;
        }
    }
    
    
    
    // control X for not moving out
    if (finalCenter.x > self.bounds.size.width*_scale/2) {
        finalCenter.x = self.bounds.size.width*_scale/2;
    }
    
    if (finalCenter.x < self.superview.bounds.size.width - self.bounds.size.width*_scale/2) {
        finalCenter.x = self.superview.bounds.size.width - self.bounds.size.width*_scale/2;
    }
    
    
    // control y for not moving out
    if (finalCenter.y > self.bounds.size.height*_scale/2) {
        finalCenter.y = self.bounds.size.height*_scale/2;
    }
    
    if (finalCenter.y < self.superview.bounds.size.height - self.bounds.size.height*_scale/2) {
        finalCenter.y = self.superview.bounds.size.height - self.bounds.size.height*_scale/2;
    }
    
    // fix page offset
    if (_horizontal) {
        
        while (_page>1 && finalCenter.x>=self.bounds.size.width*_scale/2 - ((_basePageWidth+_spacing)*_scale*2-self.superview.bounds.size.width)) {
            finalCenter.x -= (_basePageWidth+_spacing)*_scale;
            _page --;
        }
        
        while (_page<_numberOfPages-2 && finalCenter.x<(((_basePageWidth+_spacing)*_scale*2+self.superview.bounds.size.width)-self.bounds.size.width*_scale/2)) {
            finalCenter.x += (_basePageWidth+_spacing)*_scale;
            _page ++;
        }
        
    } else {
        
        while (_page>1 && finalCenter.y>=self.bounds.size.height*_scale/2 - ((_basePageHeight+_spacing)*_scale*2-self.superview.bounds.size.height)) {
            finalCenter.y -= (_basePageHeight+_spacing)*_scale;
            _page --;
        }

        while (_page<_numberOfPages-2 && finalCenter.y<(((_basePageHeight+_spacing)*_scale*2+self.superview.bounds.size.height)-self.bounds.size.height*_scale/2)) {
            finalCenter.y += (_basePageHeight+_spacing)*_scale;
            _page ++;
        }
        
    }
    
    
    self.center = finalCenter;
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
    _scale = scale * _scale;
    
    int touchCount = (int)recognizer.numberOfTouches;
    
    if (touchCount == 2) {
        
        CGPoint p1 = [recognizer locationOfTouch: 0 inView:self ];
        CGPoint p2 = [recognizer locationOfTouch: 1 inView:self ];
        
        CGPoint finalCenter = recognizer.view.center;
        CGPoint pCenter;
        pCenter.x = (p1.x+p2.x)/2;
        pCenter.y = (p1.y+p2.y)/2;
        
        finalCenter.x = scale*(finalCenter.x - pCenter.x) + pCenter.x;
        finalCenter.y = scale*(finalCenter.y - pCenter.y) + pCenter.y;
        self.center = finalCenter;
        self.transform = CGAffineTransformMakeScale(_scale, _scale);
        
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
        
        CGPoint pCenter = [recognizer locationInView:self];
        CGPoint finalCenter = self.center;
        
        finalCenter.x = scale*(finalCenter.x - pCenter.x) + pCenter.x;
        finalCenter.y = scale*(finalCenter.y - pCenter.y) + pCenter.y;
        self.center = finalCenter;
        self.transform = CGAffineTransformMakeScale(_scale, _scale);
        
    } else {
        
        _scale = 1.0;
        _isContiniousTap = TRUE;
        _fitWidth = FALSE;
        
        self.transform = CGAffineTransformMakeScale(_scale, _scale);
        
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
