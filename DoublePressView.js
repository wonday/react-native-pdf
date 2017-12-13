/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';
import React, {Component} from 'react';
import {
    View,
    PanResponder
} from 'react-native';
import PropTypes from 'prop-types';

export default class DoublePressView extends Component {

    static propTypes = {
        ...View.propTypes,
        delay: PropTypes.number,
        radius: PropTypes.number,
        onPress: PropTypes.func,
        onDoublePress: PropTypes.func,
    };

    static defaultProps = {
        delay: 300,
        radius: 40,
        onPress: () => {
        },
        onDoublePress: () => {
        },
    };

    constructor() {
        super();

        this.gestureHandlers = {};

        this.prevTouchInfo = {
            prevTouchX: 0,
            prevTouchY: 0,
            prevTouchTimeStamp: 0,
        };

        this.timer = null;

    }

    componentWillMount() {
        this.gestureHandlers = PanResponder.create({
            onStartShouldSetPanResponder: (evt, gestureState) => (gestureState.numberActiveTouches === 1),
            onStartShouldSetResponderCapture: (evt, gestureState) => (gestureState.numberActiveTouches === 1),
            onMoveShouldSetPanResponder: (evt, gestureState) => (false),
            onMoveShouldSetResponderCapture: (evt, gestureState) => (false),
            onPanResponderTerminationRequest: (evt, gestureState) => false,
            onPanResponderRelease: this.handlePanResponderRelease,

        });
    }

    distance = (x0, y0, x1, y1) => {
        return Math.sqrt(Math.pow((x1 - x0), 2) + Math.pow((y1 - y0), 2)).toFixed(1);
    };

    isDoublePress = (currentTouchTimeStamp, {x0, y0}) => {
        const {prevTouchX, prevTouchY, prevTouchTimeStamp} = this.prevTouchInfo;
        const dt = currentTouchTimeStamp - prevTouchTimeStamp;
        const {delay, radius} = this.props;

        return (prevTouchTimeStamp > 0 && dt < delay && this.distance(prevTouchX, prevTouchY, x0, y0) < radius);
    };

    handlePanResponderRelease = (evt, gestureState) => {

        const currentTouchTimeStamp = Date.now();

        if (this.timer) {

            clearTimeout(this.timer);
            this.timer = null;

            if (this.isDoublePress(currentTouchTimeStamp, gestureState)) {

                this.props.onDoublePress();

            } else {

                this.timer = setTimeout(() => {
                    this.timer = null;
                    this.props.onPress();
                }, this.props.delay);

                this.props.onPress();

            }
        } else {

            this.timer = setTimeout(() => {
                this.timer = null;
                this.props.onPress();
            }, this.props.delay);

        }


        this.prevTouchInfo = {
            prevTouchX: gestureState.x0,
            prevTouchY: gestureState.y0,
            prevTouchTimeStamp: currentTouchTimeStamp,
        };

    };

    render() {
        return (
            <View {...this.props} {...this.gestureHandlers.panHandlers}>
                {this.props.children}
            </View>
        );
    }
}