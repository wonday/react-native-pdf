//
//  react-native-pdf
//  
//
//  Created by Wonday on 17/4/21.
//  Copyright (c) wonday.org All rights reserved.
//

'use strict';
import React,{ Component, PropTypes } from 'react';
import {
    ActivityIndicator,
    requireNativeComponent,
    View
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
        };
    }

    
    componentDidMount() {
        const source = resolveAssetSource(this.props.source) || {};
        console.log("PDF source:");
        console.log(source);

        let uri = source.uri || '';

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
                this._downloadFile(uri, cacheFile);
            } else if (isAsset) {
                RNFetchBlob.fs.cp(uri, cacheFile)
                .then(() => {
                    console.log("load from asset:"+uri);
                    this.setState({path:cacheFile, isDownloaded:true});
                })
                .catch((error) => {
                    console.warn("load from asset error");
                    console.log(error);
                    this.props.onError && this.props.onError("load pdf failed.");
                });
            } else if (isBase64) {
                let data = uri.replace(/data:application\/pdf;base64/i,"");
                RNFetchBlob.fs.unlink(cacheFile);
                RNFetchBlob.fs.writeFile(cacheFile, data, 'base64')
                    .then(()=>{
                        console.log("write base64 to file:" + cacheFile);
                        this.setState({path:cacheFile, isDownloaded:true});
                    })
                    .catch(() => {
                        console.warn("write base64 file error!");
                        RNFetchBlob.fs.unlink(this.path);
                        this.props.onError && this.props.onError("load pdf failed.");
                    });
            } else {
                console.log("default source type as file");
                this.setState({path:uri.replace(/file:\/\//i,""),isDownloaded: true});
            }
        } else {
            console.error("no pdf source!");
        }

    }

    _downloadFile = (url, path) => {
        RNFetchBlob
            .config({
                // response data will be saved to this path if it has access right.
                path: path
            })
            .fetch('GET', url, {
                //some headers ..
            })
            .then((res) => {
                console.log('Load pdf from url and saved to ', res.path())
                this.setState({path:cacheFile, isDownloaded:true});
            })
            .catch(()=>{
                console.warn(`download ${url} error.`);
                RNFetchBlob.fs.unlink(this.path);
                this.props.onError && this.props.onError("load pdf failed.");
            });
    };

    setNativeProps = (nativeProps) => {
        this._root.setNativeProps(nativeProps);
    };

    _onChange = (event:Event) => {
        let message = event.nativeEvent.message.split("|");
        console.log("onChange: " + message);
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
        const {activityIndicator} = this.props;
        if (!this.state.isDownloaded) {
            return (
                <View style={{flex:1,justifyContent: 'center',alignItems: 'center'}}>
                    {activityIndicator?activityIndicator:<ActivityIndicator/>}
                </View>
            );
        } else {
            return (<PdfCustom ref={component => this._root = component} {...this.props} path={this.state.path} onChange={this._onChange}/>)
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
    activityIndicator: PropTypes.any,
    onChange: PropTypes.func,
    onLoadComplete: PropTypes.func,
    onPageChanged: PropTypes.func,
    onError: PropTypes.func
};

var PdfCustom = requireNativeComponent('RCTPdf', Pdf, {
    nativeOnly: {path:true, onChange: true}
});
