/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RNPDFPdfView.h"

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <PDFKit/PDFKit.h>

#if __has_include(<React/RCTAssert.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>
#import <React/RCTLog.h>
#import <React/RCTBlobManager.h>
#else
#import "RCTBridgeModule.h"
#import "RCTEventDispatcher.h"
#import "UIView+React.h"
#import "RCTLog.h"
#import <RCTBlobManager.h">
#endif

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <react/renderer/components/rnpdf/ComponentDescriptors.h>
#import <react/renderer/components/rnpdf/Props.h>
#import <react/renderer/components/rnpdf/RCTComponentViewHelpers.h>

// Some RN private method hacking below similar to how it is done in RNScreens:
// https://github.com/software-mansion/react-native-screens/blob/90e548739f35b5ded2524a9d6410033fc233f586/ios/RNSScreenStackHeaderConfig.mm#L30
@interface RCTBridge (Private)
+ (RCTBridge *)currentBridge;
@end

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

@interface RNPDFPdfView() <PDFDocumentDelegate, PDFViewDelegate
#ifdef RCT_NEW_ARCH_ENABLED
, RCTRNPDFPdfViewViewProtocol
#endif
>
@end

@implementation RNPDFPdfView
{
    RCTBridge *_bridge;
    PDFDocument *_pdfDocument;
    PDFView *_pdfView;
    PDFOutline *root;
    float _fixScaleFactor;
    bool _initialed;
    NSArray<NSString *> *_changedProps;
    UITapGestureRecognizer *_doubleTapRecognizer;
    UITapGestureRecognizer *_singleTapRecognizer;
    UIPinchGestureRecognizer *_pinchRecognizer;
    UILongPressGestureRecognizer *_longPressRecognizer;
    UITapGestureRecognizer *_doubleTapEmptyRecognizer;
}

#ifdef RCT_NEW_ARCH_ENABLED

using namespace facebook::react;

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<RNPDFPdfViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        static const auto defaultProps = std::make_shared<const RNPDFPdfViewProps>();
        _props = defaultProps;
        [self initCommonProps];
    }
    return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &newProps = *std::static_pointer_cast<const RNPDFPdfViewProps>(props);
    NSMutableArray<NSString *> *updatedPropNames = [NSMutableArray new];
    if (_path != RCTNSStringFromStringNilIfEmpty(newProps.path)) {
        _path = RCTNSStringFromStringNilIfEmpty(newProps.path);
        [updatedPropNames addObject:@"path"];
    }
    if (_page != newProps.page) {
        _page = newProps.page;
        [updatedPropNames addObject:@"page"];
    }
    if (_scale != newProps.scale) {
        _scale = newProps.scale;
        [updatedPropNames addObject:@"scale"];
    }
    if (_minScale != newProps.minScale) {
        _minScale = newProps.minScale;
        [updatedPropNames addObject:@"minScale"];
    }
    if (_maxScale != newProps.maxScale) {
        _maxScale = newProps.maxScale;
        [updatedPropNames addObject:@"maxScale"];
    }
    if (_horizontal != newProps.horizontal) {
        _horizontal = newProps.horizontal;
        [updatedPropNames addObject:@"horizontal"];
    }
    if (_enablePaging != newProps.enablePaging) {
        _enablePaging = newProps.enablePaging;
        [updatedPropNames addObject:@"enablePaging"];
    }
    if (_enableRTL != newProps.enableRTL) {
        _enableRTL = newProps.enableRTL;
        [updatedPropNames addObject:@"enableRTL"];
    }
    if (_enableAnnotationRendering != newProps.enableAnnotationRendering) {
        _enableAnnotationRendering = newProps.enableAnnotationRendering;
        [updatedPropNames addObject:@"enableAnnotationRendering"];
    }
    if (_enableDoubleTapZoom != newProps.enableDoubleTapZoom) {
        _enableDoubleTapZoom = newProps.enableDoubleTapZoom;
        [updatedPropNames addObject:@"enableDoubleTapZoom"];
    }
    if (_fitPolicy != newProps.fitPolicy) {
        _fitPolicy = newProps.fitPolicy;
        [updatedPropNames addObject:@"fitPolicy"];
    }
    if (_spacing != newProps.spacing) {
        _spacing = newProps.spacing;
        [updatedPropNames addObject:@"spacing"];
    }
    if (_password != RCTNSStringFromStringNilIfEmpty(newProps.password)) {
        _password = RCTNSStringFromStringNilIfEmpty(newProps.password);
        [updatedPropNames addObject:@"password"];
    }
    if (_singlePage != newProps.singlePage) {
        _singlePage = newProps.singlePage;
        [updatedPropNames addObject:@"singlePage"];
    }
    if (_showsHorizontalScrollIndicator != newProps.showsHorizontalScrollIndicator) {
        _showsHorizontalScrollIndicator = newProps.showsHorizontalScrollIndicator;
        [updatedPropNames addObject:@"showsHorizontalScrollIndicator"];
    }
    if (_showsVerticalScrollIndicator != newProps.showsVerticalScrollIndicator) {
        _showsVerticalScrollIndicator = newProps.showsVerticalScrollIndicator;
        [updatedPropNames addObject:@"showsVerticalScrollIndicator"];
    }

    [super updateProps:props oldProps:oldProps];
    [self didSetProps:updatedPropNames];
}

// already added in case https://github.com/facebook/react-native/pull/35378 has been merged
- (BOOL)shouldBeRecycled
{
    return NO;
}

- (void)prepareForRecycle
{
    [super prepareForRecycle];

    [_pdfView removeFromSuperview];
    _pdfDocument = Nil;
    _pdfView = Nil;
    //Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewDocumentChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewPageChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewScaleChangedNotification" object:nil];

    // remove old recognizers before adding new ones
    [self removeGestureRecognizer:_doubleTapRecognizer];
    [self removeGestureRecognizer:_singleTapRecognizer];
    [self removeGestureRecognizer:_pinchRecognizer];
    [self removeGestureRecognizer:_longPressRecognizer];
    [self removeGestureRecognizer:_doubleTapEmptyRecognizer];

    [self initCommonProps];
}

- (void)updateLayoutMetrics:(const facebook::react::LayoutMetrics &)layoutMetrics oldLayoutMetrics:(const facebook::react::LayoutMetrics &)oldLayoutMetrics
{
    // Fabric equivalent of `reactSetFrame` method
    [super updateLayoutMetrics:layoutMetrics oldLayoutMetrics:oldLayoutMetrics];
    _pdfView.frame = CGRectMake(0, 0, layoutMetrics.frame.size.width, layoutMetrics.frame.size.height);

    NSMutableArray *mProps = [_changedProps mutableCopy];
    if (_initialed) {
        [mProps removeObject:@"path"];
    }
    _initialed = YES;

    [self didSetProps:mProps];
}

- (void)handleCommand:(const NSString *)commandName args:(const NSArray *)args
{
  RCTRNPDFPdfViewHandleCommand(self, commandName, args);
}

- (void)setNativePage:(NSInteger)page
{
    _page = page;
    [self didSetProps:[NSArray arrayWithObject:@"page"]];
}

#endif

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
    self = [super init];
    if (self) {
        _bridge = bridge;
        [self initCommonProps];
    }

    return self;
}

- (void)initCommonProps
{
    _page = 1;
    _scale = 1;
    _minScale = MIN_SCALE;
    _maxScale = MAX_SCALE;
    _horizontal = NO;
    _enablePaging = NO;
    _enableRTL = NO;
    _enableAnnotationRendering = YES;
    _enableDoubleTapZoom = YES;
    _fitPolicy = 2;
    _spacing = 10;
    _singlePage = NO;
    _showsHorizontalScrollIndicator = YES;
    _showsVerticalScrollIndicator = YES;

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

    // Disable built-in double tap, so as not to conflict with custom recognizers.
    for (UIGestureRecognizer *recognizer in _pdfView.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UITapGestureRecognizer class]]) {
            recognizer.enabled = NO;
        }
    }

    [self bindTap];
}

- (void)PDFViewWillClickOnLink:(PDFView *)sender withURL:(NSURL *)url
{
    NSString *_url = url.absoluteString;
    [self notifyOnChangeWithMessage:
                     [[NSString alloc] initWithString:
                      [NSString stringWithFormat:
                       @"linkPressed|%s", _url.UTF8String]]];
}

- (void)didSetProps:(NSArray<NSString *> *)changedProps
{
    if (!_initialed) {

        _changedProps = changedProps;

    } else {

        if ([changedProps containsObject:@"path"]) {


            if (_pdfDocument != Nil) {
                //Release old doc
                _pdfDocument = Nil;
            }
            
            if ([_path hasPrefix:@"blob:"]) {
                RCTBlobManager *blobManager = [
#ifdef RCT_NEW_ARCH_ENABLED
        [RCTBridge currentBridge]
#else
        _bridge
#endif // RCT_NEW_ARCH_ENABLED
                    moduleForName:@"BlobModule"];
                NSURL *blobURL = [NSURL URLWithString:_path];
                NSData *blobData = [blobManager resolveURL:blobURL];
                if (blobData != nil) {
                    _pdfDocument = [[PDFDocument alloc] initWithData:blobData];
                }
            } else {
            
                // decode file path
                _path = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapes(NULL, (CFStringRef)_path, CFSTR(""));
                NSURL *fileURL = [NSURL fileURLWithPath:_path];
                _pdfDocument = [[PDFDocument alloc] initWithURL:fileURL];
            }

            if (_pdfDocument) {

                //check need password or not
                if (_pdfDocument.isLocked && ![_pdfDocument unlockWithPassword:_password]) {

                    [self notifyOnChangeWithMessage:@"error|Password required or incorrect password."];

                    _pdfDocument = Nil;
                    return;
                }

                _pdfView.document = _pdfDocument;
            } else {

                [self notifyOnChangeWithMessage:[[NSString alloc] initWithString:[NSString stringWithFormat:@"error|Load pdf failed. path=%s",_path.UTF8String]]];

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

            PDFPage *pdfPage = _pdfView.currentPage ? _pdfView.currentPage : [_pdfDocument pageAtIndex:_pdfDocument.pageCount-1];
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

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"showsHorizontalScrollIndicator"])) {
            if (_showsHorizontalScrollIndicator) {
                for (UIView *subview in _pdfView.subviews) {
                    if ([subview isKindOfClass:[UIScrollView class]]) {
                        UIScrollView *scrollView = (UIScrollView *)subview;
                        scrollView.showsHorizontalScrollIndicator = YES;
                    }
                }
            } else {
                for (UIView *subview in _pdfView.subviews) {
                    if ([subview isKindOfClass:[UIScrollView class]]) {
                        UIScrollView *scrollView = (UIScrollView *)subview;
                        scrollView.showsHorizontalScrollIndicator = NO;
                    }
                }
            }
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"showsVerticalScrollIndicator"])) {
            if (_showsVerticalScrollIndicator) {
                for (UIView *subview in _pdfView.subviews) {
                    if ([subview isKindOfClass:[UIScrollView class]]) {
                        UIScrollView *scrollView = (UIScrollView *)subview;
                        scrollView.showsVerticalScrollIndicator = YES;
                    }
                }
            } else {
                for (UIView *subview in _pdfView.subviews) {
                    if ([subview isKindOfClass:[UIScrollView class]]) {
                        UIScrollView *scrollView = (UIScrollView *)subview;
                        scrollView.showsVerticalScrollIndicator = NO;
                    }
                }
            }
        }

        if (_pdfDocument && ([changedProps containsObject:@"path"] || [changedProps containsObject:@"enablePaging"] || [changedProps containsObject:@"horizontal"] || [changedProps containsObject:@"page"])) {

            PDFPage *pdfPage = [_pdfDocument pageAtIndex:_page-1];
            if (pdfPage && _page == 1) {
                // goToDestination() would be better. However, there is an
                // error in the pointLeftTop computation that often results in
                // scrolling to the middle of the page.
                // Special case workaround to make starting at the first page
                // align acceptably.
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->_pdfView goToRect:CGRectMake(0, NSUIntegerMax, 1, 1) onPage:pdfPage];
                });
            } else if (pdfPage) {
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


- (void)notifyOnChangeWithMessage:(NSString *)message
{
#ifdef RCT_NEW_ARCH_ENABLED
    if (_eventEmitter != nullptr) {
             std::dynamic_pointer_cast<const RNPDFPdfViewEventEmitter>(_eventEmitter)
                 ->onChange(RNPDFPdfViewEventEmitter::OnChange{.message = RCTStringFromNSString(message)});
           }
#else
    _onChange(@{ @"message": message});
#endif
}

- (void)dealloc{

    _pdfDocument = Nil;
    _pdfView = Nil;

    //Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewDocumentChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewPageChangedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PDFViewScaleChangedNotification" object:nil];

    _doubleTapRecognizer = nil;
    _singleTapRecognizer = nil;
    _pinchRecognizer = nil;
    _longPressRecognizer = nil;
    _doubleTapEmptyRecognizer = nil;
}

#pragma mark notification process
- (void)onDocumentChanged:(NSNotification *)noti
{

    if (_pdfDocument) {

        unsigned long numberOfPages = _pdfDocument.pageCount;
        PDFPage *page = [_pdfDocument pageAtIndex:_pdfDocument.pageCount-1];
        CGSize pageSize = [_pdfView rowSizeForPage:page];
        NSString *jsonString = [self getTableContents];

        [self notifyOnChangeWithMessage:
         [[NSString alloc] initWithString:[NSString stringWithFormat:@"loadComplete|%lu|%f|%f|%@", numberOfPages, pageSize.width, pageSize.height,jsonString]]];
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

        [self notifyOnChangeWithMessage:[[NSString alloc] initWithString:[NSString stringWithFormat:@"pageChanged|%lu|%lu", page+1, numberOfPages]]];
    }

}

- (void)onScaleChanged:(NSNotification *)noti
{

    if (_initialed && _fixScaleFactor>0) {
        if (_scale != _pdfView.scaleFactor/_fixScaleFactor) {
            _scale = _pdfView.scaleFactor/_fixScaleFactor;
            [self notifyOnChangeWithMessage:[[NSString alloc] initWithString:[NSString stringWithFormat:@"scaleChanged|%f", _scale]]];
        }
    }
}

#pragma mark gesture process

/**
 *  Empty double tap handler
 *
 *
 */
- (void)handleDoubleTapEmpty:(UITapGestureRecognizer *)recognizer {}

/**
 *  Tap
 *  zoom reset or zoom in
 *
 *  @param recognizer
 */
- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{

    // Prevent double tap from selecting text.
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->_pdfView clearSelection];
    });

    // Event appears to be consumed; broadcast for JS.
    _onChange(@{ @"message": @"pageDoubleTap" });

    if (!_enableDoubleTapZoom) {
        return;
    }

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

    PDFPage *tappedPdfPage = [_pdfView pageForPoint:tapPoint nearest:NO];
    PDFPage *pageRef;
    if (tappedPdfPage) {
        pageRef = tappedPdfPage;
    }   else {
        pageRef = self->_pdfView.currentPage;
    }
    tapPoint = [self->_pdfView convertPoint:tapPoint toPage:pageRef];

    CGRect tempZoomRect = CGRectZero;
    tempZoomRect.size.width = self->_pdfView.frame.size.width;
    tempZoomRect.size.height = 1;
    tempZoomRect.origin = tapPoint;

    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self->_pdfView setScaleFactor:newScale];

            [self->_pdfView goToRect:tempZoomRect onPage:pageRef];
            CGPoint defZoomOrigin = [self->_pdfView convertPoint:tempZoomRect.origin fromPage:pageRef];
            defZoomOrigin.x = defZoomOrigin.x - self->_pdfView.frame.size.width / 2;
            defZoomOrigin.y = defZoomOrigin.y - self->_pdfView.frame.size.height / 2;
            defZoomOrigin = [self->_pdfView convertPoint:defZoomOrigin toPage:pageRef];
            CGRect defZoomRect =  CGRectOffset(
                tempZoomRect,
                defZoomOrigin.x - tempZoomRect.origin.x,
                defZoomOrigin.y - tempZoomRect.origin.y
            );
            [self->_pdfView goToRect:defZoomRect onPage:pageRef];

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
        [self notifyOnChangeWithMessage:
         [[NSString alloc] initWithString:[NSString stringWithFormat:@"pageSingleTap|%lu|%f|%f", page+1, point.x, point.y]]];
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
    _doubleTapRecognizer = doubleTapRecognizer;

    UITapGestureRecognizer *singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleSingleTap:)];
    //trigger by one finger and one touch
    singleTapRecognizer.numberOfTapsRequired = 1;
    singleTapRecognizer.numberOfTouchesRequired = 1;
    singleTapRecognizer.delegate = self;

    [self addGestureRecognizer:singleTapRecognizer];
    _singleTapRecognizer = singleTapRecognizer;

    [singleTapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handlePinch:)];
    [self addGestureRecognizer:pinchRecognizer];
    _pinchRecognizer = pinchRecognizer;

    pinchRecognizer.delegate = self;

    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(handleLongPress:)];
    // Making sure the allowable movement isn not too narrow
    longPressRecognizer.allowableMovement=100;
    // Important: The duration must be long enough to allow taps but not longer than the period in which view opens the magnifying glass
    longPressRecognizer.minimumPressDuration=0.3;

    [self addGestureRecognizer:longPressRecognizer];
    _longPressRecognizer = longPressRecognizer;

    // Override the _pdfView double tap gesture recognizer so that it doesn't confilict with custom double tap
    UITapGestureRecognizer *doubleTapEmptyRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                          action:@selector(handleDoubleTapEmpty:)];
    doubleTapEmptyRecognizer.numberOfTapsRequired = 2;
    [_pdfView addGestureRecognizer:doubleTapEmptyRecognizer];
    _doubleTapEmptyRecognizer = doubleTapEmptyRecognizer;
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

#ifdef RCT_NEW_ARCH_ENABLED
Class<RCTComponentViewProtocol> RNPDFPdfViewCls(void)
{
    return RNPDFPdfView.class;
}

#endif
