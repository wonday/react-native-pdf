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

@implementation WPdfView
{

    CGPDFDocumentRef _pdfDoc;
    int _numberOfPages;
    
    int _offsetX;
    int _offsetY;
    int _isContiniousTap;
    
    BOOL _isLoadCompleteNoticed;
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    
    if (self) {
        _page = 1;
        _horizontal = FALSE;
        _scale = 1;
        _spacing = 10;
        _password = @"";
        
        _numberOfPages = 0;
        _offsetX = 0;
        _offsetY = 0;

        
        _isLoadCompleteNoticed = TRUE;
        _isContiniousTap = FALSE;
        
        self.backgroundColor = UIColor.clearColor;

        [self bindPan];
        [self bindPinch];
        [self bindTap];
    }
    
    return self;
    
}

- (void)loadPdf:(NSString *)path withPassword:(NSString *)password
{
    
    if (_pdfDoc != NULL) CGPDFDocumentRelease(_pdfDoc);
    
    if (_path != nil && _path.length > 0 && _password != nil) {
        
        NSURL *pdfURL = [NSURL fileURLWithPath:_path];
        _pdfDoc = CGPDFDocumentCreateWithURL((__bridge CFURLRef) pdfURL);
        
        if (_pdfDoc != NULL && ![_password isEqualToString:@""]) {
            bool isUnlocked = CGPDFDocumentUnlockWithPassword(_pdfDoc, [_password UTF8String]);
            if (!isUnlocked) {
                if(_onChange){
                    ALog(@"error|load pdf failed.");
                    
                    _onChange(@{ @"message": @"error|unlock pdf failed."});
                    _isLoadCompleteNoticed = TRUE;
                    
                }
                return;
            }
        }
        
        if (_pdfDoc == NULL) {
            if(_onChange){
                ALog(@"error|load pdf failed.");
                
                _onChange(@{ @"message": @"error|load pdf failed."});
                _isLoadCompleteNoticed = TRUE;
                
            }
            return;
        }
        
        _numberOfPages = (int)CGPDFDocumentGetNumberOfPages(_pdfDoc);
        _isLoadCompleteNoticed = FALSE;
        
        [self setNeedsDisplay];
    }

    

    
}

- (void)setPath:(NSString *)path
{
    
    if (![path isEqual:_path]) {
        
        _path = [path copy];
        
        if (_path == nil || _path.length == 0) {
            
            DLog(@"null path");
            
        } else {
            
            [self loadPdf:_path withPassword:_password];
            
        }
    }
    
}

- (void)setPassword:(NSString *)password
{
    
    if (![password isEqual:_password]) {
        
        _password = [password copy];
        
        if (_password == nil || _password.length == 0) {
            
            DLog(@"null password");
            
        } else {
            
            [self loadPdf:_path withPassword:_password];
            
        }
    }
    
}

- (void)setPage:(int)page
{
    
    if (page != _page) {
        
        NSLog(@"setPage %d -> %d", _page, page);
        _page = page;
        [self setNeedsDisplay];
        
    }
    
}

- (void)setScale:(float)scale
{
    if (scale != _scale) {
        
        NSLog(@"setScale %f -> %f", _scale, scale);
        
        _offsetX = _offsetX / _scale * scale;
        _offsetY = _offsetY / _scale * scale;

        _scale = scale;
        
        [self updateBounds];
        
    }
    
}

- (void)setHorizontal:(BOOL)horizontal
{
    
    if (horizontal != _horizontal) {
        
        NSLog(@"setHorizontal %d -> %d", _horizontal, horizontal);
        
        _horizontal = horizontal;
        
        [self setNeedsDisplay];
        
    }
    
}

- (void)setSpacing:(int)spacing
{
    
    if (spacing != _spacing) {
        
        NSLog(@"setSpacing %d -> %d", _spacing, spacing);
        
        _spacing = spacing;
        
        [self setNeedsDisplay];
        
    }
    
}

- (void)noticePageChanged
{
    
    if(_onChange){
        
        DLog(@"pageChanged,%d,%d", _page, _numberOfPages);
        
        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"pageChanged|%d|%d", _page, _numberOfPages]]});
        _isLoadCompleteNoticed = TRUE;
        
    }
    
}

- (void)noticeLoadComplete
{
    static int _oldPage = 0;
    
    if(_oldPage!=_page && _onChange){
        
        DLog(@"loadComplete,%d", _numberOfPages);
        
        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"loadComplete|%d",_numberOfPages]]});
        _isLoadCompleteNoticed = TRUE;
        
    }
    
    _oldPage = _page;
    
}

- (void)drawRect:(CGRect)rect
{
    
    float pageWidth = 0;
    float pageHeight = 0;
       
    if (_pdfDoc != NULL) {
        
        if (!_isLoadCompleteNoticed) {
            
            [self noticeLoadComplete];
            
        }
        
        // calculate page size
        if (_horizontal==TRUE) {
            
            pageWidth = (self.bounds.size.width - _spacing * 2)/3;
            pageHeight = self.bounds.size.height;
            
        } else {
            
            pageWidth = self.bounds.size.width;
            pageHeight = (self.bounds.size.height - _spacing * 2)/3;
            
        }

        if (_horizontal) {
            
            // recaculate offset and page
            int pageOffset = (_offsetX>=0?1:-1) * floor(abs(_offsetX) / pageWidth);
            _offsetX = _offsetX - pageWidth * pageOffset;
            _page -= pageOffset;
            
            _page = _page < 1 ? 1 : _page;
            _page = _page > _numberOfPages ? _numberOfPages : _page;
            
            if (_page == 1 && _offsetX > 0) _offsetX = 0;
            if (_page == _numberOfPages && _offsetX < 0) _offsetX = 0;

            
            // control Y for not moving out
            if (_offsetY < (self.superview.bounds.size.height - pageHeight)){
                
                _offsetY = self.superview.bounds.size.height - pageHeight;
                
            }
            
            if (_offsetY > 0){
                
                _offsetY = 0;
                
            }
            
        } else {
            
            // recaculate offset and page
            int pageOffset = (_offsetY>=0?1:-1) * floor(abs(_offsetY) / pageHeight);
            _offsetY = _offsetY - pageHeight * pageOffset;
            _page -= pageOffset;
            
            _page = _page < 1 ? 1 : _page;
            _page = _page > _numberOfPages ? _numberOfPages : _page;
            
            if (_page == 1 && _offsetY > 0) _offsetY = 0;
            if (_page == _numberOfPages && _offsetY < 0) _offsetY = 0;
            
            
            // control X for not moving out
            if (_offsetX < (self.superview.bounds.size.width - pageWidth)){
                
                _offsetX = self.superview.bounds.size.width - pageWidth;
                
            }
            
            if (_offsetX > 0){
                
                _offsetX = 0;
                
            }
            
        }
        
        DLog(@"bunds.size:%f,%f", self.bounds.size.width, self.bounds.size.height);
        DLog(@"page:%d scale:%f offset:%d,%d", _page, _scale, _offsetX, _offsetY);

        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system
        // before we start drawing.
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(_pdfDoc, _page);
        
        // draw current page
        if (pdfPage != NULL) {
            CGContextSaveGState(context);
            
            CGRect curPageBounds= CGRectMake(0, 0, pageWidth, pageHeight);
            
            // caculate offset
            curPageBounds.origin.x += _offsetX;
            curPageBounds.origin.y += (-1 * _offsetY) - pageHeight;

            // Fill the background with white.
            CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
            CGContextFillRect(context, curPageBounds);
            
            CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFCropBox, curPageBounds, 0, true);
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
                        prePageBounds.origin.x -= pageWidth + _spacing;
                    } else {
                        prePageBounds.origin.y += pageHeight + _spacing;
                    }
                    
                    // Fill the background with white.
                    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
                    CGContextFillRect(context, prePageBounds);
                    
                    CGAffineTransform prePageTransform = CGPDFPageGetDrawingTransform(pdfPrePage, kCGPDFCropBox, prePageBounds, 0, true);
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
                        
                        nextPageBounds.origin.x += pageWidth + _spacing;
                        
                    } else {
                        
                        nextPageBounds.origin.y -= pageHeight + _spacing;
                        
                    }

                    // Fill the background with white.
                    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
                    CGContextFillRect(context, nextPageBounds);
                    
                    CGAffineTransform nextTransform = CGPDFPageGetDrawingTransform(pdfNextPage, kCGPDFCropBox, nextPageBounds, 0, true);
                    CGContextConcatCTM(context, nextTransform);
                    
                    CGContextDrawPDFPage(context, pdfNextPage);
                    CGContextRestoreGState(context);
                }
            }

        }
    }
    
     [self noticePageChanged];
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
    
    if (_horizontal == TRUE) {
        
        bounds.origin.x = -1 * self.superview.bounds.size.width *_scale;
        bounds.size.width = self.superview.bounds.size.width * 3 * _scale + _spacing * 2;
        bounds.size.height = self.superview.bounds.size.height * _scale;
        
    } else {
        
        bounds.origin.y = -1 * self.superview.bounds.size.height * _scale;
        bounds.size.width = self.superview.bounds.size.width * _scale;
        bounds.size.height = self.superview.bounds.size.height * 3 * _scale + _spacing * 2;
        
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
    
    _isContiniousTap = FALSE;
    
    [recognizer.view.superview bringSubviewToFront:recognizer.view];
    
    CGPoint translation = [recognizer translationInView:self];
    NSLog(@"translation %f,%f", translation.x, translation.y);
    
    _offsetX += translation.x;
    _offsetY += translation.y;
    
    
    // end animation
    while (recognizer.state == UIGestureRecognizerStateEnded) {
        
        CGPoint velocity = [recognizer velocityInView:self];

        // if low velocity not start end animation, only do a drag/move
        if (_horizontal==TRUE) {
            
            if (abs((int)velocity.x) < 200) {
                break;
            }
            
        } else {
            
            if (abs((int)velocity.y) < 200) {
                break;
            }
            
        }
        
        
        CGPoint center = recognizer.view.center;
        CGPoint finalCenter = center;
        
        // set finalCenter to do an animation
        if (_horizontal==TRUE) {
            
            if (velocity.x > 0) {
                
                finalCenter.x += self.bounds.size.width/3;
                
            } else {
                
                finalCenter.x -= self.bounds.size.width/3;
                
            }
            
        } else {
            
            if (velocity.y > 0) {
                
                finalCenter.y += self.bounds.size.height/3;
                
            } else {
                
                finalCenter.y -= self.bounds.size.height/3;
                
            }
            
        }
        
        
        
        //use animation to slip to end
        [UIView animateWithDuration:0.6
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             recognizer.view.center = finalCenter;
                         }
                         completion:^(BOOL finished){
                             
                             if (_horizontal == TRUE) {
                                 
                                 if (velocity.x > 0) {
                                     
                                     _offsetX = 0;
                                     _page--;
                                     
                                 } else {
                                     
                                     _offsetX = 0;
                                     _page++;
                                     
                                 }
                                 
                             } else {
                                 
                                 if (velocity.y > 0) {
                                     
                                     _offsetY = 0;
                                     _page--;
                                     
                                 } else {
                                     
                                     _offsetY = 0;
                                     _page++;
                                     
                                 }
                                 
                             }

                             // reset center;
                             recognizer.view.center = center;
                             
                             [self setNeedsDisplay];
                         }];
        // break while
        break;
    }

    
    
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
    
    _isContiniousTap = FALSE;
    
    CGFloat scale = recognizer.scale;
    
    if ((scale * _scale) > 1) {
        
        int touchCount = (int)recognizer.numberOfTouches;
        
        if (touchCount == 2) {
            
            CGPoint p1 = [recognizer locationOfTouch: 0 inView:self ];
            CGPoint p2 = [recognizer locationOfTouch: 1 inView:self ];
            float centerX = (p1.x+p2.x)/2;
            float centerY = (p1.y+p2.y)/2;
            
            _offsetX = centerX - (centerX - _offsetX) * scale;
            _offsetY = centerY - (centerY - _offsetY) * scale;
        
            _scale = scale * _scale;
        
            [self updateBounds];
            
        }

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

    if (_isContiniousTap) {
        
        _scale = _scale * 1.2;
        
    } else {
        
        _scale = 1.0;
        _offsetX = 0;
        _offsetY = 0;
        _isContiniousTap = TRUE;
        
        
    }
    
    [self updateBounds];
    
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
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleTap:)];
    //trigger by one finger and double touch
    recognizer.numberOfTapsRequired = 2;
    recognizer.numberOfTouchesRequired = 1;
    
    [self addGestureRecognizer:recognizer];
    
}

@end
