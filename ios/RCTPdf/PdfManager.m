/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */



#import "PdfManager.h"

#if __has_include(<React/RCTAssert.h>)
#import <React/RCTUtils.h>
#else
#import "React/RCTUtils.h"
#endif


static NSMutableArray *pdfDocRefs = Nil;

@implementation PdfManager


#ifndef __OPTIMIZE__
// only output log when debug
#define DLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define DLog( s, ... )
#endif

// output log both debug and release
#define RLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

RCT_EXPORT_MODULE();


RCT_EXPORT_METHOD(loadFile:(NSString *)path
                  password:(NSString *)password
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  )
{

    if (pdfDocRefs==Nil) {
        pdfDocRefs = [NSMutableArray arrayWithCapacity:1];
    }

    int numberOfPages = 0;

    if (path != nil && path.length != 0) {

        NSURL *pdfURL = [NSURL fileURLWithPath:path];
        CGPDFDocumentRef pdfRef = CGPDFDocumentCreateWithURL((__bridge CFURLRef) pdfURL);

        if (pdfRef == NULL) {
            reject(RCTErrorUnspecified, [NSString stringWithFormat:@"Load pdf failed. path=%s",path.UTF8String], nil);
            return;
        }

        if (CGPDFDocumentIsEncrypted(pdfRef)) {

            bool isUnlocked = CGPDFDocumentUnlockWithPassword(pdfRef, [password UTF8String]);
            if (!isUnlocked) {
                reject(RCTErrorUnspecified, @"Password required or incorrect password.", nil);
                return;
            }

        }

        [pdfDocRefs addObject:[NSValue valueWithPointer:pdfRef]];

        numberOfPages = (int)CGPDFDocumentGetNumberOfPages(pdfRef);
        CGPDFPageRef pdfPage = CGPDFDocumentGetPage(pdfRef, 1);
        CGRect pdfPageRect = CGPDFPageGetBoxRect(pdfPage, kCGPDFMediaBox);
        int rotation = CGPDFPageGetRotationAngle(pdfPage);
        
        NSArray *params;
        
        if (rotation == 90 || rotation==270) {
             params =@[[NSNumber numberWithUnsignedLong:([pdfDocRefs count]-1)], [NSNumber numberWithInt:numberOfPages], [NSNumber numberWithFloat:pdfPageRect.size.height], [NSNumber numberWithFloat:pdfPageRect.size.width]];
            RLog(@"Pdf loaded numberOfPages=%d, fileNo=%lu, pageWidth=%f, pageHeight=%f", numberOfPages, [pdfDocRefs count]-1, pdfPageRect.size.height, pdfPageRect.size.width);

        } else {
            params =@[[NSNumber numberWithUnsignedLong:([pdfDocRefs count]-1)], [NSNumber numberWithInt:numberOfPages], [NSNumber numberWithFloat:pdfPageRect.size.width], [NSNumber numberWithFloat:pdfPageRect.size.height]];
            RLog(@"Pdf loaded numberOfPages=%d, fileNo=%lu, pageWidth=%f, pageHeight=%f", numberOfPages, [pdfDocRefs count]-1, pdfPageRect.size.width, pdfPageRect.size.height);

        }

        resolve(params);
        return;
    } else {
        reject(RCTErrorUnspecified, @"Load pdf failed. path=null", nil);
        return;
    }
}

+ (CGPDFDocumentRef) getPdf:(NSUInteger) index
{
    if (pdfDocRefs && [pdfDocRefs count]>index){

        return (CGPDFDocumentRef)[(NSValue *)[pdfDocRefs objectAtIndex:index] pointerValue];

    }

    return NULL;
}

- (instancetype)init
{
    
    if ((self = [super init])) {

    }
    return self;

}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}


- (void)dealloc
{
    // release pdf docs
    for(NSValue *item in pdfDocRefs) {
        CGPDFDocumentRef pdfItem = [item pointerValue];
        if (pdfItem != NULL) {

            CGPDFDocumentRelease(pdfItem);
            pdfItem = NULL;

        }
    }
    pdfDocRefs = Nil;

}


@end
