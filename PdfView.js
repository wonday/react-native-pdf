/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';
import React, {Component} from 'react';
import {ScrollView, View, StyleSheet} from 'react-native';
import {ViewPropTypes} from 'deprecated-react-native-prop-types';
import PropTypes from 'prop-types';

import PdfManager from './PdfManager';
import PdfPageView from './PdfPageView';
import DoubleTapView from './DoubleTapView';
import PinchZoomView from './PinchZoomView';
import PdfViewFlatList from './PdfViewFlatList';

const MIN_SCALE = 1;
const MAX_SCALE = 3;

const VIEWABILITYCONFIG = {minimumViewTime: 500, itemVisiblePercentThreshold: 10, waitForInteraction: false};

export default class PdfView extends Component {

    static propTypes = {
        ...ViewPropTypes,
        path: PropTypes.string,
        password: PropTypes.string,
        scale: PropTypes.number,
        minScale: PropTypes.number,
        maxScale: PropTypes.number,
        spacing: PropTypes.number,
        fitPolicy: PropTypes.number,
        horizontal: PropTypes.bool,
        page: PropTypes.number,
        currentPage: PropTypes.number,
        singlePage: PropTypes.bool,
        onPageSingleTap: PropTypes.func,
        onScaleChanged: PropTypes.func,
    };

    static defaultProps = {
        path: "",
        password: "",
        scale: 1,
        minScale: MIN_SCALE,
        maxScale: MAX_SCALE,
        spacing: 10,
        style: {},
        progressContainerStyle: {},
        fitPolicy: 2,
        horizontal: false,
        centerContent: false,
        page: 1,
        currentPage: -1,
        enablePaging: false,
        singlePage: false,
        onPageSingleTap: (page, x, y) => {
        },
        onScaleChanged: (scale) => {
        },
    };

    constructor(props) {

        super(props);
        this.state = {
            pdfLoaded: false,
            fileNo: -1,
            numberOfPages: 0,
            page: -1,
            currentPage: -1,
            pageAspectRate: 0.5,
            pdfPageSize: {width: 0, height: 0},
            contentContainerSize: {width: 0, height: 0},
            scale: this.props.scale,
            contentOffset: {x: 0, y: 0},
            newContentOffset: {x: 0, y: 0},
        };

        this._flatList = null;
        this._scaleTimer = null;
        this._scrollTimer = null;
        this._mounted = false;

    }

    componentDidMount() {
        this._mounted = true;
        PdfManager.loadFile(this.props.path, this.props.password)
            .then((pdfInfo) => {
                if (this._mounted) {
                    const fileNo = pdfInfo[0];
                    const numberOfPages = pdfInfo[1];
                    const width = pdfInfo[2];
                    const height = pdfInfo[3];
                    const pageAspectRatio = height === 0 ? 1 : width / height;

                    this.setState({
                        pdfLoaded: true,
                        fileNo,
                        numberOfPages,
                        pageAspectRate: pageAspectRatio,
                        pdfPageSize: {width, height},
                        centerContent: numberOfPages > 1 ? false : true
                    });
                    if (this.props.onLoadComplete) {
                        this.props.onLoadComplete(numberOfPages, this.props.path, {width, height});
                    }
                }

            })
            .catch((error) => {
                this.props.onError(error);
            });

        clearTimeout(this._scrollTimer);
        this._scrollTimer = setTimeout(() => {
            if (this._flatList) {
                this._flatList.scrollToIndex({animated: false, index: this.props.page < 1 ? 0 : this.props.page - 1});
            }
        }, 200);
    }

    componentDidUpdate(prevProps) {

        if (this.props.scale !== this.state.scale) {
            this._onScaleChanged({
                scale: this.props.scale / this.state.scale,
                pageX: this.state.contentContainerSize.width / 2,
                pageY: this.state.contentContainerSize.height / 2
            });
        }

        if (this.props.horizontal !== prevProps.horizontal || this.props.page !== prevProps.page) {
            let page = (this.props.page) < 1 ? 1 : this.props.page;
            page = page > this.state.numberOfPages ? this.state.numberOfPages : page;

            if (this._flatList) {
                clearTimeout(this._scrollTimer);
                this._scrollTimer = setTimeout(() => {
                    this._flatList.scrollToIndex({animated: false, index: page - 1});
                }, 200);
            }
        }

    }

    componentWillUnmount() {
        this._mounted = false;
        clearTimeout(this._scaleTimer);
        clearTimeout(this._scrollTimer);

    }

    _keyExtractor = (item, index) => "pdf-page-" + index;

    _getPageWidth = () => {

        let fitPolicy = this.props.fitPolicy;

        // if only one page, show whole page in center
        if (this.state.numberOfPages === 1 || this.props.singlePage) {
            fitPolicy = 2;
        }


        switch (fitPolicy) {
            case 0:  //fit width
                return this.state.contentContainerSize.width * this.state.scale;
            case 1:  //fit height
                return this.state.contentContainerSize.height * this.state.pageAspectRate * this.state.scale;
            case 2: //fit both
            default: {
                if (this.state.contentContainerSize.width/this.state.contentContainerSize.height<this.state.pageAspectRate) {
                    return this.state.contentContainerSize.width * this.state.scale;
                } else {
                    return this.state.contentContainerSize.height * this.state.pageAspectRate * this.state.scale;
                }
            }
        }

    };

    _getPageHeight = () => {

        let fitPolicy = this.props.fitPolicy;

        // if only one page, show whole page in center
        if (this.state.numberOfPages === 1 || this.props.singlePage) {
            fitPolicy = 2;
        }

        switch (fitPolicy) {
            case 0: //fit width
                return this.state.contentContainerSize.width * (1 / this.state.pageAspectRate) * this.state.scale;
            case 1: //fit height
                return this.state.contentContainerSize.height * this.state.scale;
            case 2: //fit both
            default: {
                if (this.state.contentContainerSize.width/this.state.contentContainerSize.height<this.state.pageAspectRate) {
                    return this.state.contentContainerSize.width * (1 / this.state.pageAspectRate) * this.state.scale;
                } else {
                    return this.state.contentContainerSize.height * this.state.scale;
                }
            }
        }

    };

    _renderSeparator = () => (
        <View style={this.props.horizontal ? {
            width: this.props.spacing * this.state.scale,
            backgroundColor: 'transparent'
        } : {
            height: this.props.spacing * this.state.scale,
            backgroundColor: 'transparent'
        }}/>
    );

    _onItemSingleTap = (index, x, y) => {

        this.props.onPageSingleTap(index + 1, x, y);

    };

    _onItemDoubleTap = (index) => {

        if (this.state.scale >= this.props.maxScale) {
            this._onScaleChanged({
                scale: 1 / this.state.scale,
                pageX: this.state.contentContainerSize.width / 2,
                pageY: this.state.contentContainerSize.height / 2
            });
        } else {
            this._onScaleChanged({
                scale: 1.2,
                pageX: this.state.contentContainerSize.width / 2,
                pageY: this.state.contentContainerSize.height / 2
            });
        }

    };

    _onScaleChanged = (pinchInfo) => {

        let newScale = pinchInfo.scale * this.state.scale;
        newScale = newScale > this.props.maxScale ? this.props.maxScale : newScale;
        newScale = newScale < this.props.minScale ? this.props.minScale : newScale;
        let newContentOffset = {
            x: (this.state.contentOffset.x + pinchInfo.pageX) * (newScale / this.state.scale) - pinchInfo.pageX,
            y: (this.state.contentOffset.y + pinchInfo.pageY) * (newScale / this.state.scale) - pinchInfo.pageY
        }
        this.setState({scale: newScale, newContentOffset: newContentOffset});
        this.props.onScaleChanged(newScale);

    };

    _renderItem = ({item, index}) => {
        const pageView = (
            <PdfPageView
                accessible={true}
                key={item.id}
                fileNo={this.state.fileNo}
                page={item.key + 1}
                width={this._getPageWidth()}
                height={this._getPageHeight()}
            />
        )

        if (this.props.singlePage) {
            return (
                <View style={{flexDirection: this.props.horizontal ? 'row' : 'column'}} >
                    {pageView}
                </View>
            )
        }

        return (
            <DoubleTapView style={{flexDirection: this.props.horizontal ? 'row' : 'column'}}
                           onSingleTap={(x, y) => {
                               this._onItemSingleTap(index, x, y);
                           }}
                           onDoubleTap={() => {
                               this._onItemDoubleTap(index);
                           }}
            >
                {pageView}
                {(index !== this.state.numberOfPages - 1) && this._renderSeparator()}
            </DoubleTapView>
        );

    };

    _onViewableItemsChanged = (viewableInfo) => {

        for (let i = 0; i < viewableInfo.viewableItems.length; i++) {
            this._onPageChanged(viewableInfo.viewableItems[i].index + 1, this.state.numberOfPages);
            if (viewableInfo.viewableItems.length + viewableInfo.viewableItems[0].index < this.state.numberOfPages) break;
        }

    };

    _onPageChanged = (page, numberOfPages) => {
        if (this.props.onPageChanged && this.state.currentPage !== page) {
            this.props.onPageChanged(page, numberOfPages);
            this.setState({currentPage: page});
        }
    };


    _getRef = (ref) => this._flatList = ref;

    _getItemLayout = (data, index) => ({
        length: this.props.horizontal ? this._getPageWidth() : this._getPageHeight(),
        offset: ((this.props.horizontal ? this._getPageWidth() : this._getPageHeight()) + this.props.spacing * this.state.scale) * index,
        index
    });

    _onScroll = (e) => {
        this.setState({contentOffset: e.nativeEvent.contentOffset, newContentOffset: e.nativeEvent.contentOffset});
    };

    _onListContentSizeChange = (contentWidth, contentHeight) => {
        if (this.state.contentOffset.x != this.state.newContentOffset.x
            || this.state.contentOffset.y != this.state.newContentOffset.y) {
            this._flatList.scrollToXY(this.state.newContentOffset.x, this.state.newContentOffset.y);
        }
    };

    _renderList = () => {
        let data = [];

        if (this.props.singlePage) {
            data[0] = {key: this.props.currentPage >= 0 ? this.props.currentPage : 0}
        } else {
            for (let i = 0; i < this.state.numberOfPages; i++) {
                data[i] = {key: i};
            }
        }

        return (
            <PdfViewFlatList
                ref={this._getRef}
                style={[styles.container, this.props.style]}
                pagingEnabled={this.props.enablePaging}
                contentContainerStyle={[{
                    justifyContent: 'center',
                    alignItems: 'center'
                }, this.props.horizontal ? {height: this.state.contentContainerSize.height * this.state.scale} : {width: this.state.contentContainerSize.width * this.state.scale}]}
                horizontal={this.props.horizontal}
                data={data}
                renderItem={this._renderItem}
                keyExtractor={this._keyExtractor}
                windowSize={11}
                getItemLayout={this._getItemLayout}
                maxToRenderPerBatch={1}
                renderScrollComponent={(props) => <ScrollView
                    {...props}
                    centerContent={this.state.centerContent}
                    pinchGestureEnabled={false}
                />}
                initialScrollIndex={this.props.page < 1 ? 0 : this.props.page - 1}
                onViewableItemsChanged={this._onViewableItemsChanged}
                viewabilityConfig={VIEWABILITYCONFIG}
                onScroll={this._onScroll}
                onContentSizeChange={this._onListContentSizeChange}
                scrollEnabled={!this.props.singlePage}
            />
        );

    };

    _onLayout = (event) => {
        this.setState({
            contentContainerSize: {
                width: event.nativeEvent.layout.width,
                height: event.nativeEvent.layout.height
            }
        });
    };


    render() {
        if (this.props.singlePage) {
            return (
                <View
                    style={styles.container}
                    onLayout={this._onLayout}
                >
                    {this.state.pdfLoaded && this._renderList()}
                </View>
            )
        }

        return (
            <PinchZoomView
                style={styles.container}
                onLayout={this._onLayout}
                onScaleChanged={this._onScaleChanged}
            >
                {this.state.pdfLoaded && this._renderList()}
            </PinchZoomView>
        );

    }

}

const styles = StyleSheet.create({
    container: {
        flex: 1
    }
});
