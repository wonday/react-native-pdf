# react-native-pdf
[![npm](https://img.shields.io/npm/v/react-native-pdf.svg?style=flat-square)](https://www.npmjs.com/package/react-native-pdf)

A react native PDF view component (cross-platform support)

### Feature

* read a PDF from url/local file/asset and can cache it.
* display horizontally or vertically
* drag and zoom
* double tap for zoom
* support password protected pdf
* jump to a specific page in the pdf

### Supported versions - React Native / react-native-pdf

> The table below shows the supported versions of React Native for different versions of `react-native-pdf`.

| react-native-pdf          |  4.x.x - 5.0.x   |      5.0.9+      |
| ------------------------- | :------: | :-------------: |
| React Native              | 0.4x - 0.56  |  ^0.57  |

### Installation
We use [`rn-fetch-blob`](https://github.com/joltup/rn-fetch-blob) to handle file system access in this package,
So you should install react-native-pdf and rn-fetch-blob
*Notice: rn-fetch-blob v0.10.14 has a bug, please use v0.10.13*

```bash
npm install rn-fetch-blob --save
npm install react-native-pdf --save

react-native link rn-fetch-blob
react-native link react-native-pdf
```

**if you use RN 0.59.0+, please add following to your android/app/build.gradle**
```diff
android {

+    packagingOptions {
+       pickFirst 'lib/x86/libc++_shared.so'
+       pickFirst 'lib/x86_64/libjsc.so'
+       pickFirst 'lib/arm64-v8a/libjsc.so'
+       pickFirst 'lib/arm64-v8a/libc++_shared.so'
+       pickFirst 'lib/x86_64/libc++_shared.so'
+       pickFirst 'lib/armeabi-v7a/libc++_shared.so'
+     }

   }
```

### FAQ

Q1. After installation and running, I can not see the pdf file.  
A1: maybe you forgot to excute ```react-native link``` or it does not run correctly.
You can add it manually. For detail you can see the issue [`#24`](https://github.com/wonday/react-native-pdf/issues/24) and [`#2`](https://github.com/wonday/react-native-pdf/issues/2)

Q2. When running, it shows ```'Pdf' has no propType for native prop RCTPdf.acessibilityLabel of native type 'String'```  
A2. Your react-native version is too old, please upgrade it to 0.47.0+ see also [`#39`](https://github.com/wonday/react-native-pdf/issues/39)

Q3. When I run the example app I get a white screen / the loading bar isn't progressing on IOS.  
A3. Check your uri, if you hit a pdf that is hosted on a `http` you will need to add an exception for the server hosting the pdf in the ios `info.plist`. Here is an example :  

```
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>yourserver.com</key>
    <dict>
      <!--Include to allow subdomains-->
      <key>NSIncludesSubdomains</key>
      <true/>
      <!--Include to allow HTTP requests-->
      <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
      <true/>
      <!--Include to specify minimum TLS version-->
      <key>NSTemporaryExceptionMinimumTLSVersion</key>
      <string>TLSv1.1</string>
    </dict>
  </dict>
</dict>
```

Q4. why doesn't it work with react native expo?.  
A4. Expo does not support native module. you can read more expo caveats [`here`](https://facebook.github.io/react-native/docs/getting-started.html#caveats)

Q5. Why can't I run the iOS example? `'Failed to build iOS project. We ran "xcodebuild" command but it exited with error code 65.'`
A5. Run the following commands in the project folder (e.g. `react-native-pdf/example`) to ensure that all dependencies are available:
```
yarn install (or npm install)
cd ios
pod install
cd ..
react-native run-ios
```


### ChangeLog

v5.1.4
1. Update example project to RN 0.60.4
2. fix blank view after native module got recycled in onDetachedFromWindow event
3. restore singleTap, only callback, do not change scale

v5.1.3
1. remove singleTap action from iOS, make the same with Android.

v5.1.2
1. fix overflow when zoom on Android

v5.1.1
1. call onScaleChanged when tapped on iOS
2. fix overflow when zoom
3. add packagingOptions for Detox e2e tests build and androidTest target
4. add activityIndicatorProps to index.d.ts

v5.1.0
1. remove encodeURI(), **Degrade Notice: If you use Chinese/Japanese/Korean path, please encodeURI() yourself**
2. fix enableAnnotationRendering on iOS
3. Trusting certificates for api http redirection

v5.0.12
1. fix some codes for code safe
2. add flow typings
3. update style prop type

v5.0.11
1. fix sample codes

v5.0.10
1. support enablePaging for ios<11.0
2. disable long press on ios (the same with android)
3. make iOS singleTap scale the same action with android
4. recreate sample with RN 0.57

v5.0.9
1. fix podspec
2. NS_CLASS_AVAILABLE_IOS(11_0) to PDFKit related codes
3. Fix pdfs when pipe appears in table content json
4. modify build.gradle for RN 0.57

v5.0.8
1. fix podspec

v5.0.7
1. onLoadComplete return table of contents
2. delete tmp file after downloaded

v5.0.6
1. add accessible to PdfPageView
2. restore podspec

v5.0.5
1. add minScale, maxScale props
2. fix pdf display box
3. fix Content-length check

v5.0.4
1. fix ios background not work
2. fix can not show two pdf in in one page

v5.0.3
1. add enableAnnotationRendering property support, default enableAnnotationRendering=true
2. android build.gradle can reference root project sdk and buildTool setting
3. fix ios progressbar not work

v5.0.2
1. fix file successfully download check

v5.0.1
1. add paging support (ios and android)
2. add RTL support (ios)
3. fix position when set page (ios)

v5.0.0 (**break change**)
1. use iOS PDFKit to show pdf (iOS SDK>=11)
2. use js+native to show pdf (iOS SDK<11, the same with 4.0.0)
3. support pdf with layers (iOS SDK>=11)
4. support pdf with links (iOS SDK>=11)
5. fix zoom (iOS SDK>=11)


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
        height:Dimensions.get('window').height,
    }
});

```


### Configuration

| Property      | Type          | Default          | Description         | iOS   | Android | FirstRelease |
| ------------- |:-------------:|:----------------:| ------------------- | ------| ------- | ------------ |
| source        | object        | not null         | PDF source like {uri:xxx, cache:false}. see the following for detail.| ✔ | ✔ | <3.0 |
| page          | number        | 1                | initial page index          | ✔   | ✔ | <3.0 |
| scale         | number        | 1.0              | should minScale<=scale<=maxScale| ✔   | ✔ | <3.0 |
| minScale         | number        | 1.0              | min scale| ✔   | ✔ | 5.0.5 |
| maxScale         | number        | 3.0              | max scale| ✔   | ✔ | 5.0.5 |
| horizontal    | bool          | false            | draw page direction, if you want to listen the orientation change, you can use  [[react-native-orientation-locker]](https://github.com/wonday/react-native-orientation-locker)| ✔   | ✔ | <3.0 |
| fitWidth      | bool          | false            | if true fit the width of view, can not use fitWidth=true together with scale| ✔   | ✔ | <3.0, abandoned from 3.0 |
| fitPolicy     | number        | 2                | 0:fit width, 1:fit height, 2:fit both(default)| ✔   | ✔ | 3.0 |
| spacing       | number        | 10               | the breaker size between pages| ✔   | ✔ | <3.0 |
| password      | string        | ""               | pdf password, if password error, will call OnError() with message "Password required or incorrect password."        | ✔   | ✔ | <3.0 |
| style         | object        | {backgroundColor:"#eee"} | support normal view style, you can use this to set border/spacing color... | ✔   | ✔ | <3.0 |
| activityIndicator   | Component       | <ProgressBar/> | when loading show it as an indicator, you can use your component| ✔   | ✔ | <3.0 |
| activityIndicatorProps  | object      | {color:'#009900', progressTintColor:'#009900'} | activityIndicator props | ✔ | ✔ | 3.1 |
| enableAntialiasing  | bool            | true        | improve rendering a little bit on low-res screens, but maybe course some problem on Android 4.4, so add a switch  | ✖   | ✔ | <3.0 |
| enablePaging  | bool            | false        | only show one page in screen   | ✔ | ✔ | 5.0.1 |
| enableRTL  | bool            | false        | scroll page as "page3, page2, page1"  | ✔   | ✖ | 5.0.1 |
| enableAnnotationRendering  | bool            | true        | enable rendering annotation, notice:iOS only support initial setting,not support realtime changing  | ✔ | ✔ | 5.0.3 |
| onLoadProgress      | function(percent) | null        | callback when loading, return loading progress (0-1) | ✔   | ✔ | <3.0 |
| onLoadComplete      | function(numberOfPages, path, {width, height}, tableContents) | null        | callback when pdf load completed, return total page count, pdf local/cache path, {width,height} and table of contents | ✔   | ✔ | <3.0 |
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


### Methods
* [setPage](#setPage)

Methods operate on a ref to the PDF element. You can get a ref with the following code:
```
return (
  <Pdf
    ref={(pdf) => { this.pdf = pdf; }}
    source={source}
    ...
  />
);
```

#### setPage()
`setPage(pageNumber)`

Set the current page of the PDF component. pageNumber is a positive integer. If pageNumber > numberOfPages, current page is not changed.

Example:
```
this.pdf.setPage(42); // Display the answer to the Ultimate Question of Life, the Universe, and Everything
```
