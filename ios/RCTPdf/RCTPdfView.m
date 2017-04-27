//
//  RCTPdfView.m
//  
//
//  Created by Wonday on 17/4/21.
//  Copyright (c) wonday.org All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>
#import <React/RCTLog.h>


#import "RCTPdfView.h"

@implementation RCTPdfView {

    CGPDFDocumentRef _pdfDoc;
    int _numberOfPages;
    
    int _offsetX;
    int _offsetY;
    int _isContiniousTap;
    int _oldPage;
    
    BOOL _isLoadCompleteNoticed;
    
}

- (instancetype)init
{
    _page = 1;
    _horizontal = TRUE;

    _numberOfPages = 0;
    _oldPage = 0;
    _offsetX = 0;
    _offsetY = 0;
    
    _isLoadCompleteNoticed = TRUE;
    _isContiniousTap = FALSE;
    
    if ((self = [super init])) {
        
        [self bindPan];
        [self bindPinch];
        [self bindTap];
        
    }
    
    return self;
}

- (void)setAsset:(NSString *)asset
{
    
    if (![asset isEqual:_asset]) {
        
        _asset = [asset copy];
        
        if (_asset == (id)[NSNull null] || _asset.length == 0) {
            
            NSLog(@"null asset");
            
        } else {
            
            NSLog(@"not null: %@", _asset);
            
            if (_pdfDoc != NULL) CGPDFDocumentRelease(_pdfDoc);
            
            CFURLRef pdfURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), (__bridge CFStringRef)_asset, NULL, NULL);
            _pdfDoc = CGPDFDocumentCreateWithURL(pdfURL);
            CFRelease(pdfURL);
            
            _numberOfPages = (int)CGPDFDocumentGetNumberOfPages(_pdfDoc);
            
            _isLoadCompleteNoticed = FALSE;
            
            [self setNeedsDisplay];
            
        }
    }

    
}

- (void)setPath:(NSString *)path
{
    
    if (![path isEqual:_path]) {
        
        _path = [path copy];
        
        if (_path == (id)[NSNull null] || _path.length == 0) {
            
            NSLog(@"null path");
            
        } else {
            
            NSLog(@"not null: %@", _path);
            
            if (_pdfDoc != NULL) CGPDFDocumentRelease(_pdfDoc);
            NSURL *pdfURL = [NSURL fileURLWithPath:_path];
            _pdfDoc = CGPDFDocumentCreateWithURL((__bridge CFURLRef) pdfURL);
            
            _numberOfPages = (int)CGPDFDocumentGetNumberOfPages(_pdfDoc);
            _isLoadCompleteNoticed = FALSE;

            [self setNeedsDisplay];
            
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
        
        _scale = scale;
        [self setNeedsDisplay];
        
    }
    
}

- (void)setHorizontal:(BOOL)horizontal
{
    
    if (horizontal != _horizontal) {
        
        NSLog(@"setHorizontal %d -> %d", _horizontal, horizontal);
        
        _horizontal = horizontal;
        _horizontal = TRUE;
        [self setNeedsDisplay];
        
    }
    
}

- (void)noticePageChanged {
    
    if(_onChange){
        
        NSLog(@"pageChanged,%d,%d", _page, _numberOfPages);
        
        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"pageChanged,%d,%d", _page, _numberOfPages]]});
        _isLoadCompleteNoticed = TRUE;
        
    }
    
}

- (void)noticeLoadComplete {
    
    if(_oldPage!=_page && _onChange){
        
        NSLog(@"loadComplete,%d", _numberOfPages);
        
        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"loadComplete,%d",_numberOfPages]]});
        _isLoadCompleteNoticed = TRUE;
        
    }
    
    _oldPage = _page;
    
}

- (void)drawRect:(CGRect)rect {
    
    if (_pdfDoc != NULL) {
        
        if (!_isLoadCompleteNoticed) {
            
            [self noticeLoadComplete];
            
        }
        

        if (_horizontal) {
            
            // recaculate offset and page
            int pageOffset = floor(_offsetX / (self.bounds.size.width * _scale));
            _offsetX = _offsetX - (self.bounds.size.width * _scale) * pageOffset;
            _page -= pageOffset;
            
            _page = _page < 1? 1 : _page;
            _page = _page > _numberOfPages ? _numberOfPages : _page;
            

            
            // control Y for not moving out
            if (_offsetY < (self.bounds.size.height * (1-_scale))){
                
                _offsetY = self.bounds.size.height * (1-_scale);
                
            }
            
            if (_offsetY > 0){
                
                _offsetY = 0;
                
            }
            
        } else {
            
            // recaculate offset and page
            int pageOffset = floor(_offsetY / (self.bounds.size.height * _scale));
            _offsetY = _offsetY - (self.bounds.size.height * _scale) * pageOffset;
            _page -= pageOffset;
            
            _page = _page < 1? 1 : _page;
            _page = _page > _numberOfPages ? _numberOfPages : _page;
            
            
            // control X for not moving out
            if (_offsetX < (self.bounds.size.width * (1-_scale))){
                
                _offsetX = self.bounds.size.width * (1-_scale);
                
            }
            
            if (_offsetX > 0){
                
                _offsetX = 0;
                
            }
            
        }
        
        NSLog(@"bunds.size:%f,%f", self.bounds.size.width, self.bounds.size.height);
        NSLog(@"page:%d scale:%f offset:%d,%d", _page, _scale, _offsetX, _offsetY);

        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Fill the background with white.
        CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
        CGContextFillRect(context, self.bounds);
        
        // PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system
        // before we start drawing.
        CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(_pdfDoc, _page);
        
        // draw current page
        if (pdfPage != NULL) {
            CGContextSaveGState(context);
            
            CGRect curPageBounds= self.bounds;
            curPageBounds.origin.x += _offsetX;
            curPageBounds.origin.y = (-1 * _offsetY) - (_scale-1) * self.bounds.size.height;
            
            CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFCropBox, curPageBounds, 0, true);
            CGContextConcatCTM(context, pdfTransform);
            
            // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
            CGContextScaleCTM(context, _scale, _scale);
            
            CGContextDrawPDFPage(context, pdfPage);
            CGContextRestoreGState(context);
            
            // draw previous page
            if (_page>1) {
                
                CGPDFPageRef pdfPrePage = CGPDFDocumentGetPage(_pdfDoc, _page-1);
                
                if (pdfPrePage != NULL) {
                    
                    CGContextSaveGState(context);
                    CGRect prePageBounds= curPageBounds;
                    if (_horizontal){
                        prePageBounds.origin.x -= prePageBounds.size.width*_scale;
                    } else {
                        prePageBounds.origin.y += prePageBounds.size.height*_scale;
                    }
                    
                    CGAffineTransform prePageTransform = CGPDFPageGetDrawingTransform(pdfPrePage, kCGPDFCropBox, prePageBounds, 0, true);
                    CGContextConcatCTM(context, prePageTransform);
                    
                    // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
                    CGContextScaleCTM(context, _scale, _scale);
                    
                    CGContextDrawPDFPage(context, pdfPrePage);
                    CGContextRestoreGState(context);
                }
            }

            // draw next page
            if (_page<_numberOfPages) {
                
                CGPDFPageRef pdfNextPage = CGPDFDocumentGetPage(_pdfDoc, _page+1);
                
                if (pdfNextPage != NULL) {
                    
                    CGContextSaveGState(context);
                    CGRect nextPageBounds= curPageBounds;
                    if (_horizontal){
                        nextPageBounds.origin.x += nextPageBounds.size.width*_scale;
                    } else {
                        nextPageBounds.origin.y -= nextPageBounds.size.height*_scale;
                    }
                    
                    CGAffineTransform nextTransform = CGPDFPageGetDrawingTransform(pdfNextPage, kCGPDFCropBox, nextPageBounds, 0, true);
                    CGContextConcatCTM(context, nextTransform);
                    
                    // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
                    CGContextScaleCTM(context, _scale, _scale);
                    
                    CGContextDrawPDFPage(context, pdfNextPage);
                    CGContextRestoreGState(context);
                }
            }

        }
    }
    
     [self noticePageChanged];
}

// Clean up.
- (void)dealloc {
    if(_pdfDoc != NULL) CGPDFDocumentRelease(_pdfDoc);
}


#pragma mark - GestureRecognize operation
/**
 *  Pan
 *
 *  @param recognizer
 */
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    
    _isContiniousTap = FALSE;
    
    [recognizer.view.superview bringSubviewToFront:recognizer.view];
    
    CGPoint translation = [recognizer translationInView:self];
    NSLog(@"translation %f,%f", translation.x, translation.y);
    
    _offsetX += translation.x;
    _offsetY += translation.y;
    
    
    // end animation
    while (recognizer.state == UIGestureRecognizerStateEnded) {
        
        
        CGPoint center = recognizer.view.center;
        NSLog(@"frame center:%f,%f, view center:%f,%f", (self.frame.size.width/2+self.frame.origin.x), (self.frame.size.height/2+self.frame.origin.y), self.center.x,self.center.y);
        
        CGPoint velocity = [recognizer velocityInView:self];

        if (_horizontal==TRUE) {
            
            if (abs((int)velocity.x) < 20) {
                break;
            }
            
        } else {
            
            if (abs((int)velocity.y) < 200) {
                break;
            }
            
        }
        
        CGPoint finalCenter = center;
        
        // set finalCenter to pre/next page center
        if (_horizontal==TRUE) {
            
            if (velocity.y > 0) {
                finalCenter.x += self.bounds.size.width * 1.5 * _scale;
            } else {
                finalCenter.x += -1 * self.bounds.size.width/2 * _scale;
            }
            
        } else {
            
            if (velocity.y > 0) {
                finalCenter.y += self.bounds.size.height * _scale;
            } else {
                finalCenter.y -= self.bounds.size.height * _scale;
            }
            
        }
        
        
        
        //use animation to slip to end
        [UIView animateWithDuration:1
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
                                     
                                 }
                                 
                             } else {
                                 
                                 if (velocity.y > 0) {
                                     
                                     _offsetY = 0;
                                     _page--;
                                     
                                 } else {
                                     
                                     _offsetY = 0;
                                     
                                 }
                                 
                             }

                             recognizer.view.center = center;
                             
                             [self setNeedsDisplay];
                         }];
        
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
- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    
    _isContiniousTap = FALSE;
    
    CGFloat scale = recognizer.scale;
    
    if ((scale * _scale) > 1) {
        
        _scale = scale * _scale;
        
        int touchCount = (int)recognizer.numberOfTouches;
        
        if (touchCount == 2) {
            
            CGPoint p1 = [recognizer locationOfTouch: 0 inView:self ];
            CGPoint p2 = [recognizer locationOfTouch: 1 inView:self ];
            float centerX = (p1.x+p2.x)/2;
            float centerY = (p1.y+p2.y)/2;
            
            _offsetX = centerX - (centerX - _offsetX) * scale;
            _offsetY = centerY - (centerY - _offsetY) * scale;
        }
        
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
- (void)handleTap:(UITapGestureRecognizer *)recognizer {

    if (_isContiniousTap) {
        
        _scale = _scale * 1.2;
        
    } else {
        
        _scale = 1.0;
        _offsetX = 0;
        _offsetY = 0;
        _isContiniousTap = TRUE;
        
    }
    
    [self setNeedsDisplay];
    
}


#pragma mark - bind recognizer
/**
 *  Bind Pan
 *
 *
 */
- (void)bindPan {
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
- (void)bindTap {
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handleTap:)];
    //trigger by one finger and double touch
    recognizer.numberOfTapsRequired = 2;
    recognizer.numberOfTouchesRequired = 1;
    
    [self addGestureRecognizer:recognizer];
    
}

@end
