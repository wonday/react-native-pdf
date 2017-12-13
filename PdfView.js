/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';
import React, {Component} from 'react';
import {FlatList, View} from 'react-native';
import PropTypes from 'prop-types';

import PdfManager from './PdfManager';
import PdfPageView from './PdfPageView';
import DoublePressView from './DoublePressView';
import PinchZoomView from './PinchZoomView';

const MAX_SCALE = 3;

export default class PdfView extends Component {

    static propTypes = {
        ...View.propTypes,
        path: PropTypes.string,
        password: PropTypes.string,
        scale: PropTypes.number,
        spacing: PropTypes.number,
        fitPolicy: PropTypes.number,
        horizontal: PropTypes.bool,
        page: PropTypes.number,
    };

    static defaultProps = {
        path: "",
        password: "",
        scale: 1,
        spacing: 10,
        style: {},
        fitPolicy: 0,
        horizontal: false,
        page: 1,
    };

    constructor(props) {

        super(props);
        this.state = {
            pdfLoaded: false,
            fileNo: -1,
            numberOfPages: 0,
            page: -1,
            pageAspectRate: 0.5,
            contentSize: {width: 0, height: 0},
            scale: 1,
            contentOffset: null,
            scrollEnabled: true,
        };

        this.flatList = null;
        this.scaleTimer = null;

    }

    componentWillMount() {
    }

    componentDidMount() {

        PdfManager.loadFile(this.props.path, this.props.password)
            .then((pdfInfo) => {
                this.setState({
                    pdfLoaded: true,
                    fileNo: pdfInfo[0],
                    numberOfPages: pdfInfo[1],
                    pageAspectRate: pdfInfo[3] === 0 ? 1 : pdfInfo[2] / pdfInfo[3]
                });
                if (this.props.onLoadComplete) this.props.onLoadComplete(pdfInfo[1], this.props.path);
            });

    }

    componentWillReceiveProps(nextProps) {

        if (nextProps.scale !== this.state.scale) {
            this._onScale(nextProps.scale / this.state.scale);
        }

    }

    componentWillUnmount() {

        clearTimeout(this.scaleTimer);

    }

    _keyExtractor = (item, index) => index;

    _getPageWidth = () => {

        switch (this.props.fitPolicy) {
            case 1:  //fit width
                return this.state.contentSize.width * this.state.scale;
            case 2:  //fit height
                return this.state.contentSize.height * this.state.pageAspectRate * this.state.scale;
            case 3:  //fit whole page (if pageEnable=true, force this)
                return this.state.contentSize.width * this.state.scale;
            case 0: //autofit, horizontal:fit width, vertical:fit height
            default: {
                if (this.props.horizontal) {
                    return this.state.contentSize.height * this.state.pageAspectRate * this.state.scale;
                } else {
                    return this.state.contentSize.width * this.state.scale;
                }
            }
        }

    };

    _getPageHeight = () => {

        switch (this.props.fitPolicy) {
            case 1: //fit width
                return this.state.contentSize.width * (1 / this.state.pageAspectRate) * this.state.scale;
            case 2: //fit height
                return this.state.contentSize.height * this.state.scale;
            case 3:  //fit whole page (if pageEnable=true, force this)
                return this.state.contentSize.height * this.state.scale;
            case 0: //autofit, horizontal:fit width, vertical:fit height
            default: {
                if (this.props.horizontal) {
                    return this.state.contentSize.height * this.state.scale;
                } else {
                    return this.state.contentSize.width * (1 / this.state.pageAspectRate) * this.state.scale;
                }
            }
        }

    };

    _renderSeparator = () => (
        <View style={this.props.horizontal ? {
            width: this.props.spacing,
            backgroundColor: 'transparent'
        } : {height: this.props.spacing, backgroundColor: 'transparent'}}/>
    );

    _onItemPress = () => {

    };

    _onItemDoublePress = () => {

        if (this.state.scale >= MAX_SCALE) {
            this._onScale(1 / this.state.scale);
        } else {
            this._onScale(1.2);
        }

    };

    _onScale = (scale) => {

        let newScale = scale * this.state.scale;
        newScale = newScale > MAX_SCALE ? MAX_SCALE : newScale;
        newScale = newScale < 1 ? 1 : newScale;

        if (this.flatList && this.state.contentOffset) {
            this.flatList.scrollToOffset({
                animated: false,
                offset: (this.props.horizontal ? this.state.contentOffset.x : this.state.contentOffset.y) * scale
            });
        }

        this.setState({scale: newScale, scrollEnabed: false});

        if (this.scaleTimer) {
            clearTimeout(this.scaleTimer);
            this.scaleTimer = setTimeout(() => {
                this.setState({scrollEnabled: true});
            }, 1000);
        }

    };

    _renderItem = ({item, index}) => {

        return (
            <DoublePressView style={{flexDirection: this.props.horizontal ? 'row' : 'column'}}
                onPress={this._onItemPress}
                onDoublePress={this._onItemDoublePress}
            >
                <PdfPageView
                    key={item.id}
                    fileNo={this.state.fileNo}
                    page={item.key + 1}
                    style={{width: this._getPageWidth(), height: this._getPageHeight()}}
                />
                {(index !== this.state.numberOfPages - 1) && this._renderSeparator()}
            </DoublePressView>
        );

    };

    _onViewableItemsChanged = (viewableInfo) => {

        if (viewableInfo.viewableItems.length > 0) {
            if (this.props.onPageChanged) {
                this.props.onPageChanged(viewableInfo.viewableItems[0].index + 1, this.state.numberOfPages);
            }
        }

    };


    _renderList = () => {

        let data = [];
        for (let i = 0; i < this.state.numberOfPages; i++) {
            data[i] = {key: i};
        }

        if (this.state.page !== this.props.page) {
            this.timer = setTimeout(() => {
                if (this.flatList) {
                    this.flatList.scrollToIndex({animated: true, index: (this.props.page - 1)});
                    this.state.page = this.props.page;
                }
            }, 200);
        }

        return (
            <FlatList
                ref={(ref) => {
                    this.flatList = ref;
                }}
                style={this.props.style}
                contentContainerStyle={this.props.horizontal ? {height: this.state.contentSize.height * this.state.scale} : {width: this.state.contentSize.width * this.state.scale}}
                horizontal={this.props.horizontal}
                data={data}
                renderItem={this._renderItem}
                keyExtractor={this._keyExtractor}
                windowSize={11}
                getItemLayout={(data, index) => ({
                    length: this.props.horizontal ? this._getPageWidth() : this._getPageHeight(),
                    offset: ((this.props.horizontal ? this._getPageWidth() : this._getPageHeight()) + this.props.spacing) * index,
                    index
                })}
                maxToRenderPerBatch={1}
                removeClippedSubviews={true}
                /*initialScrollIndex={this.props.page - 1}*/ /* not action? */
                onViewableItemsChanged={this._onViewableItemsChanged}
                viewabilityConfig={{minimumViewTime: 500, itemVisiblePercentThreshold: 10, waitForInteraction: false}}
                onScroll={(e) => {
                    this.setState({contentOffset: e.nativeEvent.contentOffset});
                }}
                scrollEnabled={this.state.scrollEnabled}
            />
        );
    };


    render() {

        return (
            <PinchZoomView
                style={{flex: 1}}
                onLayout={(event) => {
                    this.setState({
                        contentSize: {
                            width: event.nativeEvent.layout.width,
                            height: event.nativeEvent.layout.height
                        }
                    });
                }}
                onScale={this._onScale}
            >
                {this.state.pdfLoaded ? this._renderList() : (null)}
            </PinchZoomView>
        );

    }

}