# react-native-pdf
[![npm](https://img.shields.io/npm/v/react-native-pdf.svg?style=flat-square)](https://www.npmjs.com/package/react-native-pdf)

A react native PDF view component (cross-platform support)

### Feature

* read a PDF from url/local file/asset and can cache it.
* display horizontally or vertically
* drag and zoom
* first tap for reset zoom and continuous tap for zoom in
* support password protected pdf

### Installation
We use [`react-native-fetch-blob`](https://github.com/wkh237/react-native-fetch-blob#installation) to handle file system access in this package,
So you should install react-native-pdf and react-native-fetch-blob

```bash
npm install react-native-pdf --save
npm install react-native-fetch-blob --save

react-native link react-native-pdf
react-native link react-native-fetch-blob
```

### FAQ

Q1. After installation and running, I can not see the pdf file.
A1: maybe you forgot to excute ```react-native link``` or it does not run correctly.
You can add it manually. For detail you can see the issue [`#24`](https://github.com/wonday/react-native-pdf/issues/24) and [`#2`](https://github.com/wonday/react-native-pdf/issues/2)

Q2. When running, it shows ```'Pdf' has no propType for native prop RCTPdf.acessibilityLabel of native type 'String'```
A2. Your react-native version is too old, please upgrade it to 0.47.0+ see also [`#39`](https://github.com/wonday/react-native-pdf/issues/39)

### ChangeLog

v2.0.0

1. Reimplement ios version, improving scrolling
2. fix ios paging [`#63`](https://github.com/wonday/react-native-pdf/issues/63)

v1.3.5

1. improving scolling
2. return pdf local/cache path when callback onLoadComplete [`#57`](https://github.com/wonday/react-native-pdf/issues/57)

v1.3.4

1. update ios project to xcode9 format.
2. fix crash problem when load from base64 [`#58`](https://github.com/wonday/react-native-pdf/issues/58)
3. fix TypeScript definition for onError [`#53`](https://github.com/wonday/react-native-pdf/issues/53)
4. update sample code in readme

v1.3.3

1. improve ios scrolling, fix [`#47`](https://github.com/wonday/react-native-pdf/issues/47)

v1.3.2

1. move react-native and react-native-fetch-blob to peerDependencies

v1.3.1

1. refactor android source
2. stop page scrolling when tap screen [`#41`](https://github.com/wonday/react-native-pdf/issues/41)

v1.3.0

1. fix drawing problem on Android 4.4 [`#31`](https://github.com/wonday/react-native-pdf/issues/31)
2. add fitWidth support [`#36`](https://github.com/wonday/react-native-pdf/issues/36) , [`#38`](https://github.com/wonday/react-native-pdf/issues/38)

[[more]](https://github.com/wonday/react-native-pdf/releases)

### Example

```js
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
    View,
    Text
} from 'react-native';

import Pdf from 'react-native-pdf';

export default class PDFExample extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            page: 1,
            scale: 1,
            pageCount: 1,
            horizontal: false,
        };
        this.pdf = null;
    }

    componentDidMount() {
    }

    prePage=()=>{
        let prePage = this.state.currentPage>1?this.state.currentPage-1:1;
        this.setState({page:prePage});
        console.log(`prePage: ${prePage}`);
    }

    nextPage=()=>{
        let nextPage = this.state.currentPage+1>this.state.pageCount?this.state.pageCount:this.state.currentPage+1;
        this.setState({page:nextPage});
        console.log(`nextPage: ${nextPage}`);
    }
    
    zoomOut=()=>{
        let scale = this.state.scale>1?this.state.scale/1.2:1;
        this.setState({scale:scale});
        console.log(`zoomOut scale: ${scale}`);
    }

    zoomIn=()=>{
        let scale = this.state.scale*1.2;
        scale = scale>3?3:scale;
        this.setState({scale:scale});
        console.log(`zoomIn scale: ${scale}`);
    }
    
    switchHorizontal=()=>{
        this.setState({horizontal:!this.state.horizontal,page:this.state.currentPage});
    }
        
    render() {
        //let source = {uri:'http://samples.leanpub.com/thereactnativebook-sample.pdf',cache:true};
        //let source = require('./test.pdf');  // ios only
        //let source = {uri:'bundle-assets://test.pdf'};

        //let source = {uri:'file:///sdcard/test.pdf'};
        let source = {uri:"data:application/pdf;base64,..."};

        return (
            <View style={styles.container}>
                <View style={{flexDirection:'row'}}>
                    <TouchableHighlight  disabled={this.state.page==1} style={this.state.page==1?styles.btnDisable:styles.btn} onPress={()=>this.prePage()}>
                        <Text style={styles.btnText}>{'-'}</Text>
                    </TouchableHighlight>
                    <View style={styles.btnText}><Text style={styles.btnText}>Page</Text></View>
                    <TouchableHighlight  disabled={this.state.page==this.state.pageCount} style={this.state.page==this.state.pageCount?styles.btnDisable:styles.btn}  onPress={()=>this.nextPage()}>
                        <Text style={styles.btnText}>{'+'}</Text>
                    </TouchableHighlight>
                    <TouchableHighlight  disabled={this.state.scale==1} style={this.state.scale==1?styles.btnDisable:styles.btn} onPress={()=>this.zoomOut()}>
                        <Text style={styles.btnText}>{'-'}</Text>
                    </TouchableHighlight>
                    <View style={styles.btnText}><Text style={styles.btnText}>Scale</Text></View>
                    <TouchableHighlight  disabled={this.state.scale>=3} style={this.state.scale>=3?styles.btnDisable:styles.btn}  onPress={()=>this.zoomIn()}>
                        <Text style={styles.btnText}>{'+'}</Text>
                    </TouchableHighlight>
                    <View style={styles.btnText}><Text style={styles.btnText}>{'Horizontal'}</Text></View>
                    <TouchableHighlight  style={styles.btn} onPress={()=>this.switchHorizontal()}>
                        {!this.state.horizontal?(<Text style={styles.btnText}>{'☒'}</Text>):(<Text style={styles.btnText}>{'☑'}</Text>)}
                    </TouchableHighlight>
                    
                </View>
                <Pdf ref={(pdf)=>{this.pdf = pdf;}}
                    source={source}
                    page={this.state.page}
                    scale={this.state.scale}
                    horizontal={this.state.horizontal}
                    onLoadComplete={(pageCount)=>{
                        this.setState({pageCount: pageCount});
                        console.log(`total page count: ${pageCount}`);
                    }}
                    onPageChanged={(page,pageCount)=>{
                        this.setState({currentPage:page});
                        console.log(`current page: ${page}`);
                    }}
                    onError={(error)=>{
                        console.log(error);
                    }}
                    style={styles.pdf}/>
            </View>
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
        padding:2,
        backgroundColor: "aqua",
    },
    btnDisable: {
        margin: 2,
        padding:2,
        backgroundColor: "gray",
    },
    btnText: {
        margin: 2,
        padding:2,
    },
    pdf: {
        flex:1,
        width:Dimensions.get('window').width,
    }
});

```


### Configuration

| Property      | Type          | Default          | Description         | iOS   | Android |
| ------------- |:-------------:|:----------------:| ------------------- | ------| ------- |
| source        | object        | not null         | PDF source like {uri:xxx, cache:false}. see the following for detail.| ✔   | ✔ |
| page          | number        | 1                | page index          | ✔   | ✔ |
| scale         | number        | 1.0              | zoom scale, scale>=1| ✔   | ✔ |
| horizontal    | bool          | false            | draw page direction, if you want to listen the orientation change, you can use  [[react-native-orientation-locker]](https://github.com/wonday/react-native-orientation-locker)| ✔   | ✔ |
| fitWidth      | bool          | false            | if true fit the width of view | ✔   | ✔ |
| spacing       | number        | 10               | draw page breaker   | ✔   | ✔ |
| password      | string        | ""               | pdf password, if password error, will call OnError() with message "Password required or incorrect password."        | ✔   | ✔ |
| style         | object        | {backgroundColor:"#eee"} | support normal view style, you can use this to set border/spacing color... | ✔   | ✔ |
| activityIndicator   | Component       | ProgressBar | when loading show it as an indicator  | ✔   | ✔ |
| enableAntialiasing  | bool            | true        | improve rendering a little bit on low-res screens, but maybe course some problem on Android 4.4, so add a switch  | ✖   | ✔ |
| onLoadProgress      | function        | null        | callback when loading, return loading progress (0-1) | ✔   | ✔ |
| onLoadComplete      | function        | null        | callback when pdf load completed, return total page count and pdf local/cache path | ✔   | ✔ |
| onPageChanged       | function        | null        | callback when page changed ,return current page and total page count | ✔   | ✔ |
| onError       | function        | null        | callback when error happened | ✔   | ✔ |

#### parameters of source

| parameter    | Description | default | iOS | Android |
| ------------ | ----------- | ------- | --- | ------- |
| uri          | pdf source, see the forllowing for detail.| required | ✔   | ✔ |
| cache        | use cache or not | false | ✔ | ✔ |
| method       | request method when uri is a url | "GET" | ✔ | ✔ |
| headers      | request headers when uri is a url | {} | ✔ | ✔ |

#### types of source.uri

| Usage    | Description | iOS | Android |
| ------------ | ----------- | --- | ------- |
| `{uri:"http://xxx/xxx.pdf"}` | load pdf from a url | ✔   | ✔ |
| `{require("./test.pdf")}` | load pdf relate to js file (do not need add by xcode) | ✔ | ✖ |
| `{uri:"bundle-assets://path/to/xxx.pdf"}` | load pdf from assets, the file should be at android/app/src/main/assets/path/to/xxx.pdf | ✖ | ✔ |
| `{uri:"bundle-assets://xxx.pdf"}` | load pdf from assets, you must add pdf to project by xcode. this does not support folder. | ✔ | ✖ |
| `{uri:"base64data"}` | load pdf from base64 string | ✔   | ✔ |
| `{uri:"file:///absolute/path/to/xxx.pdf"}` | load pdf from local file system | ✔   | ✔ |