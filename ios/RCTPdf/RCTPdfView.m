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

const float MAX_SCALE = 3.0f;
const float MIN_SCALE = 1.0f;

@implementation RCTPdfView
{
    PDFDocument *_pdfDocument;
    PDFView *_pdfView;
    PDFOutline *root;
    float _fixScaleFactor;
    bool _initialed;
    NSArray<NSString *> *_changedProps;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        _page = 1;
        _scale = 1;
        _minScale = MIN_SCALE;
        _maxScale = MAX_SCALE;
        _horizontal = NO;
        _enablePaging = NO;
        _enableRTL = NO;
        _enableAnnotationRendering = YES;
        _fitPolicy = 2;
        _spacing = 10;
        _singlePage = NO;

        // init and config PDFView
        _pdfView = [[PDFView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
        _pdfView.displayMode = kPDFDisplaySinglePageContinuous;
        _pdfView.autoScales = YES;
        _pdfView.displaysPageBreaks = YES;
        _pdfView.displayBox = kPDFDisplayBoxCropBox;
        _pdfView.backgroundColor = [UIColor clearColor];

        _fixScaleFactor = -1.0f;
        _initialed = NO;
        _changedProps = NULL;

        [self addSubview:_pdfView];


        // register notification
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(onDocumentChanged:) name:PDFViewDocumentChangedNotification object:_pdfView];
        [center addObserver:self selector:@selector(onPageChanged:) name:PDFViewPageChangedNotification object:_pdfView];
        [center addObserver:self selector:@selector(onScaleChanged:) name:PDFViewScaleChangedNotification object:_pdfView];

        [[_pdfView document] setDelegate: self];
        [_pdfView setDelegate: self];


        [self bindTap];
    }

    return self;
}

- (void)PDFViewWillClickOnLink:(PDFView *)sender withURL:(NSURL *)url
{
    NSString *_url = url.absoluteString;
    _onChange(@{ @"message":
                     [[NSString alloc] initWithString:
                      [NSString stringWithFormat:
                       @"linkPressed|%s", _url.UTF8String]] });
}

- (void)didSetProps:(NSArray<NSString *> *)changedProps
{
    if (!_initialed) {

        _changedProps = changedProps;

    } else {

        if ([changedProps containsObject:@"path"]) {

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
                    return;
                }

                _pdfView.document = _pdfDocument;
            } else {

                _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"error|Load pdf failed. path=%s",_path.UTF8String]]});

                _pdfDocument = Nil;
                return;
            }
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"spacing"])) {
            if (_horizontal) {
                _pdfView.pageBreakMargins = UIEdgeInsetsMake(0,_spacing,0,0);
                if (_spacing==0) {
                    if (@available(iOS 12.0, *)) {
                        _pdfView.pageShadowsEnabled = NO;
                    }
                } else {
                    if (@available(iOS 12.0, *)) {
                        _pdfView.pageShadowsEnabled = YES;
                    }
                }
            } else {
                _pdfView.pageBreakMargins = UIEdgeInsetsMake(0,0,_spacing,0);
                if (_spacing==0) {
                    if (@available(iOS 12.0, *)) {
                        _pdfView.pageShadowsEnabled = NO;
                    }
                } else {
                    if (@available(iOS 12.0, *)) {
                        _pdfView.pageShadowsEnabled = YES;
                    }
                }
            }
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"enableRTL"])) {
            _pdfView.displaysRTL = _enableRTL;
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"enableAnnotationRendering"])) {
            if (!_enableAnnotationRendering) {
                for (unsigned long i=0; i<_pdfView.document.pageCount; i++) {
                    PDFPage *pdfPage = [_pdfView.document pageAtIndex:i];
                    for (unsigned long j=0; j<pdfPage.annotations.count; j++) {
                        pdfPage.annotations[j].shouldDisplay = _enableAnnotationRendering;
                    }
                }
            }
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"fitPolicy"] || [changedProps containsObject:@"minScale"] || [changedProps containsObject:@"maxScale"])) {

            PDFPage *pdfPage = [_pdfDocument pageAtIndex:_pdfDocument.pageCount-1];
            CGRect pdfPageRect = [pdfPage boundsForBox:kPDFDisplayBoxCropBox];

            // some pdf with rotation, then adjust it
            if (pdfPage.rotation == 90 || pdfPage.rotation == 270) {
                pdfPageRect = CGRectMake(0, 0, pdfPageRect.size.height, pdfPageRect.size.width);
            }

            if (_fitPolicy == 0) {
                _fixScaleFactor = self.frame.size.width/pdfPageRect.size.width;
                _pdfView.scaleFactor = _scale * _fixScaleFactor;
                _pdfView.minScaleFactor = _fixScaleFactor*_minScale;
                _pdfView.maxScaleFactor = _fixScaleFactor*_maxScale;
            } else if (_fitPolicy == 1) {
                _fixScaleFactor = self.frame.size.height/pdfPageRect.size.height;
                _pdfView.scaleFactor = _scale * _fixScaleFactor;
                _pdfView.minScaleFactor = _fixScaleFactor*_minScale;
                _pdfView.maxScaleFactor = _fixScaleFactor*_maxScale;
            } else {
                float pageAspect = pdfPageRect.size.width/pdfPageRect.size.height;
                float reactViewAspect = self.frame.size.width/self.frame.size.height;
                if (reactViewAspect>pageAspect) {
                    _fixScaleFactor = self.frame.size.height/pdfPageRect.size.height;
                    _pdfView.scaleFactor = _scale * _fixScaleFactor;
                    _pdfView.minScaleFactor = _fixScaleFactor*_minScale;
                    _pdfView.maxScaleFactor = _fixScaleFactor*_maxScale;
                } else {
                    _fixScaleFactor = self.frame.size.width/pdfPageRect.size.width;
                    _pdfView.scaleFactor = _scale * _fixScaleFactor;
                    _pdfView.minScaleFactor = _fixScaleFactor*_minScale;
                    _pdfView.maxScaleFactor = _fixScaleFactor*_maxScale;
                }
            }

        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"scale"])) {
            _pdfView.scaleFactor = _scale * _fixScaleFactor;
            if (_pdfView.scaleFactor>_pdfView.maxScaleFactor) _pdfView.scaleFactor = _pdfView.maxScaleFactor;
            if (_pdfView.scaleFactor<_pdfView.minScaleFactor) _pdfView.scaleFactor = _pdfView.minScaleFactor;
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"horizontal"])) {
            if (_horizontal) {
                _pdfView.displayDirection = kPDFDisplayDirectionHorizontal;
                _pdfView.pageBreakMargins = UIEdgeInsetsMake(0,_spacing,0,0);
            } else {
                _pdfView.displayDirection = kPDFDisplayDirectionVertical;
                _pdfView.pageBreakMargins = UIEdgeInsetsMake(0,0,_spacing,0);
            }
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"enablePaging"])) {
            if (_enablePaging) {
                [_pdfView usePageViewController:YES withViewOptions:@{UIPageViewControllerOptionSpineLocationKey:@(UIPageViewControllerSpineLocationMin),UIPageViewControllerOptionInterPageSpacingKey:@(_spacing)}];
            } else {
                [_pdfView usePageViewController:NO withViewOptions:Nil];
            }
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"singlePage"])) {
            if (_singlePage) {
                _pdfView.displayMode = kPDFDisplaySinglePage;
                _pdfView.userInteractionEnabled = NO;
            } else {
                _pdfView.displayMode = kPDFDisplaySinglePageContinuous;
                _pdfView.userInteractionEnabled = YES;
            }
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"enablePaging"] || [changedProps containsObject:@"horizontal"] || [changedProps containsObject:@"page"])) {

            PDFPage *pdfPage = [_pdfDocument pageAtIndex:_page-1];
            if (pdfPage) {
                CGRect pdfPageRect = [pdfPage boundsForBox:kPDFDisplayBoxCropBox];

                // some pdf with rotation, then adjust it
                if (pdfPage.rotation == 90 || pdfPage.rotation == 270) {
                    pdfPageRect = CGRectMake(0, 0, pdfPageRect.size.height, pdfPageRect.size.width);
                }

                CGPoint pointLeftTop = CGPointMake(0, pdfPageRect.size.height);
                PDFDestination *pdfDest = [[PDFDestination alloc] initWithPage:pdfPage atPoint:pointLeftTop];
                [_pdfView goToDestination:pdfDest];
                _pdfView.scaleFactor = _fixScaleFactor*_scale;
            }
        }

        _pdfView.backgroundColor = [UIColor clearColor];
        [_pdfView layoutDocumentView];
        [self setNeedsDisplay];
    }
}


- (void)reactSetFrame:(CGRect)frame
{
    [super reactSetFrame:frame];
    _pdfView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);

    NSMutableArray *mProps = [_changedProps mutableCopy];
    if (_initialed) {
        [mProps removeObject:@"path"];
    }
    _initialed = YES;

    [self didSetProps:mProps];
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
        PDFPage *page = [_pdfDocument pageAtIndex:_pdfDocument.pageCount-1];
        CGSize pageSize = [_pdfView rowSizeForPage:page];
        NSString *jsonString = [self getTableContents];

        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"loadComplete|%lu|%f|%f|%@", numberOfPages, pageSize.width, pageSize.height,jsonString]]});
    }

}

-(NSString *) getTableContents
{

    NSMutableArray<PDFOutline *> *arrTableOfContents = [[NSMutableArray alloc] init];

    if (_pdfDocument.outlineRoot) {

        PDFOutline *currentRoot = _pdfDocument.outlineRoot;
        NSMutableArray<PDFOutline *> *stack = [[NSMutableArray alloc] init];

        [stack addObject:currentRoot];

        while (stack.count > 0) {

            PDFOutline *currentOutline = stack.lastObject;
            [stack removeLastObject];

            if (currentOutline.label.length > 0){
                [arrTableOfContents addObject:currentOutline];
            }

            for ( NSInteger i= currentOutline.numberOfChildren; i > 0; i-- )
            {
                [stack addObject:[currentOutline childAtIndex:i-1]];
            }
        }
    }

    NSMutableArray *arrParentsContents = [[NSMutableArray alloc] init];

    for ( NSInteger i= 0; i < arrTableOfContents.count; i++ )
    {
        PDFOutline *currentOutline = [arrTableOfContents objectAtIndex:i];

        NSInteger indentationLevel = -1;

        PDFOutline *parentOutline = currentOutline.parent;

        while (parentOutline != nil) {
            indentationLevel += 1;
            parentOutline = parentOutline.parent;
        }

        if (indentationLevel == 0) {

            NSMutableDictionary *DXParentsContent = [[NSMutableDictionary alloc] init];

            [DXParentsContent setObject:[[NSMutableArray alloc] init] forKey:@"children"];
            [DXParentsContent setObject:@"" forKey:@"mNativePtr"];
            [DXParentsContent setObject:[NSString stringWithFormat:@"%lu", [_pdfDocument indexForPage:currentOutline.destination.page]] forKey:@"pageIdx"];
            [DXParentsContent setObject:currentOutline.label forKey:@"title"];

            //currentOutlin
            //mNativePtr
            [arrParentsContents addObject:DXParentsContent];
        }
        else {
            NSMutableDictionary *DXParentsContent = [arrParentsContents lastObject];

            NSMutableArray *arrChildren = [DXParentsContent valueForKey:@"children"];

            while (indentationLevel > 1) {
                NSMutableDictionary *DXchild = [arrChildren lastObject];
                arrChildren = [DXchild valueForKey:@"children"];
                indentationLevel--;
            }

            NSMutableDictionary *DXChildContent = [[NSMutableDictionary alloc] init];
            [DXChildContent setObject:[[NSMutableArray alloc] init] forKey:@"children"];
            [DXChildContent setObject:@"" forKey:@"mNativePtr"];
            [DXChildContent setObject:[NSString stringWithFormat:@"%lu", [_pdfDocument indexForPage:currentOutline.destination.page]] forKey:@"pageIdx"];
            [DXChildContent setObject:currentOutline.label forKey:@"title"];
            [arrChildren addObject:DXChildContent];

        }
    }

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arrParentsContents options:NSJSONWritingPrettyPrinted error:&error];

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

    return jsonString;

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

    if (_initialed && _fixScaleFactor>0) {
        if (_scale != _pdfView.scaleFactor/_fixScaleFactor) {
            _scale = _pdfView.scaleFactor/_fixScaleFactor;
            _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"scaleChanged|%f", _scale]]});
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
    // Cycle through min/mid/max scale factors to be consistent with Android
    float min = self->_pdfView.minScaleFactor/self->_fixScaleFactor;
    float max = self->_pdfView.maxScaleFactor/self->_fixScaleFactor;
    float mid = (max - min) / 2 + min;
    float scale = self->_scale;
    if (self->_scale < mid) {
        scale = mid;
    } else if (self->_scale < max) {
        scale = max;
    } else {
        scale = min;
    }

    CGFloat newScale = scale * self->_fixScaleFactor;
    CGPoint tapPoint = [recognizer locationInView:self->_pdfView];
    tapPoint = [self->_pdfView convertPoint:tapPoint toPage:self->_pdfView.currentPage];
    CGRect zoomRect = CGRectZero;
    zoomRect.size.width = self->_pdfView.frame.size.width * newScale;
    zoomRect.size.height = self->_pdfView.frame.size.height * newScale;
    zoomRect.origin.x = tapPoint.x - zoomRect.size.width / 2;
    zoomRect.origin.y = tapPoint.y - zoomRect.size.height / 2;

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self->_pdfView setScaleFactor:newScale];
            [self->_pdfView goToRect:zoomRect onPage:self->_pdfView.currentPage];

            [self setNeedsDisplay];
            [self onScaleChanged:Nil];
        }];
    });
}

/**
 *  Single Tap
 *  stop zoom
 *
 *  @param recognizer
 */
- (void)handleSingleTap:(UITapGestureRecognizer *)sender
{
    //_pdfView.scaleFactor = _pdfView.minScaleFactor;

    CGPoint point = [sender locationInView:self];
    PDFPage *pdfPage = [_pdfView pageForPoint:point nearest:NO];
    if (pdfPage) {
        unsigned long page = [_pdfDocument indexForPage:pdfPage];
        _onChange(@{ @"message": [[NSString alloc] initWithString:[NSString stringWithFormat:@"pageSingleTap|%lu|%f|%f", page+1, point.x, point.y]]});
    }

    //[self setNeedsDisplay];
    //[self onScaleChanged:Nil];


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
 *  Do nothing on long Press
 *
 *
 */
- (void)handleLongPress:(UILongPressGestureRecognizer *)sender{

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
    doubleTapRecognizer.delegate = self;

    [self addGestureRecognizer:doubleTapRecognizer];

    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleSingleTap:)];
    //trigger by one finger and one touch
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    singleTapRecognizer.delegate = self;

    [self addGestureRecognizer:singleTapRecognizer];
    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handlePinch:)];
    [self addGestureRecognizer:pinchRecognizer];
    pinchRecognizer.delegate = self;

    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(handleLongPress:)];
    // Making sure the allowable movement isn not too narrow
    longPressRecognizer.allowableMovement=100;
    // Important: The duration must be long enough to allow taps but not longer than the period in which view opens the magnifying glass
    longPressRecognizer.minimumPressDuration=0.3;

    [self addGestureRecognizer:longPressRecognizer];

}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer

{
    return !_singlePage;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return !_singlePage;
}



@end
