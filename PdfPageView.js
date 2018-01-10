/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';
import React, {Component} from 'react';
import PropTypes from 'prop-types';
import {
    ViewPropTypes,
    requireNativeComponent,
} from 'react-native';

export default class PdfPageView extends Component {

    constructor(props) {
        super(props);
        this.state = {}
    }

    render() {

        return (
            <PdfPageViewCustom {...this.props} />
        );

    }
}

PdfPageView.propTypes = {
    ...ViewPropTypes,
    fileNo: PropTypes.number,
    page: PropTypes.number
};

let PdfPageViewCustom = requireNativeComponent('RCTPdfPageView', PdfPageView, {nativeOnly: {}});