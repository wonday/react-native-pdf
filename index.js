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
const SHA1 = require('crypto-js/sha1');

let PdfView;

const getPdfView = () => {
    if (!PdfView) {
        const module = require('./PdfView');
        PdfView = module.default || module;
    }

    return PdfView;
};

export default class Pdf extends Component {

    static propTypes = {
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
        directionalLockEnabled: PropTypes.bool,
        scrollEnabled: PropTypes.bool,
        enablePaging: PropTypes.bool,
        enableRTL: PropTypes.bool,
        fitPolicy: PropTypes.number,
        trustAllCerts: PropTypes.bool,
        singlePage: PropTypes.bool,
        transformFile: PropTypes.bool,
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
        trustAllCerts: true,
        usePDFKit: true,
        singlePage: false,
        transformFile: false,
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

        this.lastRNBFTask = null;
        this.lastViewFile = null;
    }

    componentDidUpdate(prevProps) {

        const nextSource = Image.resolveAssetSource(this.props.source);
        const curSource = Image.resolveAssetSource(prevProps.source);

        if ((nextSource.uri !== curSource.uri)) {
            // if has download task, then cancel it.
            if (this.lastRNBFTask && this.lastRNBFTask.cancel) {
                this.lastRNBFTask.cancel(err => {
                    this._cleanupViewFile();
                    this._loadFromSource(this.props.source);
                });
                this.lastRNBFTask = null;
            } else {
                this._cleanupViewFile();
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

        if (!this.props.cache) {
            if (this.props.transformFile) {
                // this.state.path is the .view file; unlink the original pre-transformed file.
                // The .view file is cleaned up by _cleanupViewFile below.
                if (this.lastPreTransformedPath) {
                    this._unlinkFile(this.lastPreTransformedPath);
                }
            } else {
                this._unlinkFile(this.state.path);
            }
        }

        this._cleanupViewFile();

    }

    _cleanupViewFile = () => {
        if (this.lastViewFile) {
            this._unlinkFile(this.lastViewFile);
            this.lastViewFile = null;
        }
    };

    _transformToViewFile = async (preTransformedPath) => {
        const viewFile = preTransformedPath + '.view';
        this._unlinkFile(viewFile);
        const base64 = await ReactNativeBlobUtil.fs.readFileWithTransform(preTransformedPath, 'base64');
        await ReactNativeBlobUtil.fs.writeFile(viewFile, base64, 'base64');
        this.lastViewFile = viewFile;
        this.lastPreTransformedPath = preTransformedPath;
        return viewFile;
    };

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
                .then(async stats => {
                    if (!Boolean(source.expiration) || (source.expiration * 1000 + stats.lastModified) > (new Date().getTime())) {
                        try {
                            const finalPath = this.props.transformFile
                                ? await this._transformToViewFile(cacheFile)
                                : cacheFile;
                            if (this._mounted) {
                                this.setState({path: finalPath, isDownloaded: true});
                            }
                        } catch (e) {
                            this._onError(e);
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
                      const localPath = decodeURIComponent(uri.replace(/file:\/\//i, ''));
                      if (this.props.transformFile) {
                          try {
                              const viewFile = await this._transformToViewFile(localPath);
                              if (this._mounted) {
                                  this.setState({
                                      path: viewFile,
                                      isDownloaded: true,
                                  });
                              }
                          } catch (e) {
                              this._onError(e);
                          }
                      } else {
                          this.setState({
                              path: localPath,
                              isDownloaded: true,
                          });
                      }
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
            try {
                this.lastRNBFTask.cancel(err => {
                });
            } catch (e) {
                // ignore — cancel can fail if the task already settled
            }
            this.lastRNBFTask = null;
        }

        const tempCacheFile = cacheFile + '.tmp';
        // Await the unlink: a fire-and-forget call here lets ReactNativeBlobUtil's
        // open(path) race with the in-flight delete on Android 14 + New Architecture and
        // surface as `ENOENT (No such file or directory)` on the temp file. See #1018.
        await this._unlinkFile(tempCacheFile);

        try {
            this.lastRNBFTask = ReactNativeBlobUtil.config({
                // response data will be saved to this path if it has access right.
                path: tempCacheFile,
                trusty: this.props.trustAllCerts,
                transformFile: !!this.props.transformFile,
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
                });

            const res = await this.lastRNBFTask;
            this.lastRNBFTask = null;
            const responseInfo = res ? res.respInfo : undefined;

            if (responseInfo && typeof responseInfo.status === "number" && (responseInfo.status < 200 || responseInfo.status >= 300)) {
                throw this._createDownloadError(source.uri, responseInfo);
            }

            if (!this.props.transformFile && responseInfo && responseInfo.headers && !responseInfo.headers["Content-Encoding"] && !responseInfo.headers["Transfer-Encoding"] && responseInfo.headers["Content-Length"]) {
                const expectedContentLength = responseInfo.headers["Content-Length"];
                let actualContentLength;

                try {
                    const fileStats = await ReactNativeBlobUtil.fs.stat(res.path());

                    if (!fileStats || !fileStats.size) {
                        throw this._createDownloadError(source.uri, responseInfo);
                    }

                    actualContentLength = fileStats.size;
                } catch (error) {
                    throw this._createDownloadError(source.uri, responseInfo);
                }

                if (expectedContentLength != actualContentLength) {
                    throw this._createDownloadError(source.uri, responseInfo);
                }
            }

            await this._unlinkFile(cacheFile);
            // Await the copy: a fire-and-forget chain here swallows cp() rejections
            // as `Uncaught (in promise)` instead of forwarding them through onError.
            await ReactNativeBlobUtil.fs.cp(tempCacheFile, cacheFile);
            const finalPath = this.props.transformFile
                ? await this._transformToViewFile(cacheFile)
                : cacheFile;
            if (this._mounted) {
                this.setState({path: finalPath, isDownloaded: true, progress: 1});
            }
            await this._unlinkFile(tempCacheFile);
        } catch (error) {
            this.lastRNBFTask = null;
            await this._unlinkFile(tempCacheFile);
            await this._unlinkFile(cacheFile);
            this._onError(error);
        }

    };

    _createDownloadError = (uri, responseInfo) => {
        const error = new Error("DownloadFailed:" + uri);
        if (responseInfo) {
            error.status = responseInfo.status;
        }
        return error;
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
