/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';
import {
    FlatList,
} from 'react-native';

export default class PdfViewFlatList extends FlatList {
    /**
     * Scrolls to a given x, y offset, either immediately or with a smooth animation.
     *
     * Example:
     *
     * `scrollTo({x: 0, y: 0, animated: true})`
     *
     * Note: The weird function signature is due to the fact that, for historical reasons,
     * the function also accepts separate arguments as an alternative to the options object.
     * This is deprecated due to ambiguity (y before x), and SHOULD NOT BE USED.
     */
    scrollToXY = (x, y) => {
        const scrollRef = typeof this.getNativeScrollRef === 'function'
            ? this.getNativeScrollRef()
            : (typeof this.getScrollResponder === 'function'
                ? this.getScrollResponder()
                : undefined);
        if (scrollRef && typeof scrollRef.scrollTo === 'function') {
            scrollRef.scrollTo({x, y, animated: false});
            return;
        }

        const offset = this.props.horizontal ? x : y;
        if (typeof this.scrollToOffset === 'function') {
            this.scrollToOffset({animated: false, offset});
        }
    }

}
