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
    ViewPropTypes,
    requireNativeComponent,
} from 'react-native';
import {style} from "./index";

export default class PdfPageView extends PureComponent {

    constructor(props) {
        super(props);
        this.state = {}
    }

    _getStylePropsProps = () => {
        const { width, height } = this.props;
        if( width || height ) {
            return { width, height };
        }
        return {};
    };

    render() {
        return (
            <PdfPageViewCustom {...this.props} style={[style, this._getStylePropsProps()]} />
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
