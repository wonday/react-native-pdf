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
            isDownloaded: false,
        };
        this.path = "";
        this.asset = "";
    }

    componentDidMount() {
        const source = resolveAssetSource(this.props.source) || {};
        console.log("PDF source:");
        console.log(source);

        if (source.uri) {

            let uri = source.uri || '';

            const isNetwork = !!(uri && uri.match(/^https?:/));
            const isAsset = !!(uri && uri.match(/^(assets-library|content|ms-appx|ms-appdata):/));
            const isBase64 = !!(uri && uri.match(/^data:application\/pdf;base64/));

            if (isNetwork) {
                if (source.saveToDocument) {
                    this.path = RNFetchBlob.fs.dirs.DocumentDir + "/" + SHA1(uri) + ".pdf";
                } else {
                    this.path = RNFetchBlob.fs.dirs.CacheDir + "/" + SHA1(uri) + ".pdf";
                }

                if (!source.cache) {
                    this._downloadFile(uri, this.path);
                }
                else {
                    RNFetchBlob.fs.exists(this.path)
                        .then((exist) => {
                            if (exist) {
                                this.setState({isDownloaded: true});
                            } else {
                                this._downloadFile(uri, this.path);
                            }
                        })
                        .catch(() => {
                            this._downloadFile(uri, this.path);
                        });
                }
            } else if (isAsset) {
                this.asset = source.asset;
                this.setState({isDownloaded: true});
            } else if (isBase64) {
                this.path = RNFetchBlob.fs.dirs.CacheDir + "/" + SHA1(uri) + ".pdf";
                let data = uri.replace(/data:application\/pdf;base64/i,"");

                RNFetchBlob.fs.writeFile(this.path, data, 'base64')
                    .then(()=>{
                        console.log("write base64 to file:"+this.path);
                        this.setState({isDownloaded: true});
                    })
                    .catch(() => {
                        console.log("write base64 file error!");
                        RNFetchBlob.fs.unlink(this.path);
                    });
            } else {
                console.log("default source type as file");
                this.path = uri.replace(/file:\/\//i,"");
                this.setState({isDownloaded: true});
            }
        } else {
            console.log("no pdf source!");
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
                // the path should be dRNFetchBlob.fs.dirs.DocumentDir + '/xxx.pdf'
                console.log('Load pdf from url and saved to ', res.path())
                this.setState({isDownloaded: true});
            })
            .catch(()=>{
                console.log(`download ${url} error.`);
                RNFetchBlob.fs.unlink(this.path);
            });
    };

    setNativeProps = (nativeProps) => {
        this._root.setNativeProps(nativeProps);
    };

    _onChange = (event:Event) => {
        let message = event.nativeEvent.message.split(",");
        console.log("onChange: " + message);
        if (message.length>0){
            if (message[0]=="loadComplete") {
                this.props.onLoadComplete && this.props.onLoadComplete(Number(message[1]));
            } else if (message[0]=="pageChanged") {
                this.props.onPageChanged && this.props.onPageChanged(Number(message[1]),Number(message[2]));
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
            return (<PdfCustom ref={component => this._root = component} {...this.props} asset={this.asset!=""?this.asset:(null)} path={this.path} onChange={this._onChange}/>)
        }

    }

}

Pdf.propTypes = {
    ...View.propTypes,
    path: PropTypes.string,
    asset: PropTypes.string,
    source: PropTypes.oneOfType([
        PropTypes.shape({
            uri: PropTypes.string,
            cache: PropTypes.bool,
            saveToDocument: PropTypes.bool
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
    onPageChanged: PropTypes.func
};

var PdfCustom = requireNativeComponent('RCTPdf', Pdf, {
    nativeOnly: {path:true, asset:true, onChange: true}
});