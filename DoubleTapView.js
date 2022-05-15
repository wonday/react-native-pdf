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
import {ViewPropTypes} from 'deprecated-react-native-prop-types';
export default class DoubleTapView extends Component {

    static propTypes = {
        ...ViewPropTypes,
        delay: PropTypes.number,
        radius: PropTypes.number,
        onSingleTap: PropTypes.func,
        onDoubleTap: PropTypes.func,
    };

    static defaultProps = {
        delay: 300,
        radius: 50,
        onSingleTap: () => {
        },
        onDoubleTap: () => {
        },
    };

    constructor() {
        super();

        this.gestureHandlers = PanResponder.create({
            onStartShouldSetPanResponder: (evt, gestureState) => (gestureState.numberActiveTouches === 1),
            onStartShouldSetResponderCapture: (evt, gestureState) => (gestureState.numberActiveTouches === 1),
            onMoveShouldSetPanResponder: (evt, gestureState) => (false),
            onMoveShouldSetResponderCapture: (evt, gestureState) => (false),
            onPanResponderTerminationRequest: (evt, gestureState) => false,
            onPanResponderRelease: this.handlePanResponderRelease,

        });

        this.prevTouchInfo = {
            prevTouchX: 0,
            prevTouchY: 0,
            prevTouchTimeStamp: 0,
        };

        this.timer = null;

    }


    distance = (x0, y0, x1, y1) => {
        return Math.sqrt(Math.pow((x1 - x0), 2) + Math.pow((y1 - y0), 2)).toFixed(1);
    };

    isDoubleTap = (currentTouchTimeStamp, {x0, y0}) => {
        const {prevTouchX, prevTouchY, prevTouchTimeStamp} = this.prevTouchInfo;
        const dt = currentTouchTimeStamp - prevTouchTimeStamp;
        const {delay, radius} = this.props;

        return (prevTouchTimeStamp > 0 && dt < delay && this.distance(prevTouchX, prevTouchY, x0, y0) < radius);
    };

    handlePanResponderRelease = (evt, gestureState) => {

        const currentTouchTimeStamp = Date.now();
        const x = evt.nativeEvent.locationX;
        const y = evt.nativeEvent.locationY; 

        if (this.timer) {

            if (this.isDoubleTap(currentTouchTimeStamp, gestureState)) {

                clearTimeout(this.timer);
                this.timer = null;
                this.props.onDoubleTap();

            } else {

                const {prevTouchX, prevTouchY, prevTouchTimeStamp} = this.prevTouchInfo;
                const {radius} = this.props;

                // if not in radius, it's a move
                if (this.distance(prevTouchX, prevTouchY, gestureState.x0, gestureState.y0) < radius) {
                    this.timer = null;
                    this.props.onSingleTap(x, y);
                }

            }
        } else {
            // do not count scroll gestures as taps
            if (this.distance(0, gestureState.dx, 0, gestureState.dy) < 10) {

                this.timer = setTimeout(() => {
                    this.props.onSingleTap(x, y);
                    this.timer = null;
                }, this.props.delay);
            }
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