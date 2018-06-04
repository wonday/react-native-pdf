/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#if __has_include(<React/RCTAssert.h>)
#import <React/UIView+React.h>
#else
#import "UIView+React.h"
#endif


@interface RCTPdfPageView : UIView

@property(nonatomic) int fileNo;
@property(nonatomic) int page;

@end
