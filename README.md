# react-native-pdf
[![npm](https://img.shields.io/npm/v/react-native-pdf.svg?style=flat-square)](https://www.npmjs.com/package/react-native-pdf)

A react native PDF view component (cross-platform support)

### Feature

* read a PDF from url/local file/asset and can cache it.
* display horizontally or vertically
* drag and zoom
* first tap for reset zoom and contious tap for zoom in
* support password protected pdf

### Installation
```bash
npm install react-native-pdf --save

react-native link react-native-pdf
```
We use [`react-native-fetch-blob`](https://github.com/wkh237/react-native-fetch-blob#installation) to handle file system access in this package and it requires an extra step during the installation. 
_You should only have to do this once._
```bash
npm install react-native-fetch-blob --save

react-native link react-native-fetch-blob
```
Or, if you want to add Android permissions to AndroidManifest.xml automatically, use this one:

    RNFB_ANDROID_PERMISSIONS=true react-native link react-native-fetch-blob

### ChangeLog 

v1.2.1

1. add METHOD and HEADERS support for network pdf

v1.2.0

1. add page breaker support (ios/android)
2. add password support (ios/android)
3. improve font rendering (android)
4. change default activityIndicator to progress bar

[[more]](https://github.com/wonday/react-native-pdf/releases)

### Example

```js
//
//  PDFExample.js
// 
//
//  Created by Wonday on 17/4/21.
//  Copyright (c) wonday.org All rights reserved.
//

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
            pageCount: 1,
        };
        this.pdf = null;
    }

    componentDidMount() {
    }

    prePage=()=>{
        if (this.pdf){
            let prePage = this.state.page>1?this.state.page-1:1;
            this.pdf.setNativeProps({page: prePage});
            this.setState({page:prePage});
            console.log(`prePage: ${prePage}`);
        }
    }

    nextPage=()=>{
        if (this.pdf){
            let nextPage = this.state.page+1>this.state.pageCount?this.state.pageCount:this.state.page+1;
            this.pdf.setNativeProps({page: nextPage});
            this.setState({page:nextPage});
            console.log(`nextPage: ${nextPage}`);
        }

    }

    render() {
        let source = {uri:'https://www.irs.gov/pub/irs-pdf/fw2.pdf',cache:true};
        //let source = {uri:'bundle-assets://test.pdf'};
        //let source = require('./test.pdf'); //ios only
        //let source = {uri:"data:application/pdf;base64, ..."}; // this is a dummy

        return (
            <View style={styles.container}>
                <View style={{flexDirection:'row'}}>
                    <TouchableHighlight  disabled={this.state.page==1} style={this.state.page==1?styles.btnDisable:styles.btn} onPress={()=>this.prePage()}>
                        <Text style={styles.btnText}>{'Previous'}</Text>
                    </TouchableHighlight>
                    <TouchableHighlight  disabled={this.state.page==this.state.pageCount} style={this.state.page==this.state.pageCount?styles.btnDisable:styles.btn}  onPress={()=>this.nextPage()}>
                        <Text style={styles.btnText}>{'Next'}</Text>
                    </TouchableHighlight>
                </View>
                <Pdf ref={(pdf)=>{this.pdf = pdf;}}
                    source={source}
                    page={1}
                    horizontal={false}
                    onLoadComplete={(pageCount)=>{
                        this.setState({pageCount: pageCount});
                        console.log(`total page count: ${pageCount}`);
                    }}
                    onPageChanged={(page,pageCount)=>{
                        this.setState({page:page});
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
        margin: 5,
        padding:5,
        backgroundColor: "blue",
    },
    btnDisable: {
        margin: 5,
        padding:5,
        backgroundColor: "gray",
    },
    btnText: {
        color: "#FFF",
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
| horizontal    | bool          | false            | draw page direction | ✔   | ✔ |
| spacing       | number        | 10               | draw page breaker   | ✔   | ✔ |
| password      | string        | ""               | pdf password        | ✔   | ✔ |
| style         | object        | {backgroundColor:"#eee"} | support normal view style, you can use this to set border/spacing color... | ✔   | ✔ |
| activityIndicator   | Component       | ProgressBar | when loading show it as an indicator  | ✔   | ✔ |
| onLoadProgress      | function        | null        | callback when loading, return loading progress (0-1) | ✔   | ✔ |
| onLoadComplete      | function        | null        | callback when pdf load completed, return total page count | ✔   | ✔ |
| onPageChanged       | function        | null        | callback when page changed ,return current page and total page count | ✔   | ✔ |
| onError       | function        | null        | callback when error happened | ✔   | ✔ |

#### parameters of source

| parameter    | Description | default | iOS | Android |
| ------------ | ----------- | ------- | --- | ------- |
| uri          | pdf source, see the forllowing for detail.| required | ✔   | ✔ |
| cached       | use cache or not | false | ✔ | ✔ |
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