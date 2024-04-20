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
    View,
    Platform,
    StyleSheet,
    Image,
    Text,
    requireNativeComponent
} from 'react-native';
import PdfViewNativeComponent, {
    Commands as PdfViewCommands,
  } from './fabric/RNPDFPdfNativeComponent';
import ReactNativeBlobUtil from 'react-native-blob-util'
import {ViewPropTypes} from 'deprecated-react-native-prop-types';
const SHA1 = require('crypto-js/sha1');
import PdfView from './PdfView';

export default class Pdf extends Component {

    static propTypes = {
        ...ViewPropTypes,
        source: PropTypes.oneOfType([
            PropTypes.shape({
                uri: PropTypes.string,
                cache: PropTypes.bool,
                cacheFileName: PropTypes.string,
                expiration: PropTypes.number,
            }),
            // Opaque type returned by require('./test.pdf')
            PropTypes.number,
        ]).isRequired,
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
        enablePaging: PropTypes.bool,
        enableRTL: PropTypes.bool,
        fitPolicy: PropTypes.number,
        trustAllCerts: PropTypes.bool,
        singlePage: PropTypes.bool,
        onLoadComplete: PropTypes.func,
        onPageChanged: PropTypes.func,
        onError: PropTypes.func,
        onPageSingleTap: PropTypes.func,
        onScaleChanged: PropTypes.func,
        onPressLink: PropTypes.func,

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
        enablePaging: false,
        enableRTL: false,
        trustAllCerts: true,
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

    componentDidUpdate(prevProps) {

        const nextSource = Image.resolveAssetSource(this.props.source);
        const curSource = Image.resolveAssetSource(prevProps.source);

        if ((nextSource.uri !== curSource.uri)) {
            // if has download task, then cancel it.
            if (this.lastRNBFTask) {
                this.lastRNBFTask.cancel(err => {
                    this._loadFromSource(this.props.source);
                });
                this.lastRNBFTask = null;
            } else {
                this._loadFromSource(this.props.source);
            }
        }
    }

    componentDidMount() {
        this._mounted = true;
        this._loadFromSource(this.props.source);
    }

    componentWillUnmount() {
        this._mounted = false;
        if (this.lastRNBFTask) {
            // this.lastRNBFTask.cancel(err => {
            // });
            this.lastRNBFTask = null;
        }

    }

    _loadFromSource = (newSource) => {

        const source = Image.resolveAssetSource(newSource) || {};

        let uri = source.uri || '';
        // first set to initial state
        if (this._mounted) {
            this.setState({isDownloaded: false, path: '', progress: 0});
        }
        const filename = source.cacheFileName || SHA1(uri) + '.pdf';
        const cacheFile = ReactNativeBlobUtil.fs.dirs.CacheDir + '/' + filename;

        if (source.cache) {
            ReactNativeBlobUtil.fs
                .stat(cacheFile)
                .then(stats => {
                    if (!Boolean(source.expiration) || (source.expiration * 1000 + stats.lastModified) > (new Date().getTime())) {
                        if (this._mounted) {
                            this.setState({path: cacheFile, isDownloaded: true});
                        }
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

                const filename = source.cacheFileName || SHA1(uri) + '.pdf';
                const cacheFile = ReactNativeBlobUtil.fs.dirs.CacheDir + '/' + filename;

                // delete old cache file
                this._unlinkFile(cacheFile);

                if (isNetwork) {
                    this._downloadFile(source, cacheFile);
                } else if (isAsset) {
                    ReactNativeBlobUtil.fs
                        .cp(uri, cacheFile)
                        .then(() => {
                            if (this._mounted) {
                                this.setState({path: cacheFile, isDownloaded: true, progress: 1});
                            }
                        })
                        .catch(async (error) => {
                            this._unlinkFile(cacheFile);
                            this._onError(error);
                        })
                } else if (isBase64) {
                    let data = uri.replace(/data:application\/pdf;base64,/i, '');
                    ReactNativeBlobUtil.fs
                        .writeFile(cacheFile, data, 'base64')
                        .then(() => {
                            if (this._mounted) {
                                this.setState({path: cacheFile, isDownloaded: true, progress: 1});
                            }
                        })
                        .catch(async (error) => {
                            this._unlinkFile(cacheFile);
                            this._onError(error)
                        });
                } else {
                    if (this._mounted) {
                       this.setState({
                            path: unescape(uri.replace(/file:\/\//i, '')),
                            isDownloaded: true,
                        });
                    }
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

        this.lastRNBFTask = ReactNativeBlobUtil.config({
            // response data will be saved to this path if it has access right.
            path: tempCacheFile,
            trusty: this.props.trustAllCerts,
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
                if (this._mounted) {
                    this.setState({progress: received / total});
                }
            })
            .catch(async (error) => {
                this._onError(error);
            });

        this.lastRNBFTask
            .then(async (res) => {

                this.lastRNBFTask = null;

                if (res && res.respInfo && res.respInfo.headers && !res.respInfo.headers["Content-Encoding"] && !res.respInfo.headers["Transfer-Encoding"] && res.respInfo.headers["Content-Length"]) {
                    const expectedContentLength = res.respInfo.headers["Content-Length"];
                    let actualContentLength;

                    try {
                        const fileStats = await ReactNativeBlobUtil.fs.stat(res.path());

                        if (!fileStats || !fileStats.size) {
                            throw new Error("FileNotFound:" + source.uri);
                        }

                        actualContentLength = fileStats.size;
                    } catch (error) {
                        throw new Error("DownloadFailed:" + source.uri);
                    }

                    if (expectedContentLength != actualContentLength) {
                        throw new Error("DownloadFailed:" + source.uri);
                    }
                }

                this._unlinkFile(cacheFile);
                ReactNativeBlobUtil.fs
                    .cp(tempCacheFile, cacheFile)
                    .then(() => {
                        if (this._mounted) {
                            this.setState({path: cacheFile, isDownloaded: true, progress: 1});
                        }
                        this._unlinkFile(tempCacheFile);
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
            await ReactNativeBlobUtil.fs.unlink(file);
        } catch (e) {

        }
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

        let message = event.nativeEvent.message.split('|');
        //__DEV__ && console.log("onChange: " + message);
        if (message.length > 0) {
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
                                            ):(<PdfView
                                                {...this.props}
                                                style={[{backgroundColor: '#EEE',overflow: 'hidden'}, this.props.style]}
                                                path={this.state.path}
                                                onLoadComplete={this.props.onLoadComplete}
                                                onPageChanged={this.props.onPageChanged}
                                                onError={this._onError}
                                                onPageSingleTap={this.props.onPageSingleTap}
                                                onScaleChanged={this.props.onScaleChanged}
                                                onPressLink={this.props.onPressLink}
                                            />)
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
