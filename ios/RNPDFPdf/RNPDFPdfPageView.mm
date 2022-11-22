/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "PdfManager.h"
#import "RNPDFPdfPageView.h"



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

@interface CAPdfLayer : CALayer
-(void) setParentView:(RNPDFPdfPageView *)parentView;
@end

@implementation CAPdfLayer
{
    RNPDFPdfPageView *_parentView;
}

-(void) setParentView:(RNPDFPdfPageView *)parentView
{
    _parentView = parentView;
}

- (void)drawInContext:(CGContextRef)context
{
    
    CGRect _viewFrame = _parentView.frame;
    CGPDFDocumentRef pdfRef= [PdfManager getPdf:_parentView.fileNo];
    if (pdfRef!=NULL)
    {
        
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfRef, _parentView.page);
        
        if (pdfPage != NULL) {
            
            // Fill the background with white.
            CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
            CGContextFillRect(context, _viewFrame);
            
            // PDF page drawing expects a Lower-Left coordinate system, so we flip the coordinate system before drawing.
            CGContextScaleCTM(context, 1.0, -1.0);
            CGContextTranslateCTM(context, 0, -_viewFrame.size.height);
            
            CGRect pdfPageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
            
            int rotation = CGPDFPageGetRotationAngle(pdfPage);
            if (rotation == 90 || rotation == 270) {
                pdfPageRect = CGRectMake(0, 0, pdfPageRect.size.height, pdfPageRect.size.width);
            }
            
            CGFloat scale = 1.0f;
            if (_viewFrame.size.width/_viewFrame.size.height>=pdfPageRect.size.width/pdfPageRect.size.height) {
                scale = _viewFrame.size.height/pdfPageRect.size.height;
                
            } else {
                scale = _viewFrame.size.width/pdfPageRect.size.width;
            }
            CGContextScaleCTM(context, scale, scale);
            
            
            
            switch (rotation) {
                case 0:
                    if (_viewFrame.size.width/_viewFrame.size.height>=pdfPageRect.size.width/pdfPageRect.size.height) {
                        CGContextTranslateCTM(context, (_viewFrame.size.width-pdfPageRect.size.width*scale)/2, 0);
                    } else {
                        CGContextTranslateCTM(context, 0, (_viewFrame.size.height-pdfPageRect.size.height*scale)/2);
                    }
                    break;
                case 90:
                    CGContextRotateCTM(context, -rotation*M_PI/180);
                    CGContextTranslateCTM(context, -pdfPageRect.size.height, 0);
                    if (_viewFrame.size.width/_viewFrame.size.height>=pdfPageRect.size.width/pdfPageRect.size.height) {
                        CGContextTranslateCTM(context, 0, -(_viewFrame.size.height-pdfPageRect.size.height*scale)/2);
                    } else {
                        CGContextTranslateCTM(context, -(_viewFrame.size.height/scale-pdfPageRect.size.height)/2, 0);
                    }
                    break;
                case 180:
                    CGContextRotateCTM(context, -rotation*M_PI/180);
                    CGContextTranslateCTM(context, -pdfPageRect.size.height, -pdfPageRect.size.width);
                    if (_viewFrame.size.width/_viewFrame.size.height>=pdfPageRect.size.width/pdfPageRect.size.height) {
                        CGContextTranslateCTM(context, (_viewFrame.size.width-pdfPageRect.size.width*scale)/2, 0);
                    } else {
                        CGContextTranslateCTM(context, 0, (_viewFrame.size.height-pdfPageRect.size.height*scale)/2);
                    }
                case 270:
                    CGContextRotateCTM(context, -rotation*M_PI/180);
                    CGContextTranslateCTM(context, 0, -pdfPageRect.size.width);
                    if (_viewFrame.size.width/_viewFrame.size.height>=pdfPageRect.size.width/pdfPageRect.size.height) {
                        CGContextTranslateCTM(context, 0, -(_viewFrame.size.height-pdfPageRect.size.height*scale)/2);
                    } else {
                        CGContextTranslateCTM(context, -(_viewFrame.size.height/scale-pdfPageRect.size.height)/2, 0);
                    }
                default:
                    break;
            }
            
            
            // draw the content to context
            CGContextDrawPDFPage(context, pdfPage);
        }
        
    }
}
@end

@implementation RNPDFPdfPageView {
    
    CAPdfLayer         *_layer;
}

// The layer's class
+ (Class)layerClass
{
    return [CAPdfLayer class];
}

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    
    return self;
}

- (void)didSetProps:(NSArray<NSString *> *)changedProps
{
    long int count = [changedProps count];
    for (int i = 0 ; i < count; i++) {
        if ([[changedProps objectAtIndex:i] isEqualToString:@"page"]) {
            // do something
        }
    }

    [self.layer setNeedsDisplay];
}


- (void)reactSetFrame:(CGRect)frame
{
    [super reactSetFrame:frame];
    
    self.layer.backgroundColor= [UIColor whiteColor].CGColor;
    self.layer.contentsScale = [[UIScreen mainScreen] scale];
    [(CAPdfLayer *)self.layer setParentView:self];
    [self.layer setNeedsDisplay];
}

- (void)dealloc{

}

@end
