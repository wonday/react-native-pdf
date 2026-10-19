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
import {View, Platform, StyleSheet, Text, requireNativeComponent} from 'react-native';
import PdfViewNativeComponent, {
    Commands as PdfViewCommands,
} from './fabric/RNPDFPdfNativeComponent';

let PdfView;

const getPdfView = () => {
    if (!PdfView) {
        const module = require('./PdfView');
        PdfView = module.default || module;
    }

    return PdfView;
};

export default class PdfRenderer extends Component {

    static propTypes = {
        page: PropTypes.number,
        scale: PropTypes.number,
        minScale: PropTypes.number,
        maxScale: PropTypes.number,
        horizontal: PropTypes.bool,
        spacing: PropTypes.number,
        password: PropTypes.string,
        renderActivityIndicator: PropTypes.func,
        enableAntialiasing: PropTypes.bool,
        enableAnnotationRendering: PropTypes.bool,
        showsHorizontalScrollIndicator: PropTypes.bool,
        showsVerticalScrollIndicator: PropTypes.bool,
        directionalLockEnabled: PropTypes.bool,
        scrollEnabled: PropTypes.bool,
        enablePaging: PropTypes.bool,
        enableRTL: PropTypes.bool,
        fitPolicy: PropTypes.number,
        singlePage: PropTypes.bool,
        onLoadComplete: PropTypes.func,
        onPageChanged: PropTypes.func,
        onError: PropTypes.func,
        onPageSingleTap: PropTypes.func,
        onScaleChanged: PropTypes.func,
        onPressLink: PropTypes.func,
        enableTextSelection: PropTypes.bool,
        onTextSelectionChange: PropTypes.func,

        // Props that are not available in the earlier react native version, added to prevent crashed on android
        accessibilityLabel: PropTypes.string,
        importantForAccessibility: PropTypes.string,
        renderToHardwareTextureAndroid: PropTypes.string,
        testID: PropTypes.string,
        onLayout: PropTypes.bool,
        accessibilityLiveRegion: PropTypes.string,
        accessibilityComponentType: PropTypes.string,
    };

    static defaultProps = {
        password: "",
        scale: 1,
        minScale: 1,
        maxScale: 3,
        spacing: 10,
        fitPolicy: 2, //fit both
        horizontal: false,
        page: 1,
        enableAntialiasing: true,
        enableAnnotationRendering: true,
        showsHorizontalScrollIndicator: true,
        showsVerticalScrollIndicator: true,
        directionalLockEnabled: false,
        scrollEnabled: true,
        enablePaging: false,
        enableRTL: false,
        usePDFKit: true,
        singlePage: false,
        onLoadProgress: (percent) => {
        },
        onLoadComplete: (numberOfPages, path) => {
        },
        onPageChanged: (page, numberOfPages) => {
        },
        onError: (error) => {
        },
        onPageSingleTap: (page, x, y) => {
        },
        onScaleChanged: (scale) => {
        },
        onPressLink: (url) => {
        },
        enableTextSelection: true,
        onTextSelectionChange: (event) => {
        },
    };

    constructor(props) {

        super(props);
        this.state = {
            path: '',
            isDownloaded: false,
            progress: 0,
        };

    }

    setNativeProps = nativeProps => {
        if (this._root){
            this._root.setNativeProps(nativeProps);
        }
    };

    setPage( pageNumber ) {
        if ( (pageNumber === null) || (isNaN(pageNumber)) ) {
            throw new Error('Specified pageNumber is not a number');
        }
        if (!!global?.nativeFabricUIManager ) {
            if (this._root) {
                PdfViewCommands.setNativePage(
                    this._root,
                    pageNumber,
                );
            }
          } else {
            this.setNativeProps({
                page: pageNumber
            });
          }

    }

    _onChange = (event) => {
        // Handle direct events for text selection/highlight
        if (event.nativeEvent.type) {
            this.props.onTextSelectionChange && this.props.onTextSelectionChange(event);
            return;
        }

        let message = event.nativeEvent.message.split('|');
        //__DEV__ && console.log("onChange: " + message);
        if (message.length > 0) {

            // Handle text selection messages
            if (message[0] === 'textSelected') {
                this.props.onTextSelectionChange && this.props.onTextSelectionChange({
                    nativeEvent: { type: 'selectionChanged', text: message.slice(1).join('|') }
                });
                return;
            } else if (message[0] === 'textSelectionCleared') {
                this.props.onTextSelectionChange && this.props.onTextSelectionChange({
                    nativeEvent: { type: 'selectionCleared' }
                });
                return;
            }

            if (message.length > 5) {
                message[4] = message.splice(4).join('|');
            }
            if (message[0] === 'loadComplete') {
                let tableContents;
                try {
                    tableContents = message[4]&&JSON.parse(message[4]);
                } catch(e) {
                    tableContents = message[4];
                }
                this.props.onLoadComplete && this.props.onLoadComplete(Number(message[1]), this.state.path, {
                    width: Number(message[2]),
                    height: Number(message[3]),
                },
                tableContents
                );
            } else if (message[0] === 'pageChanged') {
                this.props.onPageChanged && this.props.onPageChanged(Number(message[1]), Number(message[2]));
            } else if (message[0] === 'error') {
                this._onError(new Error(message[1]));
            } else if (message[0] === 'pageSingleTap') {
                this.props.onPageSingleTap && this.props.onPageSingleTap(Number(message[1]), Number(message[2]), Number(message[3]));
            } else if (message[0] === 'scaleChanged') {
                this.props.onScaleChanged && this.props.onScaleChanged(Number(message[1]));
            } else if (message[0] === 'linkPressed') {
                this.props.onPressLink && this.props.onPressLink(message[1]);
            }
        }

    };

    _onError = (error) => {

        this.props.onError && this.props.onError(error);

    };

    render() {
        if (Platform.OS === "android" || Platform.OS === "ios" || Platform.OS === "windows") {
                return (
                    <View style={[this.props.style,{overflow: 'hidden'}]}>
                        {!this.state.isDownloaded?
                            (<View
                                style={[styles.progressContainer, this.props.progressContainerStyle]}
                            >
                                {this.props.renderActivityIndicator
                                    ? this.props.renderActivityIndicator(this.state.progress)
                                    : <Text>{`${(this.state.progress * 100).toFixed(2)}%`}</Text>}
                            </View>):(
                                Platform.OS === "android" || Platform.OS === "windows"?(
                                        <PdfCustom
                                            ref={component => (this._root = component)}
                                            {...this.props}
                                            style={[{flex:1,backgroundColor: '#EEE'}, this.props.style]}
                                            path={this.state.path}
                                            onChange={this._onChange}
                                        />
                                    ):(
                                        this.props.usePDFKit ?(
                                                <PdfCustom
                                                    ref={component => (this._root = component)}
                                                    {...this.props}
                                                    style={[{backgroundColor: '#EEE',overflow: 'hidden'}, this.props.style]}
                                                    path={this.state.path}
                                                    onChange={this._onChange}
                                                />
                                            ):(React.createElement(getPdfView(), {
                                                ...this.props,
                                                style: [{backgroundColor: '#EEE',overflow: 'hidden'}, this.props.style],
                                                path: this.state.path,
                                                onLoadComplete: this.props.onLoadComplete,
                                                onPageChanged: this.props.onPageChanged,
                                                onError: this._onError,
                                                onPageSingleTap: this.props.onPageSingleTap,
                                                onScaleChanged: this.props.onScaleChanged,
                                                onPressLink: this.props.onPressLink,
                                            }))
                                    )
                                )}
                    </View>);
        } else {
            return (null);
        }


    }
}

if (Platform.OS === "android" || Platform.OS === "ios") {
    var PdfCustom = PdfViewNativeComponent;
}  else if (Platform.OS === "windows") {
    var PdfCustom = requireNativeComponent('RCTPdf', PdfRenderer, {
        nativeOnly: {path: true, onChange: true},
    })
}

const styles = StyleSheet.create({
    progressContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center'
    },
    progressBar: {
        width: 200,
        height: 2
    }
});
