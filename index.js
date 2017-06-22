/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';
import React,{ Component, PropTypes } from 'react';
import {
    ActivityIndicator,
    requireNativeComponent,
    View,
    Platform,
    ProgressBarAndroid,
    ProgressViewIOS
} from 'react-native';
import RNFetchBlob from 'react-native-fetch-blob'
const SHA1 = require("crypto-js/sha1");
import resolveAssetSource from 'react-native/Libraries/Image/resolveAssetSource';

export default class Pdf extends Component {
    constructor(props) {
        super(props);
        this.state = {
            path: "",
            isDownloaded: false,
            progress: 0,
        };

        this.uri = "";
        this.lastRNBFTask = null;

    }

    componentWillReceiveProps(nextProps) {
        if (nextProps.source != this.props.source) {
            __DEV__ && console.log("componentWillReceiveProps: source changed");
            this._loadFromSource(nextProps.source);
        }
    }

    componentDidMount() {
        this._loadFromSource(this.props.source);
    }

    _loadFromSource = (newSource) => {

        const source = resolveAssetSource(newSource) || {};
        __DEV__ && console.log("PDF source:");
        __DEV__ && console.log(source);

        let uri = source.uri || '';

        // no chanage then return
        if (this.uri == uri) return;
        this.uri = uri;

        // first set to initial state
        this.setState({isDownloaded:false,path:"",progress:0});

        const cacheFile = RNFetchBlob.fs.dirs.CacheDir + "/" + SHA1(uri) + ".pdf";

        if (source.cache) {
            RNFetchBlob.fs.exists(cacheFile)
                .then((exist) => {
                    if (exist) {
                        this.setState({path:cacheFile, isDownloaded:true});
                    } else {
                        // cache not exist then re load it
                        this._prepareFile(source);
                    }
                })
                .catch(() => {
                    this._prepareFile(source);
                });
        } else {
            this._prepareFile(source);
        }
    }

    _prepareFile = (source) => {

        if (source.uri) {

            let uri = source.uri || '';

            const isNetwork = !!(uri && uri.match(/^https?:\/\//));
            const isAsset = !!(uri && uri.match(/^bundle-assets:\/\//));
            const isBase64 = !!(uri && uri.match(/^data:application\/pdf;base64/));

            const cacheFile = RNFetchBlob.fs.dirs.CacheDir + "/" + SHA1(uri) + ".pdf";

            // delete old cache file
            RNFetchBlob.fs.unlink(cacheFile);


            if (isNetwork) {
                this._downloadFile(source, cacheFile);
            } else if (isAsset) {
                RNFetchBlob.fs.cp(uri, cacheFile)
                    // listen to download progress event
                    .progress((received, total) => {
                        __DEV__ && console.log('progress', received / total);
                        this.props.onLoadProgress && this.props.onLoadProgress(received/total);
                        this.setState({progress:received/total});
                    })
                    .then(() => {
                        __DEV__ && console.log("load from asset:"+uri);
                        this.setState({path:cacheFile, isDownloaded:true});
                    })
                    .catch((error) => {
                        RNFetchBlob.fs.unlink(cacheFile);
                        console.warn("load from asset error");
                        console.log(error);
                        this.props.onError && this.props.onError("load pdf failed.");
                    });
            } else if (isBase64) {
                let data = uri.replace(/data:application\/pdf;base64\,/i,"");
                RNFetchBlob.fs.writeFile(cacheFile, data, 'base64')
                    // listen to download progress event
                    .progress((received, total) => {
                        __DEV__ && console.log('progress', received / total);
                        this.props.onLoadProgress && this.props.onLoadProgress(received/total);
                        this.setState({progress:received/total});
                    })
                    .then(()=>{
                        __DEV__ && console.log("write base64 to file:" + cacheFile);
                        this.setState({path:cacheFile, isDownloaded:true});
                    })
                    .catch(() => {
                        RNFetchBlob.fs.unlink(this.path);
                        console.warn("write base64 file error!");
                        this.props.onError && this.props.onError("load pdf failed.");
                    });
            } else {
                __DEV__ && console.log("default source type as file");
                this.setState({path:uri.replace(/file:\/\//i,""),isDownloaded: true});
            }
        } else {
            console.error("no pdf source!");
        }

    }

    _downloadFile = (source, cacheFile) => {

        if (this.lastRNBFTask!=null) {
            this.lastRNBFTask.cancel((err) => {
                __DEV__ && console.log("Load pdf from url was cancelled.");
            });
        }

        this.lastRNBFTask = RNFetchBlob
            .config({
                // response data will be saved to this path if it has access right.
                path: cacheFile
            })
            .fetch(source.method?source.method:'GET', source.uri, source.headers?source.headers:{})
            // listen to download progress event
            .progress((received, total) => {
                __DEV__ && console.log('progress', received / total);
                this.props.onLoadProgress && this.props.onLoadProgress(received/total);
                this.setState({progress:received/total});
            });

        this.lastRNBFTask.then((res) => {
                __DEV__ && console.log('Load pdf from url and saved to ', res.path())
                this.lastRNBFTask = null;
                this.setState({path:cacheFile, isDownloaded:true, progress:1});
            })
            .catch((error)=>{
                console.warn(`download ${source.uri} error.`);
                console.log(error);
                this.lastRNBFTask = null;
                RNFetchBlob.fs.unlink(cacheFile);
                this.props.onError && this.props.onError("load pdf failed.");
            });
    };

    setNativeProps = (nativeProps) => {
        this._root.setNativeProps(nativeProps);
    };

    _onChange = (event:Event) => {
        let message = event.nativeEvent.message.split("|");
        __DEV__ && console.log("onChange: " + message);
        if (message.length>0){
            if (message[0]=="loadComplete") {
                this.props.onLoadComplete && this.props.onLoadComplete(Number(message[1]));
            } else if (message[0]=="pageChanged") {
                this.props.onPageChanged && this.props.onPageChanged(Number(message[1]),Number(message[2]));
            } else if (message[0]=="error") {
                this.props.onError && this.props.onError(message[1]);
            }
        }

    };

    render() {
        if (!this.state.isDownloaded) {
            return (
                <View style={{flex:1,justifyContent: 'center',alignItems: 'center'}}>
                    {this.props.activityIndicator
                        ?this.props.activityIndicator
                        :(Platform.OS == 'android'
                            ?<ProgressBarAndroid progress={this.state.progress} indeterminate={false} styleAttr="Horizontal" style={{width:200, height:2}} />
                            :<ProgressViewIOS progress={this.state.progress} style={{width:200, height:2}} />)
                    }
                </View>
            );
        } else {
            return (
                <PdfCustom ref={component => this._root = component} {...this.props} style={[{backgroundColor:"#EEE"},this.props.style]}  path={this.state.path} onChange={this._onChange}/>
            )
        }

    }

}

Pdf.propTypes = {
    ...View.propTypes,
    path: PropTypes.string,
    source: PropTypes.oneOfType([
        PropTypes.shape({
            uri: PropTypes.string,
            cache: PropTypes.bool
        }),
        // Opaque type returned by require('./test.pdf')
        PropTypes.number
    ]).isRequired,
    page: PropTypes.number,
    scale: PropTypes.number,
    horizontal: PropTypes.bool,
    spacing: PropTypes.number,
    password: PropTypes.string,
    activityIndicator: PropTypes.any,
    onChange: PropTypes.func,
    onLoadComplete: PropTypes.func,
    onPageChanged: PropTypes.func,
    onError: PropTypes.func
};

var PdfCustom = requireNativeComponent('RCTPdf', Pdf, {
    nativeOnly: {path:true, onChange: true}
});
