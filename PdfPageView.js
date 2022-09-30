/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */


'use strict';
import React, {PureComponent} from 'react';
import PropTypes from 'prop-types';
import {
    requireNativeComponent,
} from 'react-native';
import {ViewPropTypes} from 'deprecated-react-native-prop-types';
export default class PdfPageView extends PureComponent {
    _getStylePropsProps = () => {
        const {width, height} = this.props;
        if (width || height) {
            return {width, height};
        }
        return {};
    };

    render() {
        const {
            style,
            ...restProps
        } = this.props;
        return (
            <PdfPageViewCustom
                {...restProps}
                style={[style, this._getStylePropsProps()]}
            />
        );

    }
}

PdfPageView.propTypes = {
    ...ViewPropTypes,
    fileNo: PropTypes.number,
    page: PropTypes.number,
    width: PropTypes.number,
    height: PropTypes.number
};

PdfPageView.defaultProps = {
    style: {}
};

let PdfPageViewCustom = requireNativeComponent('RCTPdfPageView', PdfPageView, {nativeOnly: {}});
