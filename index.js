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

import RNFetchBlob from 'react-native-fetch-blob';

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
                    if (!!!source.expiration || (source.expiration * 1000 + stats.lastModified) < (new Date().getTime())) {
                        // cache expirated then reload it
                        this._prepareFile(source);
                    } else {
                        this.setState({path: cacheFile, isDownloaded: true});
                    }
                })
                .catch(() => {
                    this._prepareFile(source);
                })

        } else {
            this._prepareFile(source);
        }
    };

    _prepareFile = (source) => {

        if (source.uri) {
            let uri = source.uri || '';

            const isNetwork = !!(uri && uri.match(/^https?:\/\//));
            const isAsset = !!(uri && uri.match(/^bundle-assets:\/\//));
            const isBase64 = !!(uri && uri.match(/^data:application\/pdf;base64/));

            const cacheFile = RNFetchBlob.fs.dirs.CacheDir + '/' + SHA1(uri) + '.pdf';

            // delete old cache file
            RNFetchBlob.fs.unlink(cacheFile);

            if (isNetwork) {
                this._downloadFile(source, cacheFile);
            } else if (isAsset) {
                RNFetchBlob.fs
                    .cp(uri, cacheFile)
                    .then(() => {
                        this.setState({path: cacheFile, isDownloaded: true});
                    })
                    .catch(error => {
                        RNFetchBlob.fs.unlink(cacheFile);
                        this._onError(error);
                    })
            } else if (isBase64) {
                let data = uri.replace(/data:application\/pdf;base64,/i, '');
                RNFetchBlob.fs
                    .writeFile(cacheFile, data, 'base64')
                    .then(() => {
                        //__DEV__ && console.log("write base64 to file:" + cacheFile);
                        this.setState({path: cacheFile, isDownloaded: true});
                    })
                    .catch(error => {
                        RNFetchBlob.fs.unlink(cacheFile);
                        this._onError(error)
                    });
            } else {
                //__DEV__ && console.log("default source type as file");
                this.setState({
                    path: uri.replace(/file:\/\//i, ''),
                    isDownloaded: true,
                });
            }
        } else {
            this._onError(new Error('no pdf source!'));
        }

    };

    _downloadFile = (source, cacheFile) => {

        if (this.lastRNBFTask) {
            this.lastRNBFTask.cancel(err => {
            });
            this.lastRNBFTask = null;
        }

        const tempCacheFile = cacheFile + '.tmp';
        RNFetchBlob.fs.unlink(tempCacheFile);

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
            .then(res => {
                let {status} = res.respInfo;
                this.lastRNBFTask = null;

                switch (status) {
                    case 200: /* OK */
                    case 204: /* No content */
                    case 304: /* Not modified */
                    {
                        RNFetchBlob.fs.unlink(cacheFile)
                            .then(() => {
                                RNFetchBlob.fs
                                    .cp(tempCacheFile, cacheFile)
                                    .then(() => {
                                        this.setState({path: cacheFile, isDownloaded: true, progress: 1});
                                    })
                                    .catch(error => {
                                        RNFetchBlob.fs.unlink(tempCacheFile);
                                        RNFetchBlob.fs.unlink(cacheFile);
                                        this._onError(error)
                                    })
                            })
                            .catch(error => {
                                RNFetchBlob.fs.unlink(tempCacheFile);
                                RNFetchBlob.fs.unlink(cacheFile);
                                this._onError(error)
                            });
                        break;
                    }
                    default:
                        RNFetchBlob.fs.unlink(tempCacheFile);
                        RNFetchBlob.fs.unlink(cacheFile);
                        this._onError(new Error(`load pdf failed with code ${status}`));
                        break;
                }
            })
            .catch(error => {
                RNFetchBlob.fs.unlink(tempCacheFile);
                RNFetchBlob.fs.unlink(cacheFile);
                this._onError(error);
            });

    };

    setNativeProps = nativeProps => {

        this._root.setNativeProps(nativeProps);

    };

    _onChange = (event) => {

        let message = event.nativeEvent.message.split('|');
        //__DEV__ && console.log("onChange: " + message);
        if (message.length > 0) {
            if (message[0] === 'loadComplete') {
                this.props.onLoadComplete && this.props.onLoadComplete(Number(message[1]), this.state.path);
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
        }

    }
}


if (Platform.OS === "android") {
    var PdfCustom = requireNativeComponent('RCTPdf', Pdf, {
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
