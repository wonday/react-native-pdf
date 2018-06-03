/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "PdfManager.h"
#import "RCTPdfPageView.h"



#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

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

@implementation RCTPdfPageView {

   
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.scale = 1.0f;
        self.backgroundColor = UIColor.whiteColor;
        CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
        tiledLayer.levelsOfDetailBias = 0;
        
    }
    
    return self;
}


// The layer's class should be CATiledLayer.
+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (void)didSetProps:(NSArray<NSString *> *)changedProps
{
    long int count = [changedProps count];
    for (int i = 0 ; i < count; i++) {
        
        if ([[changedProps objectAtIndex:i] isEqualToString:@"page"]) {
            [self setNeedsDisplay];
        }

    }
    
    [self setNeedsDisplay];
}


- (void)reactSetFrame:(CGRect)frame
{
    [super reactSetFrame:frame];
    CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
    tiledLayer.tileSize = frame.size;
}

-(void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context
{
    
    // PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system before drawing.
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGPDFDocumentRef pdfRef= [PdfManager getPdf:_fileNo];
    if (pdfRef!=NULL)
    {
        
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfRef, _page);
        
        if (pdfPage != NULL) {
            
            CGContextSaveGState(context);
            CGRect pageBounds;
                pageBounds = CGRectMake(0,
                                        -self.bounds.size.height,
                                        self.bounds.size.width,
                                        self.bounds.size.height);
            
            // Fill the background with white.
            CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
            CGContextFillRect(context, pageBounds);
            
            CGAffineTransform pageTransform = CGPDFPageGetDrawingTransform(pdfPage, kCGPDFCropBox, pageBounds, 0, true);
            CGContextConcatCTM(context, pageTransform);
            CGContextScaleCTM(context, self.scale, self.scale);
            
            CGContextDrawPDFPage(context, pdfPage);
            CGContextRestoreGState(context);
            
            RLog(@"drawpage %d", _page);
        }

    }
}

@end
