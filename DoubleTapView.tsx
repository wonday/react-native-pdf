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
    PanResponder,
    GestureResponderEvent,
    PanResponderGestureState
} from 'react-native';
import { DoubleTapViewProps } from '.';

export default class DoubleTapView extends Component<DoubleTapViewProps> {
    static defaultProps = {
        delay: 300,
        radius: 50,
    };
    gestureHandlers: any;
    prevTouchInfo: { prevTouchX: number; prevTouchY: number; prevTouchTimeStamp: number; };
    timer: any;

    constructor(props: DoubleTapViewProps) {
        super(props);

        this.gestureHandlers = PanResponder.create({
            onStartShouldSetPanResponder: (_evt, gestureState) => (gestureState.numberActiveTouches === 1),
            onStartShouldSetPanResponderCapture: (_evt, gestureState) => (gestureState.numberActiveTouches === 1),
            onMoveShouldSetPanResponder: () => false,
            onMoveShouldSetPanResponderCapture: () => false,
            onPanResponderTerminationRequest: () => false,
            onPanResponderRelease: this.handlePanResponderRelease,

        });

        this.prevTouchInfo = {
            prevTouchX: 0,
            prevTouchY: 0,
            prevTouchTimeStamp: 0,
        };

        this.timer = null;
    }

    distance = (x0: number, y0: number, x1: number, y1: number) => {
        return Math.sqrt(Math.pow((x1 - x0), 2) + Math.pow((y1 - y0), 2));
    };

    isDoubleTap = (currentTouchTimeStamp: number, gestureState: PanResponderGestureState) => {
        const {prevTouchX, prevTouchY, prevTouchTimeStamp} = this.prevTouchInfo;
        const dt = currentTouchTimeStamp - prevTouchTimeStamp;
        const {delay, radius} = this.props;

        return (prevTouchTimeStamp > 0 && dt < delay && this.distance(prevTouchX, prevTouchY, gestureState.x0, gestureState.y0) < radius);
    };

    handlePanResponderRelease = (evt: GestureResponderEvent, gestureState: PanResponderGestureState) => {

        const currentTouchTimeStamp = Date.now();
        const x = evt.nativeEvent.locationX;
        const y = evt.nativeEvent.locationY; 

        if (this.timer) {
            if (this.isDoubleTap(currentTouchTimeStamp, gestureState)) {
                clearTimeout(this.timer);
                this.timer = null;
                this.props.onDoubleTap();

            } else {

                const {prevTouchX, prevTouchY} = this.prevTouchInfo;
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

    componentWillUnmount() {
        if (this.timer) {
            clearTimeout(this.timer);
        }
    }

    render() {
        return (
            <View {...this.props} {...this.gestureHandlers.panHandlers}>
                {this.props.children}
            </View>
        );
    }
}