# react-native-pdf
[![npm](https://img.shields.io/npm/v/react-native-pdf.svg?style=flat-square)](https://www.npmjs.com/package/react-native-pdf)

A react native PDF view component (cross-platform support)

### Feature

* read a PDF from url/local file/asset and can cache it.
* display horizontally or vertically
* drag and zoom
* first tap for reset zoom and contious tap for zoom in

### Notice
* react-native-pdf does not support for react-native(iOS) ver<0.40, becouse of header file inluding changed, but you can modify it yourself to support react-native(iOS) ver<0.40.

### Installation
```bash
npm install react-native-pdf --save

react-native link react-native-pdf
```
We use [`react-native-fetch-blob`](https://github.com/wkh237/react-native-fetch-blob#installation) to handle file system access in this package and it requires an extra step during the installation. 
_You should only have to do this once._

    react-native link react-native-fetch-blob
    
Or, if you want to add Android permissions to AndroidManifest.xml automatically, use this one:

    RNFB_ANDROID_PERMISSIONS=true react-native link react-native-fetch-blob

### Usage

First, require it from your app's JavaScript files with:
```bash
import Pdf from 'react-native-pdf';
```


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
        //let source = require('./test.pdf');
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
                        console.log(`current page: ${page}`);}}
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

| Property      | Type            | Default             | Description | iOS | Android |
| ------------- |:-------------:|:------------:       | ----------- | --- | ------- |
| source        | object      | null              | PDF sourse like <Image>, can be:{uri:"http://xxx/xxx.pdf"} or {require("./test.pdf")} or {uri:"base64 data"}. You also can  cache it by add "cache" property to source like {url:"http://xxx/xxx.pdf",cache:true}, default not cache network file.| ✔   | ✔ |
| page          | number        | 1             | page index | ✔   | ✔ |
| zoom      | number        | 1.0   | zoom scale | ✔   | ✔ |
| horizontal      | bool        | false   | draw page direction | ✔   | ✔ |
| activityIndicator       | Component       | `<ActivityIndicator>`   | when loading a file show it as a indicator  | ✔   | ✔ |
| onLoadComplete      | function        | null        | callback when page load complete, return total page count | ✔   | ✔ |
| onPageChanged       | function        | null        | callback when page changed, ,return current page and total page count | ✔   | ✔ |
