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

#define SCREEN_BUFFER_NUM 7.0f
#define DEFAULT_SPACING 10
#define INVALID_TARGETCONTENTOFFSET -100000.0f

@implementation WPdfView
{
    
    CGPDFDocumentRef _pdfDoc;
    int _numberOfPages;
    
    CGRect _pdfPageRect;
    CGSize _pageCanvasSize;
    CGPoint _pageCanvasOffset;
    CGFloat _pageOffset;
    CGFloat _targetContentOffset;

    double _numberOfBufferPages;
    BOOL _isScrollToUpOrLeft; // TRUE:Up/Left FALSE:Down/Right
    BOOL _needFixPageOffset;
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        
        _page = 1;
        _pageOffset = 0;

        _horizontal = NO;
        _fitWidth = NO;
        _spacing = DEFAULT_SPACING;
        _password = @"";
        
        _numberOfPages = 0;
        _numberOfBufferPages = SCREEN_BUFFER_NUM;
        
        _pdfPageRect = CGRectZero;
        _pageCanvasSize = CGSizeZero;
        _pageCanvasOffset = CGPointZero;
        _targetContentOffset = INVALID_TARGETCONTENTOFFSET;
        
        _isScrollToUpOrLeft = NO;
        _needFixPageOffset = NO;
        
    }
    
    return self;
    
}

- (void)setPath:(NSString *)path
{
    
    if (![path isEqual:_path]) {
        
        _path = [path copy];
        _page = 1;
        _pageOffset = 0;
        
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
    
    if (page != _page+_pageOffset) {
        
        DLog(@"setPage %d -> %d", _page, page);
        _page = page;
        _pageOffset = 0;
        
    }
    
}

- (void)setHorizontal:(BOOL)horizontal
{
    
    if (horizontal != _horizontal) {
        
        DLog(@"setHorizontal %d -> %d", _horizontal, horizontal);
        _horizontal = horizontal;
        
    }
    
}

- (void)setFitWidth:(BOOL)fitWidth
{
    
    if (fitWidth != _fitWidth) {
        
        DLog(@"setFitWidth %d -> %d", _fitWidth, fitWidth);
        _fitWidth = fitWidth;
        
    }
    
}

- (void)setSpacing:(int)spacing
{
    
    if (spacing != _spacing) {
        
        DLog(@"setSpacing %d -> %d", _spacing, spacing);
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

                }
                return;
            }
            
        }
        
        if (_pdfDoc == NULL) {
            if(_onChange){
                
                ALog(@"error|load pdf failed. path=%s", _path.UTF8String);
                _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"error|Load pdf failed. path=%s",_path.UTF8String]]});
                
            }
            return;
        }
        
        _numberOfPages = (int)CGPDFDocumentGetNumberOfPages(_pdfDoc);
        
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(_pdfDoc, 1);
        _pdfPageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFTrimBox);
        
        DLog(@"loadComplete,%d", _numberOfPages);
        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"loadComplete|%d",_numberOfPages]]});
        
    } else {
        
        ALog(@"error|load pdf failed. path=null");
        
        if(_onChange){
            _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"error|Load pdf failed. path=null"]]});
        }
        return;
    }
}


- (void)noticePageChanged
{
    
    if(_onChange){
        static int lastPage = -1;
        
        if (_horizontal) {
            _pageOffset = ((((UIScrollView *)self.superview).contentOffset.x+((UIScrollView *)self.superview).bounds.size.width/2)/((UIScrollView *)self.superview).zoomScale-((UIScrollView *)self.superview).bounds.size.width/2)/(_pageCanvasSize.width+_spacing);
        } else {
            _pageOffset = ((((UIScrollView *)self.superview).contentOffset.y+((UIScrollView *)self.superview).bounds.size.height/2)/((UIScrollView *)self.superview).zoomScale-((UIScrollView *)self.superview).bounds.size.height/2)/(_pageCanvasSize.height+_spacing);
        }
        
        if (_pageOffset<0) _pageOffset = 0;
        
        if (floor(_pageOffset)+_page!=lastPage) {
            lastPage = floor(_pageOffset)+_page;
            _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"pageChanged|%d|%d", lastPage, _numberOfPages]]});
            DLog(@"pageChanged,%d,%d", lastPage, _numberOfPages);
        }
    }
    
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
                pageBounds = CGRectMake(pageOffset*(_pageCanvasSize.width + _spacing) + _pageCanvasOffset.x,
                                         - _pageCanvasSize.height - _pageCanvasOffset.y,
                                        _pageCanvasSize.width,
                                        _pageCanvasSize.height);

        } else {
                pageBounds = CGRectMake(_pageCanvasOffset.x,
                                        -pageOffset*(_pageCanvasSize.height + _spacing) - _pageCanvasSize.height - _pageCanvasOffset.y,
                                        _pageCanvasSize.width,
                                        _pageCanvasSize.height);
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
        
        
        // PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system before drawing.
        CGContextScaleCTM(context, 1.0, -1.0);
        
        for(int i=0; i<_numberOfBufferPages; i++) [self drawPage:i :context];

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
    if (bounds.size.width==0 || bounds.size.height==0 || _pdfPageRect.size.width==0 || _pdfPageRect.size.height==0) return;
    bounds.origin.x = 0;
    bounds.origin.y = 0;
    
    
    // caculate page canvas size
    _pageCanvasSize.width = self.superview.bounds.size.width;
    _pageCanvasSize.height = self.superview.bounds.size.height;
    
    if (_fitWidth ) {
        _pageCanvasSize.width = self.superview.bounds.size.width;
        _pageCanvasSize.height = _pdfPageRect.size.height*_pageCanvasSize.width/_pdfPageRect.size.width;
        
    } else {
        if (_pageCanvasSize.height/_pageCanvasSize.width>_pdfPageRect.size.height/_pdfPageRect.size.width) {
            _pageCanvasSize.width = self.superview.bounds.size.width;
            _pageCanvasSize.height = ceil(_pdfPageRect.size.height*self.superview.bounds.size.width/_pdfPageRect.size.width);
        } else {
            _pageCanvasSize.width = ceil(_pdfPageRect.size.width*self.superview.bounds.size.height/_pdfPageRect.size.height);
            _pageCanvasSize.height = self.superview.bounds.size.height;
        }
    }
    
    
    // caculate bounds size
    if (_horizontal) {
        _numberOfBufferPages = floor((SCREEN_BUFFER_NUM*self.superview.bounds.size.width+_spacing)/(_pageCanvasSize.width+_spacing));
        _numberOfBufferPages = _numberOfBufferPages<_numberOfPages?_numberOfBufferPages:_numberOfPages;
        bounds.size.width = _pageCanvasSize.width*_numberOfBufferPages + _spacing*(_numberOfBufferPages-1);
        bounds.size.height = _pageCanvasSize.height;
    } else {
        _numberOfBufferPages = floor((SCREEN_BUFFER_NUM*self.superview.bounds.size.height+_spacing)/(_pageCanvasSize.height+_spacing));
        _numberOfBufferPages = _numberOfBufferPages<_numberOfPages?_numberOfBufferPages:_numberOfPages;
        bounds.size.width = _pageCanvasSize.width;
        bounds.size.height = _pageCanvasSize.height*_numberOfBufferPages + _spacing*(_numberOfBufferPages-1);
    }
    
    
    // adjust page canvas offset when can be drawn in one screen
    _pageCanvasOffset = CGPointZero;
    if (bounds.size.width<self.superview.bounds.size.width) {
        _pageCanvasOffset.x = (self.superview.bounds.size.width - bounds.size.width)/2;
        bounds.size.width = self.superview.bounds.size.width;
    }
    
    if (bounds.size.height<self.superview.bounds.size.height) {
        _pageCanvasOffset.y = (self.superview.bounds.size.height - bounds.size.height)/2;
        bounds.size.height = self.superview.bounds.size.height;
    }
    
    
    // save zoomScale
    CGFloat zoomScale = ((UIScrollView *)self.superview).zoomScale;
    ((UIScrollView *)self.superview).zoomScale = 1;
    
    [self setFrame:bounds];
    [self setBounds:bounds];
    ((UIScrollView *)self.superview).contentSize = bounds.size;
    
    // fix contentOffset for head/foot page
    CGPoint contentOffset;
    if (_horizontal) {
        contentOffset.x = (_pageCanvasSize.width+_spacing)*_pageOffset;
        contentOffset.y = 0;
        if (_page + _numberOfBufferPages>_numberOfPages){
            contentOffset.x += (_page + _numberOfBufferPages - _numberOfPages - 1)*(_pageCanvasSize.width+_spacing);
            float maxContentOffsetX = ((UIScrollView*)self.superview).contentSize.width - self.superview.bounds.size.width;
            contentOffset.x = contentOffset.x>maxContentOffsetX?maxContentOffsetX:contentOffset.x;
            ((UIScrollView *)self.superview).contentOffset = contentOffset;
            _page = _numberOfPages - _numberOfBufferPages + 1;
        } else {
            ((UIScrollView *)self.superview).contentOffset = contentOffset;
            [self fixPageOffset];
        }
    } else {
        contentOffset.x = 0;
        contentOffset.y = (_pageCanvasSize.height+_spacing)*_pageOffset;
        if (_page + _numberOfBufferPages>_numberOfPages){
            contentOffset.y += (_page + _numberOfBufferPages - _numberOfPages - 1)*(_pageCanvasSize.height+_spacing);
            float maxContentOffsetY = ((UIScrollView *)self.superview).contentSize.height - self.superview.bounds.size.height;
            contentOffset.y = contentOffset.y>maxContentOffsetY?maxContentOffsetY:contentOffset.y;
            ((UIScrollView *)self.superview).contentOffset = contentOffset;
            _page = _numberOfPages - _numberOfBufferPages + 1;
        } else {
            ((UIScrollView *)self.superview).contentOffset = contentOffset;
            [self fixPageOffset];
        }
    }
    
    // restore zoomScale
    ((UIScrollView *)self.superview).zoomScale = zoomScale;
    [self setNeedsDisplay];
}

// Clean up.
- (void)dealloc
{
    if(_pdfDoc != NULL) CGPDFDocumentRelease(_pdfDoc);
}

- (void)fixPageOffset
{
    _needFixPageOffset = NO;
    
    CGPoint contentOffset = ((UIScrollView *)self.superview).contentOffset;
    
    if(_horizontal) {
        while (!_isScrollToUpOrLeft && _page>1 && contentOffset.x < (_pageCanvasSize.width+_spacing)*floor(_numberOfBufferPages/2)*((UIScrollView *)self.superview).zoomScale) {
            _page --;
            contentOffset.x += (_pageCanvasSize.width+_spacing)*((UIScrollView *)self.superview).zoomScale;
        }
        
        while (_isScrollToUpOrLeft && _page<_numberOfPages - _numberOfBufferPages + 1 && contentOffset.x > (_pageCanvasSize.width+_spacing)*floor(_numberOfBufferPages/2)*((UIScrollView *)self.superview).zoomScale) {
            _page ++;
            contentOffset.x -= (_pageCanvasSize.width+_spacing)*((UIScrollView *)self.superview).zoomScale;
        }
    } else {

        while (!_isScrollToUpOrLeft && _page>1 && contentOffset.y < (_pageCanvasSize.height+_spacing)*floor(_numberOfBufferPages/2)*((UIScrollView *)self.superview).zoomScale) {
            _page --;
            contentOffset.y += (_pageCanvasSize.height+_spacing)*((UIScrollView *)self.superview).zoomScale;
        }

        while (_isScrollToUpOrLeft && _page<_numberOfPages - _numberOfBufferPages + 1 && contentOffset.y > (_pageCanvasSize.height+_spacing)*floor(_numberOfBufferPages/2)*((UIScrollView *)self.superview).zoomScale) {
            _page ++;
            contentOffset.y -= (_pageCanvasSize.height+_spacing)*((UIScrollView *)self.superview).zoomScale;
        }
    }
    
    ((UIScrollView *)self.superview).contentOffset = contentOffset;
    ((UIScrollView *)self.superview).decelerationRate = UIScrollViewDecelerationRateNormal;
    [self setNeedsDisplay];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (_needFixPageOffset) {
        
        [self fixPageOffset];
        
    }
}

- (void)scrollViewWillEndDragging:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGSize contentSize = ((UIScrollView *)self.superview).contentSize;

    if (_horizontal) {
        if (velocity.x ==0) {
            
            _targetContentOffset = INVALID_TARGETCONTENTOFFSET;
            [self fixPageOffset];
            
        }else if (velocity.x < 0) {
            
            _isScrollToUpOrLeft = NO;
            _needFixPageOffset = YES;
            
            if (targetContentOffset->x <= 0 ) {
                _targetContentOffset = targetContentOffset->x;
            }
            
        } else {
            
            _isScrollToUpOrLeft = YES;
            _needFixPageOffset = YES;
            
            if (targetContentOffset->x >= contentSize.width - self.superview.bounds.size.width && _page<_numberOfPages - _numberOfBufferPages + 1) {
                _targetContentOffset = targetContentOffset->x;
            }
            
        }
    } else {
        if (velocity.y == 0) {
            
            _targetContentOffset = INVALID_TARGETCONTENTOFFSET;
            [self fixPageOffset];
            
        }else if (velocity.y < 0) {
            
            _isScrollToUpOrLeft = NO;
            _needFixPageOffset = YES;
            
            if (targetContentOffset->y <= 0 ) {
                _targetContentOffset = targetContentOffset->y;
            }
            
        } else {
            
            _isScrollToUpOrLeft = YES;
            _needFixPageOffset = YES;
            
            if (targetContentOffset->y >= contentSize.height - self.superview.bounds.size.height && _page<_numberOfPages - _numberOfBufferPages + 1) {
                _targetContentOffset = targetContentOffset->y;
            }
            
        }
    }

}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_horizontal) {
        if (_targetContentOffset!=INVALID_TARGETCONTENTOFFSET && fabs(_targetContentOffset-((UIScrollView *)self.superview).contentOffset.x)<=100) {
            ((UIScrollView *)self.superview).decelerationRate = UIScrollViewDecelerationRateFast;
            _targetContentOffset = INVALID_TARGETCONTENTOFFSET;
        }
    } else {
        if (_targetContentOffset!=INVALID_TARGETCONTENTOFFSET && fabs(_targetContentOffset-((UIScrollView *)self.superview).contentOffset.y)<=100) {
            ((UIScrollView *)self.superview).decelerationRate = UIScrollViewDecelerationRateFast;
            _targetContentOffset = INVALID_TARGETCONTENTOFFSET;
        }
    }
    [self noticePageChanged];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self fixPageOffset];
}
@end
