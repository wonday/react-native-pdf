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
    StyleSheet,
    PanResponder,
    GestureResponderEvent,
    PanResponderGestureState
} from 'react-native';
import { PinchZoomViewProps } from '.';

export default class PinchZoomView extends Component<PinchZoomViewProps> {
    static defaultProps = {
        scalable: true,
    };

    distant: number;
    gestureHandlers: any;

    constructor(props: PinchZoomViewProps) {
        super(props);
        this.state = {};

        this.distant = 0;
        
        this.gestureHandlers = PanResponder.create({
            onStartShouldSetPanResponder: this._handleStartShouldSetPanResponder,
            onMoveShouldSetPanResponderCapture: () => true,
            onMoveShouldSetPanResponder: this._handleMoveShouldSetPanResponder,
            onPanResponderGrant: this._handlePanResponderGrant,
            onPanResponderMove: this._handlePanResponderMove,
            onPanResponderRelease: this._handlePanResponderEnd,
            onPanResponderTerminationRequest: evt => false,
            onPanResponderTerminate: this._handlePanResponderTerminate,
            onShouldBlockNativeResponder: evt => true
        });
    }

    _handleStartShouldSetPanResponder = () => {
        // don't respond to single touch to avoid shielding click on child components
        return false;
    };

    _handleMoveShouldSetPanResponder = (e: GestureResponderEvent, gestureState: PanResponderGestureState) => {
        return this.props.scalable && (e.nativeEvent.changedTouches.length >= 2 || gestureState.numberActiveTouches >= 2);
    };

    _handlePanResponderGrant = (e: GestureResponderEvent, gestureState: PanResponderGestureState) => {
        if (e.nativeEvent.changedTouches.length >= 2 || gestureState.numberActiveTouches >= 2) {
            let dx = Math.abs(e.nativeEvent.touches[0].pageX - e.nativeEvent.touches[1].pageX);
            let dy = Math.abs(e.nativeEvent.touches[0].pageY - e.nativeEvent.touches[1].pageY);
            this.distant = Math.sqrt(dx * dx + dy * dy);
        }
    };

    _handlePanResponderEnd = () => {
        this.distant = 0;
    };

    _handlePanResponderTerminate = () => {
        this.distant = 0;
    };

    _handlePanResponderMove = (e: GestureResponderEvent, gestureState: PanResponderGestureState) => {

        if ((e.nativeEvent.changedTouches.length >= 2 || gestureState.numberActiveTouches >= 2) && this.distant > 100) {

            let dx = Math.abs(e.nativeEvent.touches[0].pageX - e.nativeEvent.touches[1].pageX);
            let dy = Math.abs(e.nativeEvent.touches[0].pageY - e.nativeEvent.touches[1].pageY);
            let distant = Math.sqrt(dx * dx + dy * dy);
            let scale = (distant / this.distant);
            let pageX = (e.nativeEvent.touches[0].pageX + e.nativeEvent.touches[1].pageX) / 2;
            let pageY = (e.nativeEvent.touches[0].pageY + e.nativeEvent.touches[1].pageY) / 2;
            let pinchInfo = {scale: scale, pageX: pageX, pageY: pageY};

            this.props.onScaleChanged && this.props.onScaleChanged(pinchInfo);
            this.distant = distant;
        }
    };

    render() {
        return (
            <View
                {...this.props}
                {...this.gestureHandlers?.panHandlers}
                style={[styles.container, this.props.style]}>
                {this.props.children}
            </View>
        );
    }
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center'
    }
});
