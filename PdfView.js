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
import DoubleTapView from './DoubleTapView';
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
        onPageSingleTap: PropTypes.func,
        onScaleChanged: PropTypes.func,
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
        onPageSingleTap: (page)=>{},
        onScaleChanged: (scale)=>{},
    };

    constructor(props) {

        super(props);
        this.state = {
            pdfLoaded: false,
            fileNo: -1,
            numberOfPages: 0,
            page: -1,
            pageAspectRate: 0.5,
            contentContainerSize: {width: 0, height: 0},
            scale: 1,
            contentOffset: {x:0, y:0},
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
            this.onScaleChanged(nextProps.scale / this.state.scale);
        }

    }

    componentWillUnmount() {

        clearTimeout(this.scaleTimer);

    }

    _keyExtractor = (item, index) => index;

    _getPageWidth = () => {

        // if only one page, show whole page in center
        if (this.state.numberOfPages===1) {
            return this.state.contentContainerSize.width * this.state.scale;
        }


        switch (this.props.fitPolicy) {
            case 0:  //fit width
                return this.state.contentContainerSize.width * this.state.scale;
            case 1:  //fit height
                return this.state.contentContainerSize.height * this.state.pageAspectRate * this.state.scale;
            case 2: //fit both
            default: {
                if ((this.state.contentContainerSize.width/this.state.contentContainerSize.height) > this.state.pageAspectRate) {
                    return this.state.contentContainerSize.height * this.state.scale * this.state.pageAspectRate;
                } else {
                    return this.state.contentContainerSize.width * this.state.scale;
                }
            }
        }

    };

    _getPageHeight = () => {

        // if only one page, show whole page in center
        if (this.state.numberOfPages===1) {
            return this.state.contentContainerSize.height * this.state.scale;
        }

        switch (this.props.fitPolicy) {
            case 0: //fit width
                return this.state.contentContainerSize.width * (1 / this.state.pageAspectRate) * this.state.scale;
            case 1: //fit height
                return this.state.contentContainerSize.height * this.state.scale;
            case 2: //fit both
            default: {
                if ((this.state.contentContainerSize.width/this.state.contentContainerSize.height) > this.state.pageAspectRate) {
                    return this.state.contentContainerSize.height * this.state.scale;
                } else {

                    return this.state.contentContainerSize.width * (1 / this.state.pageAspectRate) * this.state.scale;
                }
            }
        }

    };

    _renderSeparator = () => (
        <View style={this.props.horizontal ? {
            width: this.props.spacing*this.state.scale,
            backgroundColor: 'transparent'
        } : {
            height: this.props.spacing*this.state.scale,
            backgroundColor: 'transparent'
        }}/>
    );

    _onItemSingleTap = (index) => {

        this.props.onPageSingleTap(index+1);

    };

    _onItemDoubleTap = (index) => {

        if (this.state.scale >= MAX_SCALE) {
            this.onScaleChanged(1 / this.state.scale);
        } else {
            this.onScaleChanged(1.2);
        }

    };

    _onScaleChanged = (scale, center) => {

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
        this.props.onScaleChanged(newScale);

        if (this.scaleTimer) {
            clearTimeout(this.scaleTimer);
            this.scaleTimer = setTimeout(() => {
                this.setState({scrollEnabled: true});
            }, 1000);
        }

    };

    _renderItem = ({item, index}) => {

        return (
            <DoubleTapView style={{flexDirection: this.props.horizontal ? 'row' : 'column'}}
                onSingleTap={()=>this._onItemSingleTap(index)}
                onDoubleTap={()=>this._onItemDoubleTap(index)}
            >
                <PdfPageView
                    key={item.id}
                    fileNo={this.state.fileNo}
                    page={item.key + 1}
                    style={{width: this._getPageWidth(), height: this._getPageHeight()}}
                />
                {(index !== this.state.numberOfPages - 1) && this._renderSeparator()}
            </DoubleTapView>
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
                contentContainerStyle={this.props.horizontal ? {height: this.state.contentContainerSize.height * this.state.scale} : {width: this.state.contentContainerSize.width * this.state.scale}}
                horizontal={this.props.horizontal}
                data={data}
                renderItem={this._renderItem}
                keyExtractor={this._keyExtractor}
                windowSize={11}
                getItemLayout={(data, index) => ({
                    length: this.props.horizontal ? this._getPageWidth() : this._getPageHeight(),
                    offset: ((this.props.horizontal ? this._getPageWidth() : this._getPageHeight()) + this.props.spacing*this.state.scale) * index,
                    index
                })}
                maxToRenderPerBatch={1}
                removeClippedSubviews={true}
                /*initialScrollIndex={this.props.page - 1}*/ /* not action? */
                onViewableItemsChanged={this._onViewableItemsChanged}
                viewabilityConfig={{minimumViewTime: 500, itemVisiblePercentThreshold: 10, waitForInteraction: false}}
                onScroll={(e) => {
                    this.state.scrollEnabled && this.setState({contentOffset: e.nativeEvent.contentOffset});
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
                        contentContainerSize: {
                            width: event.nativeEvent.layout.width,
                            height: event.nativeEvent.layout.height
                        }
                    });
                }}
                onScaleChanged={this._onScaleChanged}
            >
                {this.state.pdfLoaded ? this._renderList() : (null)}
            </PinchZoomView>
        );

    }

}