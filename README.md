# react-native-pdf
[![npm](https://img.shields.io/npm/v/react-native-pdf.svg?style=flat-square)](https://www.npmjs.com/package/react-native-pdf)

A react native PDF view component (cross-platform support)

### Feature

* read a PDF from url/local file/asset and can cache it.
* display horizontally or vertically
* drag and zoom
* double tap for zoom
* support password protected pdf

### Installation
We use [`react-native-fetch-blob`](https://github.com/wkh237/react-native-fetch-blob#installation) to handle file system access in this package,
So you should install react-native-pdf and react-native-fetch-blob

```bash
npm install react-native-fetch-blob --save
npm install react-native-pdf --save

react-native link react-native-fetch-blob
react-native link react-native-pdf
```

### FAQ

Q1. After installation and running, I can not see the pdf file.  
A1: maybe you forgot to excute ```react-native link``` or it does not run correctly.
You can add it manually. For detail you can see the issue [`#24`](https://github.com/wonday/react-native-pdf/issues/24) and [`#2`](https://github.com/wonday/react-native-pdf/issues/2)

Q2. When running, it shows ```'Pdf' has no propType for native prop RCTPdf.acessibilityLabel of native type 'String'```  
A2. Your react-native version is too old, please upgrade it to 0.47.0+ see also [`#39`](https://github.com/wonday/react-native-pdf/issues/39)

### ChangeLog

v3.0.14
1. fix in iPad can not zoom problem(offset still has problem, but zoom works)

v3.0.13
1. fix in iPad layout not center problem

v3.0.12
1. fix source.expiration check

v3.0.11
1. improve iOS zoom, can zoom from pinch center
2. fix call setState on an unmounted component

v3.0.10
1. fix source.expiration check [`#163`](https://github.com/wonday/react-native-pdf/issues/163)

v3.0.9
1. use CATiledLayer to improve iOS render performance

v3.0.8
1. use await to unlink file
2. fix podspec
3. do not count a scrolling gesture as a tap

v3.0.6
1. add cache file expiration
2. enhanced file download stability

v3.0.5
1. OnError return Error() object
2. fix cache overwrite error
3. add Android content:// support
4. fix type error
5. refactor view.propTypes to ViewPropTypes.

v3.0.4

1. fix 'virtualizedCell.cellKey' warning [`#125`](https://github.com/wonday/react-native-pdf/issues/125)
2. fix android crashed because of missing props [`#127`](https://github.com/wonday/react-native-pdf/issues/127)
3. use pure component to render pdf pages [`#129`](https://github.com/wonday/react-native-pdf/issues/129)
4. add requiresMainQueueSetup to cure RN v0.52 warning [`#130`](https://github.com/wonday/react-native-pdf/issues/130)

v3.0.3

1. when cache failed, can re-load at next time

v3.0.2

1. add activityIndicatorProps to support ActivityIndicator customize
2. fix not trigger onPageChanged() at last screen when screen has more then one pages
3. fix set initial page and scale no action error

v3.0.1
deprecated

v3.0.0

1. rewrite all iOS codes， improve scroll performance/Smoothness, fix scale/onPageChanged...  
2. add onPageSigleTap(), onScaleChanged()
3. update android dependent lib AndroidPdfViewer to 3.0.0.alpha.5
4. android support link in pdf
5. delete cache file when error happened

Known issues  
1. iOS zooming can not scroll to pinch center 

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
import { StyleSheet, Dimensions, View } from 'react-native';

import Pdf from 'react-native-pdf';

export default class PDFExample extends React.Component {
    render() {
        const source = {uri:'http://samples.leanpub.com/thereactnativebook-sample.pdf',cache:true};
        //const source = require('./test.pdf');  // ios only
        //const source = {uri:'bundle-assets://test.pdf'};

        //const source = {uri:'file:///sdcard/test.pdf'};
        //const source = {uri:"data:application/pdf;base64,..."};

        return (
            <View style={styles.container}>
                <Pdf
                    source={source}
                    onLoadComplete={(numberOfPages,filePath)=>{
                        console.log(`number of pages: ${numberOfPages}`);
                    }}
                    onPageChanged={(page,numberOfPages)=>{
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
    pdf: {
        flex:1,
        width:Dimensions.get('window').width,
    }
});

```


### Configuration

| Property      | Type          | Default          | Description         | iOS   | Android | FirstRelease |
| ------------- |:-------------:|:----------------:| ------------------- | ------| ------- | ------------ |
| source        | object        | not null         | PDF source like {uri:xxx, cache:false}. see the following for detail.| ✔ | ✔ | <3.0 |
| page          | number        | 1                | initial page index          | ✔   | ✔ | <3.0 |
| scale         | number        | 1.0              | zoom scale, 1<=scale<=3| ✔   | ✔ | <3.0 |
| horizontal    | bool          | false            | draw page direction, if you want to listen the orientation change, you can use  [[react-native-orientation-locker]](https://github.com/wonday/react-native-orientation-locker)| ✔   | ✔ | <3.0 |
| fitWidth      | bool          | false            | if true fit the width of view, can not use fitWidth=true together with scale| ✔   | ✔ | <3.0, abandoned from 3.0 |
| fitPolicy     | number        | 2                | 0:fit width, 1:fit height, 2:fit both(default)| ✔   | ✔ | 3.0 |
| spacing       | number        | 10               | the breaker size between pages| ✔   | ✔ | <3.0 |
| password      | string        | ""               | pdf password, if password error, will call OnError() with message "Password required or incorrect password."        | ✔   | ✔ | <3.0 |
| style         | object        | {backgroundColor:"#eee"} | support normal view style, you can use this to set border/spacing color... | ✔   | ✔ | <3.0 |
| activityIndicator   | Component       | <ProgressBar/> | when loading show it as an indicator, you can use your component| ✔   | ✔ | <3.0 |
| activityIndicatorProps  | object      | {color:'#009900',progressTintColor:'#009900'} | activityIndicator props | ✔ | ✔ | 3.1 |
| enableAntialiasing  | bool            | true        | improve rendering a little bit on low-res screens, but maybe course some problem on Android 4.4, so add a switch  | ✖   | ✔ | <3.0 |
| onLoadProgress      | function(percent) | null        | callback when loading, return loading progress (0-1) | ✔   | ✔ | <3.0 |
| onLoadComplete      | function(numberOfPages, path) | null        | callback when pdf load completed, return total page count and pdf local/cache path | ✔   | ✔ | <3.0 |
| onPageChanged       | function(page,numberOfPages)  | null        | callback when page changed ,return current page and total page count | ✔   | ✔ | <3.0 |
| onError       | function(error) | null        | callback when error happened | ✔   | ✔ | <3.0 |
| onPageSingleTap   | function(page)  | null        | callback when page was single tapped | ✔ | ✔ | 3.0 |
| onScaleChanged    | function(scale) | null        | callback when scale page | ✔ | ✔ | 3.0 |

#### parameters of source

| parameter    | Description | default | iOS | Android |
| ------------ | ----------- | ------- | --- | ------- |
| uri          | pdf source, see the forllowing for detail.| required | ✔   | ✔ |
| cache        | use cache or not | false | ✔ | ✔ |
| expiration   | cache file expired seconds (0 is not expired) | 0 | ✔ | ✔ |
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
