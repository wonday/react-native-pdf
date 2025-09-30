/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from 'react';
import {
    StyleSheet,
    TouchableHighlight,
    Dimensions,
    SafeAreaView,
    View,
    Text,
    Platform
} from 'react-native';

import Pdf from 'react-native-pdf';
import Orientation from 'react-native-orientation-locker';

const WIN_WIDTH = Dimensions.get('window').width;
const WIN_HEIGHT = Dimensions.get('window').height;


export default class PDFExample extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            page: 1,
            scale: 1,
            numberOfPages: 0,
            horizontal: false,
            showsHorizontalScrollIndicator: true,
            showsVerticalScrollIndicator: true,
            width: WIN_WIDTH
        };
        this.pdf = null;
    }

    _onOrientationDidChange = (orientation) => {
        if (orientation == 'LANDSCAPE-LEFT'||orientation == 'LANDSCAPE-RIGHT') {
          this.setState({width:WIN_HEIGHT>WIN_WIDTH?WIN_HEIGHT:WIN_WIDTH,horizontal:true});
        } else {
          this.setState({width:WIN_HEIGHT>WIN_WIDTH?WIN_HEIGHT:WIN_WIDTH,horizontal:false});
        }
    };

    componentDidMount() {
        Orientation.addOrientationListener(this._onOrientationDidChange);

        (async () => {
            const url = 'https://www.africau.edu/images/default/sample.pdf';
            // handling blobs larger than 64 KB on Android requires patching React Native (https://github.com/facebook/react-native/pull/31789)
            const result = await fetch(url);
            const blob = await result.blob();
            const objectURL = URL.createObjectURL(blob);
            this.setState({...this.state, objectURL, blob}); // keep blob in state so it doesn't get garbage-collected
        })();
    }

    componentWillUnmount() {
        Orientation.removeOrientationListener(this._onOrientationDidChange);
    }

    prePage = () => {
        let prePage = this.state.page > 1 ? this.state.page - 1 : 1;
        this.pdf.setPage(prePage);
        console.log(`prePage: ${prePage}`);
    };

    nextPage = () => {
        let nextPage = this.state.page + 1 > this.state.numberOfPages ? this.state.numberOfPages : this.state.page + 1;
        this.pdf.setPage(nextPage);
        console.log(`nextPage: ${nextPage}`);
    };

    zoomOut = () => {
        let scale = this.state.scale > 1 ? this.state.scale / 1.2 : 1;
        this.setState({scale: scale});
        console.log(`zoomOut scale: ${scale}`);
    };

    zoomIn = () => {
        let scale = this.state.scale * 1.2;
        scale = scale > 3 ? 3 : scale;
        this.setState({scale: scale});
        console.log(`zoomIn scale: ${scale}`);
    };

    switchHorizontal = () => {
        this.setState({horizontal: !this.state.horizontal, page: this.state.page});
    };

    switchShowsHorizontalScrollIndicator = () => {
        this.setState({showsHorizontalScrollIndicator: !this.state.showsHorizontalScrollIndicator});
    };

    switchShowsVerticalScrollIndicator = () => {
        this.setState({showsVerticalScrollIndicator: !this.state.showsVerticalScrollIndicator});
    };

    render() {
        let source = Platform.OS === 'windows' ?  {uri: 'ms-appx:///test.pdf'} : {uri:'https://www.africau.edu/images/default/sample.pdf',cache:true};
        //let source = {uri:'http://samples.leanpub.com/thereactnativebook-sample.pdf',cache:true};
        //let source = {uri: 'ms-appx:///test.pdf'}
        //let source = require('./test.pdf');  // ios only
        //let source = {uri:'bundle-assets://test.pdf'};
        //let source = {uri: this.state.objectURL};

        //let source = {uri:'file:///sdcard/test.pdf'};
        //let source = {uri:"data:application/pdf;base64,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Pj4NZW5kb2JqDTQgMCBvYmoNPDwvTmFtZXMgW10+Pg1lbmRvYmoNNSAwIG9iag08PD4+DWVuZG9iag14cmVmDQowIDE0DQowMDAwMDAwMDAwIDY1NTM1IGYNCjAwMDAwMDAwMTYgMDAwMDAgbg0KMDAwMDAyMTU1NSAwMDAwMCBuDQowMDAwMDAwMTAzIDAwMDAwIG4NCjAwMDAwMjE2MTAgMDAwMDAgbg0KMDAwMDAyMTYzOSAwMDAwMCBuDQowMDAwMDAwMzY2IDAwMDAwIG4NCjAwMDAwMDA0OTEgMDAwMDAgbg0KMDAwMDAwMDc3MyAwMDAwMCBuDQowMDAwMDAwOTExIDAwMDAwIG4NCjAwMDAwMDEzMzIgMDAwMDAgbg0KMDAwMDAwMTU5NCAwMDAwMCBuDQowMDAwMDAxOTA4IDAwMDAwIG4NCjAwMDAwMDEyNTkgMDAwMDAgbg0KdHJhaWxlcjw8L1NpemUgMTQgL1Jvb3QgMSAwIFIgL0luZm8gMyAwIFIgL0lEIFs8ZTkyNjNhYjcwZGU0NDg0ZTljZjYwYWEwZTYxYmUwN2Q+PGM3MDYwZmFjMGZlZjRiYjI4MDQyYzY1ZmNlYTRjYzQwPl0+Pg1zdGFydHhyZWYNMjE2NTkNJSVFT0YN"};

        return (
            <SafeAreaView style={styles.container}>
                <View style={{flexDirection: 'row'}}>
                    <TouchableHighlight disabled={this.state.page === 1}
                                        style={this.state.page === 1 ? styles.btnDisable : styles.btn}
                                        onPress={() => this.prePage()}>
                        <Text style={styles.btnText}>{'-'}</Text>
                    </TouchableHighlight>
                    <View style={styles.btnText}><Text style={styles.btnText}>Page</Text></View>
                    <TouchableHighlight disabled={this.state.page === this.state.numberOfPages}
                                        style={this.state.page === this.state.numberOfPages ? styles.btnDisable : styles.btn}
                                        testID='NextPage'
                                        onPress={() => this.nextPage()}>
                        <Text style={styles.btnText}>{'+'}</Text>
                    </TouchableHighlight>
                    <TouchableHighlight disabled={this.state.scale === 1}
                                        style={this.state.scale === 1 ? styles.btnDisable : styles.btn}
                                        onPress={() => this.zoomOut()}>
                        <Text style={styles.btnText}>{'-'}</Text>
                    </TouchableHighlight>
                    <View style={styles.btnText}><Text style={styles.btnText}>Scale</Text></View>
                    <TouchableHighlight disabled={this.state.scale >= 3}
                                        style={this.state.scale >= 3 ? styles.btnDisable : styles.btn}
                                        onPress={() => this.zoomIn()}>
                        <Text style={styles.btnText}>{'+'}</Text>
                    </TouchableHighlight>
                </View>
                <View style={{flexDirection: 'row'}}>
                    <View style={styles.btnText}><Text style={styles.btnText}>{'Horizontal:'}</Text></View>
                    <TouchableHighlight style={styles.btn} onPress={() => this.switchHorizontal()}>
                        {!this.state.horizontal ? (<Text style={styles.btnText}>{'false'}</Text>) : (
                            <Text style={styles.btnText}>{'true'}</Text>)}
                    </TouchableHighlight>
                    <View style={styles.btnText}><Text style={styles.btnText}>{'Scrollbar'}</Text></View>
                    <TouchableHighlight style={styles.btn} onPress={
                        () => {this.switchShowsHorizontalScrollIndicator(); 
                        this.switchShowsVerticalScrollIndicator()}}>
                        {!this.state.showsVerticalScrollIndicator ? (<Text style={styles.btnText}>{'hidden'}</Text>) : (
                            <Text style={styles.btnText}>{'shown'}</Text>)}
                    </TouchableHighlight>

                </View>
                <View style={{flex:1,width: this.state.width}}>
                    <Pdf ref={(pdf) => {
                        this.pdf = pdf;
                    }}
                         source={source}
                         scale={this.state.scale}
                         horizontal={this.state.horizontal}
                         showsVerticalScrollIndicator={this.state.showsVerticalScrollIndicator}
                         showsHorizontalScrollIndicator={this.state.showsHorizontalScrollIndicator}
                         onLoadComplete={(numberOfPages, filePath,{width,height},tableContents) => {
                             this.setState({
                                numberOfPages: numberOfPages 
                             });
                             console.log(`total page count: ${numberOfPages}`);
                             console.log(tableContents);
                         }}
                         onPageChanged={(page, numberOfPages) => {
                             this.setState({
                                 page: page
                             });
                             console.log(`current page: ${page}`);
                         }}
                         onError={(error) => {
                             console.log(error);
                         }}
                         style={{flex:1}}
                         />
                </View>
            </SafeAreaView>
        )
    }
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'flex-start',
        alignItems: 'center',
        marginTop: 25,
    },
    btn: {
        margin: 2,
        padding: 2,
        backgroundColor: "aqua",
    },
    btnDisable: {
        margin: 2,
        padding: 2,
        backgroundColor: "gray",
    },
    btnText: {
        margin: 2,
        padding: 2,
    }
});
