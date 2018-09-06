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
    requireNativeComponent,
    View,
    Platform,
    ProgressBarAndroid,
    ProgressViewIOS,
    ViewPropTypes,
    StyleSheet
} from 'react-native';

import RNFetchBlob from 'rn-fetch-blob';

const SHA1 = require('crypto-js/sha1');
import resolveAssetSource from 'react-native/Libraries/Image/resolveAssetSource';
import PdfView from './PdfView';

export default class Pdf extends Component {

    static propTypes = {
        ...ViewPropTypes,
        source: PropTypes.oneOfType([
            PropTypes.shape({
                uri: PropTypes.string,
                cache: PropTypes.bool,
                expiration: PropTypes.number,
            }),
            // Opaque type returned by require('./test.pdf')
            PropTypes.number,
        ]).isRequired,
        page: PropTypes.number,
        scale: PropTypes.number,
        horizontal: PropTypes.bool,
        spacing: PropTypes.number,
        password: PropTypes.string,
        progressBarColor: PropTypes.string,
        activityIndicator: PropTypes.any,
        activityIndicatorProps: PropTypes.any,
        enableAntialiasing: PropTypes.bool,
        enableAnnotationRendering: PropTypes.bool,
        enablePaging: PropTypes.bool,
        enableRTL: PropTypes.bool,
        fitPolicy: PropTypes.number,
        onLoadComplete: PropTypes.func,
        onPageChanged: PropTypes.func,
        onError: PropTypes.func,
        onPageSingleTap: PropTypes.func,
        onScaleChanged: PropTypes.func,

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
        spacing: 10,
        fitPolicy: 2, //fit both
        horizontal: false,
        page: 1,
        enableAntialiasing: true,
        enableAnnotationRendering: true,
        enablePaging: false,
        enableRTL: false,
        activityIndicatorProps: {color: '#009900', progressTintColor: '#009900'},
        onLoadProgress: (percent) => {
        },
        onLoadComplete: (numberOfPages, path) => {
        },
        onPageChanged: (page, numberOfPages) => {
        },
        onError: (error) => {
        },
        onPageSingleTap: (page) => {
        },
        onScaleChanged: (scale) => {
        },
    };

    constructor(props) {

        super(props);
        this.state = {
            path: '',
            isDownloaded: false,
            progress: 0,
            isSupportPDFKit: -1
        };

        this.lastRNBFTask = null;

    }

    componentWillReceiveProps(nextProps) {

        const nextSource = resolveAssetSource(nextProps.source);
        const curSource = resolveAssetSource(this.props.source);

        if ((nextSource.uri !== curSource.uri)) {
            // if has download task, then cancel it.
            if (this.lastRNBFTask) {
                this.lastRNBFTask.cancel(err => {
                    this._loadFromSource(nextProps.source);
                });
                this.lastRNBFTask = null;
            } else {
                this._loadFromSource(nextProps.source);
            }
        }
    }

    componentDidMount() {
        if (Platform.OS === "ios") {
            const PdfViewManagerNative = require('react-native').NativeModules.PdfViewManager;
            PdfViewManagerNative.supportPDFKit((isSupportPDFKit) => {
                this.setState({isSupportPDFKit: isSupportPDFKit ? 1 : 0});
            });
        }
        this._loadFromSource(this.props.source);
    }

    componentWillUnmount() {

        if (this.lastRNBFTask) {
            this.lastRNBFTask.cancel(err => {
            });
            this.lastRNBFTask = null;
        }

    }

    _loadFromSource = (newSource) => {

        const source = resolveAssetSource(newSource) || {};

        let uri = source.uri || '';

        // first set to initial state
        this.setState({isDownloaded: false, path: '', progress: 0});

        const cacheFile = RNFetchBlob.fs.dirs.CacheDir + '/' + SHA1(uri) + '.pdf';

        if (source.cache) {
            RNFetchBlob.fs
                .stat(cacheFile)
                .then(stats => {
                    if (!Boolean(source.expiration) || (source.expiration * 1000 + stats.lastModified) > (new Date().getTime())) {
                        this.setState({path: cacheFile, isDownloaded: true});
                    } else {
                        // cache expirated then reload it
                        this._prepareFile(source);
                    }
                })
                .catch(() => {
                    this._prepareFile(source);
                })

        } else {
            this._prepareFile(source);
        }
    };

    _prepareFile = async (source) => {

        try {
            if (source.uri) {
                let uri = source.uri || '';

                const isNetwork = !!(uri && uri.match(/^https?:\/\//));
                const isAsset = !!(uri && uri.match(/^bundle-assets:\/\//));
                const isBase64 = !!(uri && uri.match(/^data:application\/pdf;base64/));

                const cacheFile = RNFetchBlob.fs.dirs.CacheDir + '/' + SHA1(uri) + '.pdf';

                // delete old cache file
                this._unlinkFile(cacheFile);

                if (isNetwork) {
                    this._downloadFile(source, cacheFile);
                } else if (isAsset) {
                    RNFetchBlob.fs
                        .cp(uri, cacheFile)
                        .then(() => {
                            this.setState({path: cacheFile, isDownloaded: true, progress: 1});
                        })
                        .catch(async (error) => {
                            this._unlinkFile(cacheFile);
                            this._onError(error);
                        })
                } else if (isBase64) {
                    let data = uri.replace(/data:application\/pdf;base64,/i, '');
                    RNFetchBlob.fs
                        .writeFile(cacheFile, data, 'base64')
                        .then(() => {
                            this.setState({path: cacheFile, isDownloaded: true, progress: 1});
                        })
                        .catch(async (error) => {
                            this._unlinkFile(cacheFile);
                            this._onError(error)
                        });
                } else {
                    this.setState({
                        path: uri.replace(/file:\/\//i, ''),
                        isDownloaded: true,
                    });
                }
            } else {
                this._onError(new Error('no pdf source!'));
            }
        } catch (e) {
            this._onError(e)
        }


    };

    _downloadFile = async (source, cacheFile) => {

        if (this.lastRNBFTask) {
            this.lastRNBFTask.cancel(err => {
            });
            this.lastRNBFTask = null;
        }

        const tempCacheFile = cacheFile + '.tmp';
        this._unlinkFile(tempCacheFile);

        this.lastRNBFTask = RNFetchBlob.config({
            // response data will be saved to this path if it has access right.
            path: tempCacheFile,
        })
            .fetch(
                source.method ? source.method : 'GET',
                source.uri,
                source.headers ? source.headers : {},
                source.body ? source.body : ""
            )
            // listen to download progress event
            .progress((received, total) => {
                this.props.onLoadProgress && this.props.onLoadProgress(received / total);
                this.setState({progress: received / total});
            });

        this.lastRNBFTask
            .then(async (res) => {

                this.lastRNBFTask = null;

                if (res && res.respInfo && res.respInfo.headers && res.respInfo.headers["Content-Length"]) {
                    const expectedContentLength = res.respInfo.headers["Content-Length"];
                    let actualContentLength;

                    try {
                        const fileStats = await RNFetchBlob.fs.stat(res.path());

                        if (!fileStats || !fileStats.size) {
                            throw new Error("FileNotFound:" + url);
                        }

                        actualContentLength = fileStats.size;
                    } catch (error) {
                        throw new Error("DownloadFailed:" + url);
                    }

                    if (expectedContentLength != actualContentLength) {
                        throw new Error("DownloadFailed:" + url);
                    }
                }

                this._unlinkFile(cacheFile);
                RNFetchBlob.fs
                    .cp(tempCacheFile, cacheFile)
                    .then(() => {
                        this.setState({path: cacheFile, isDownloaded: true, progress: 1});
                    })
                    .catch(async (error) => {
                        throw error;
                    });
            })
            .catch(async (error) => {
                this._unlinkFile(tempCacheFile);
                this._unlinkFile(cacheFile);
                this._onError(error);
            });

    };

    _unlinkFile = async (file) => {
        try {
            await RNFetchBlob.fs.unlink(file);
        } catch (e) {

        }
    }

    setNativeProps = nativeProps => {

        this._root.setNativeProps(nativeProps);

    };

    _onChange = (event) => {

        let message = event.nativeEvent.message.split('|');
        //__DEV__ && console.log("onChange: " + message);
        if (message.length > 0) {
            if (message[0] === 'loadComplete') {
                this.props.onLoadComplete && this.props.onLoadComplete(Number(message[1]), this.state.path, {
                    width: Number(message[2]),
                    height: Number(message[3])
                });
            } else if (message[0] === 'pageChanged') {
                this.props.onPageChanged && this.props.onPageChanged(Number(message[1]), Number(message[2]));
            } else if (message[0] === 'error') {
                this._onError(new Error(message[1]));
            } else if (message[0] === 'pageSingleTap') {
                this.props.onPageSingleTap && this.props.onPageSingleTap(message[1]);
            } else if (message[0] === 'scaleChanged') {
                this.props.onScaleChanged && this.props.onScaleChanged(message[1]);
            }
        }

    };

    _onError = (error) => {

        this.props.onError && this.props.onError(error);

    };

    render() {

        if (!this.state.isDownloaded) {
            return (
                <View
                    style={styles.progressContainer}
                >
                    {this.props.activityIndicator
                        ? this.props.activityIndicator
                        : Platform.OS === 'android'
                            ? <ProgressBarAndroid
                                progress={this.state.progress}
                                indeterminate={false}
                                styleAttr="Horizontal"
                                style={styles.progressBar}
                                {...this.props.activityIndicatorProps}
                            />
                            : <ProgressViewIOS
                                progress={this.state.progress}
                                style={styles.progressBar}
                                {...this.props.activityIndicatorProps}
                            />}
                </View>
            )
        } else {
            if (Platform.OS === "android") {
                return (
                    <PdfCustom
                        ref={component => (this._root = component)}
                        {...this.props}
                        style={[{backgroundColor: '#EEE'}, this.props.style]}
                        path={this.state.path}
                        onChange={this._onChange}
                    />
                );
            } else if (Platform.OS === "ios") {
                if (this.state.isSupportPDFKit === 1) {
                    return (
                        <PdfCustom
                            ref={component => (this._root = component)}
                            {...this.props}
                            style={[{backgroundColor: '#EEE'}, this.props.style]}
                            path={this.state.path}
                            onChange={this._onChange}
                        />
                    );
                } else if (this.state.isSupportPDFKit === 0) {
                    return (
                        <PdfView
                            {...this.props}
                            style={[{backgroundColor: '#EEE'}, this.props.style]}
                            path={this.state.path}
                            onLoadComplete={this.props.onLoadComplete}
                            onPageChanged={this.props.onPageChanged}
                            onError={this._onError}
                            onPageSingleTap={this.props.onPageSingleTap}
                            onScaleChanged={this.props.onScaleChanged}
                        />
                    );
                } else {
                    return (null);
                }
            } else {
                return (null);
            }
        }

    }
}


if (Platform.OS === "android") {
    var PdfCustom = requireNativeComponent('RCTPdf', Pdf, {
        nativeOnly: {path: true, onChange: true},
    })
} else if (Platform.OS === "ios") {
    var PdfCustom = requireNativeComponent('RCTPdfView', Pdf, {
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