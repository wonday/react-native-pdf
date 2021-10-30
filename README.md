# react-native-pdf
[![npm](https://img.shields.io/npm/v/react-native-pdf.svg?style=flat-square)](https://www.npmjs.com/package/react-native-pdf)

A react native PDF view component (cross-platform support)

### Feature

* read a PDF from url, blob, local file or asset and can cache it.
* display horizontally or vertically
* drag and zoom
* double tap for zoom
* support password protected pdf
* jump to a specific page in the pdf

### Supported versions
We use [`react-native-blob-util`](https://github.com/RonRadtke/react-native-blob-util) to handle file system access in this package,
So you should install react-native-pdf and react-native-blob-util

> The table below shows the supported versions of React Native and react-native-blob-util for different versions of `react-native-pdf`.

| React Native              | 0.4x - 0.56     | 0.57    | 0.60+    | 0.62+    | 0.62+    |
| ------------------------- | --------------- | ------- | -------- | -------- | -------- |
| react-native-pdf          | 4.x.x - 5.0.x   | 5.0.9+  | 6.0.0+   | 6.2.0+   | 6.4.0+   |
| react-native-blob-util    |                 |         |          |          | 0.13.7+  |

### Installation

```bash
# Using npm
npm install react-native-pdf react-native-blob-util fbjs --save

# or using yarn:
yarn add react-native-pdf react-native-blob-util fbjs
```

Then follow the instructions for your platform to link react-native-pdf into your project:

### iOS installation
<details>
  <summary>iOS details</summary>

**React Native 0.60 and above**

Run `pod install` in the `ios` directory. Linking is not required in React Native 0.60 and above.

**React Native 0.59 and below**

```bash
react-native link react-native-blob-util
react-native link react-native-pdf
```
</details>

### Android installation
<details>
  <summary>Android details</summary>

**If you use RN 0.59.0 and above**, please add following to your android/app/build.gradle**
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

**React Native 0.59.0 and below**
```bash
react-native link react-native-blob-util
react-native link react-native-pdf
```


</details>

### Windows installation
<details>
  <sumary>Windows details</summary>

- Open your solution in Visual Studio 2019 (eg. `windows\yourapp.sln`)
- Right-click Solution icon in Solution Explorer > Add > Existing Project...
- If running RNW 0.62: add `node_modules\react-native-pdf\windows\RCTPdf\RCTPdf.vcxproj`
- If running RNW 0.62: add `node_modules\react-native-blob-util\windows\ReactNativeBlobUtil\ReactNativeBlobUtil.vcxproj`
- Right-click main application project > Add > Reference...
- Select `progress-view` and  in Solution Projects
  - If running 0.62, also select `RCTPdf` and `ReactNativeBlobUtil`
- In app `pch.h` add `#include "winrt/RCTPdf.h"`
  - If running 0.62, also select `#include "winrt/ReactNativeBlobUtil.h"`
- In `App.cpp` add `PackageProviders().Append(winrt::progress_view::ReactPackageProvider());` before `InitializeComponent();`
  - If running RNW 0.62, also add `PackageProviders().Append(winrt::RCTPdf::ReactPackageProvider());` and `PackageProviders().Append(winrt::ReactNativeBlobUtil::ReactPackageProvider());`


#### Bundling PDFs with the app
To add a `test.pdf` like in the example add:
```
<None Include="..\..\test.pdf">
  <DeploymentContent>true</DeploymentContent>
</None>
```
in the app `.vcxproj` file, before `<None Include="packages.config" />`.
</details>

### FAQ
<details>
  <summary>FAQ details</summary>

Q1. After installation and running, I can not see the pdf file.
A1: maybe you forgot to excute ```react-native link``` or it does not run correctly.
You can add it manually. For detail you can see the issue [`#24`](https://github.com/wonday/react-native-pdf/issues/24) and [`#2`](https://github.com/wonday/react-native-pdf/issues/2)

Q2. When running, it shows ```'Pdf' has no propType for native prop RCTPdf.acessibilityLabel of native type 'String'```
A2. Your react-native version is too old, please upgrade it to 0.47.0+ see also [`#39`](https://github.com/wonday/react-native-pdf/issues/39)

Q3. When I run the example app I get a white/gray screen / the loading bar isn't progressing .
A3. Check your uri, if you hit a pdf that is hosted on a `http` you will need to do the following:

**iOS:**
add an exception for the server hosting the pdf in the ios `info.plist`. Here is an example :

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

**Android:**
[`see here`](https://stackoverflow.com/questions/54818098/cleartext-http-traffic-not-permitted)

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
</details>

### ChangeLog
<details>
  <summary>ChangeLog details</summary>

v6.4.0
1. Remove sample for reducing NPM package size
2. Add support for setting a filename for the cached pdf file
3. Use react-native-blob-util instead of rn-fetch-blob
4. Add blob support
5. remove progress-view dependency

v6.3.0
1. Add windows support
2. Fixed some bugs

v6.2.2
1. Fixed incorrect type of onPageSingleTap and onScaleChanged argument
2. Fixed included missing setPage method in TypeScript and Flow types
3. fixed Xcode 12 compatibility

v6.2.1
1. Fixed typescript `onLoadComplete()` definition
2. Switched the AndroidPdfViewer dependency from Barteksc repo to TalbotGooday
3. Add singlePage property

v6.2.0
1. Fixed ReferenceError, url should be source.uri
2. Dependency bump to support React-Native >= 0.62

v6.1.2
1. Fixed wrong scale returned from onScaleChanged()
2. Fixed iOS Double Tap zoom
3. Fixed Some critical typo fixes

v6.1.1
1. Fixed undefined is not an object, crashing on ios

v6.1.0
1. Fixed react-native warning on `componentWill*`
2. Fixed onPageSingleTap
3. Set the PDF View background color to be transparent On iOS

v6.0.1
1. Expose prop to trust self-signed SSL certs
2. Use ViewStyleProp in index.js.flow, not deprecated StyleSheet.Styles

v6.0.0
1. Add JS callback onPressLink for pdf link press listener
2. Fix calling setState while unmounted


[[more]](https://github.com/wonday/react-native-pdf/releases)

</details>

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
        const source = { uri: 'http://samples.leanpub.com/thereactnativebook-sample.pdf', cache: true };
        //const source = require('./test.pdf');  // ios only
        //const source = {uri:'bundle-assets://test.pdf' };
        //const source = {uri:'file:///sdcard/test.pdf'};
        //const source = {uri:"data:application/pdf;base64,JVBERi0xLjcKJc..."};
        //const source = {uri:"content://com.example.blobs/xxxxxxxx-...?offset=0&size=xxx"};
        //const source = {uri:"blob:xxxxxxxx-...?offset=0&size=xxx"};

        return (
            <View style={styles.container}>
                <Pdf
                    source={source}
                    onLoadComplete={(numberOfPages,filePath) => {
                        console.log(`Number of pages: ${numberOfPages}`);
                    }}
                    onPageChanged={(page,numberOfPages) => {
                        console.log(`Current page: ${page}`);
                    }}
                    onError={(error) => {
                        console.log(error);
                    }}
                    onPressLink={(uri) => {
                        console.log(`Link pressed: ${uri}`);
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

| Property      | Type          | Default          | Description         | iOS   | Android | Windows | FirstRelease |
| ------------- |:-------------:|:----------------:| ------------------- | ------| ------- | ------- | ------------ |
| source        | object        | not null         | PDF source like {uri:xxx, cache:false}. see the following for detail.| ✔ | ✔ | ✔ | <3.0 |
| page          | number        | 1                | initial page index          | ✔   | ✔ | ✔ | <3.0 |
| scale         | number        | 1.0              | should minScale<=scale<=maxScale| ✔   | ✔ | ✔ | <3.0 |
| minScale         | number        | 1.0              | min scale| ✔   | ✔ | ✔ | 5.0.5 |
| maxScale         | number        | 3.0              | max scale| ✔   | ✔ | ✔ | 5.0.5 |
| horizontal    | bool          | false            | draw page direction, if you want to listen the orientation change, you can use  [[react-native-orientation-locker]](https://github.com/wonday/react-native-orientation-locker)| ✔   | ✔ | ✔ | <3.0 |
| fitWidth      | bool          | false            | if true fit the width of view, can not use fitWidth=true together with scale| ✔   | ✔ | ✔ | <3.0, abandoned from 3.0 |
| fitPolicy     | number        | 2                | 0:fit width, 1:fit height, 2:fit both(default)| ✔   | ✔ | ✔ | 3.0 |
| spacing       | number        | 10               | the breaker size between pages| ✔   | ✔ | ✔ | <3.0 |
| password      | string        | ""               | pdf password, if password error, will call OnError() with message "Password required or incorrect password."        | ✔   | ✔ | ✔ | <3.0 |
| style         | object        | {backgroundColor:"#eee"} | support normal view style, you can use this to set border/spacing color... | ✔   | ✔ | ✔ | <3.0 |
| renderActivityIndicator   | (progress) => Component       | <ProgressBar/> | when loading show it as an indicator, you can use your component| ✔   | ✔ | ✖ | <3.0 |
| enableAntialiasing  | bool            | true        | improve rendering a little bit on low-res screens, but maybe course some problem on Android 4.4, so add a switch  | ✖   | ✔ | ✖ | <3.0 |
| enablePaging  | bool            | false        | only show one page in screen   | ✔ | ✔ | ✔ | 5.0.1 |
| enableRTL  | bool            | false        | scroll page as "page3, page2, page1"  | ✔   | ✖ | ✔ | 5.0.1 |
| enableAnnotationRendering  | bool            | true        | enable rendering annotation, notice:iOS only support initial setting,not support realtime changing  | ✔ | ✔ | ✖ | 5.0.3 |
| trustAllCerts  | bool            | true        | Allow connections to servers with self-signed certification  | ✔ | ✔ | ✖ | 6.0.? |
| singlePage  | bool  | false | Only show first page, useful for thumbnail views | ✔ | ✔ | ✔ | 6.2.1 |
| onLoadProgress      | function(percent) | null        | callback when loading, return loading progress (0-1) | ✔   | ✔ | ✖ | <3.0 |
| onLoadComplete      | function(numberOfPages, path, {width, height}, tableContents) | null        | callback when pdf load completed, return total page count, pdf local/cache path, {width,height} and table of contents | ✔   | ✔ | ✔ but without tableContents | <3.0 |
| onPageChanged       | function(page,numberOfPages)  | null        | callback when page changed ,return current page and total page count | ✔   | ✔ | ✔ | <3.0 |
| onError       | function(error) | null        | callback when error happened | ✔   | ✔ | ✔ | <3.0 |
| onPageSingleTap   | function(page)  | null        | callback when page was single tapped | ✔ | ✔ | ✔ | 3.0 |
| onScaleChanged    | function(scale) | null        | callback when scale page | ✔ | ✔ | ✔ | 3.0 |
| onPressLink       | function(uri)   | null        | callback when link tapped | ✔ | ✔ | ✖ | 6.0.0 |

#### parameters of source

| parameter    | Description | default | iOS | Android | Windows |
| ------------ | ----------- | ------- | --- | ------- | ------- |
| uri          | pdf source, see the forllowing for detail.| required | ✔   | ✔ | ✔ |
| cache        | use cache or not | false | ✔ | ✔ | ✖ |
| cacheFileName | specific file name for cached pdf file | SHA1(uri) result | ✔ | ✔ | ✖ |
| expiration   | cache file expired seconds (0 is not expired) | 0 | ✔ | ✔ | ✖ |
| method       | request method when uri is a url | "GET" | ✔ | ✔ | ✖ |
| headers      | request headers when uri is a url | {} | ✔ | ✔ | ✖ |

#### types of source.uri

| Usage        | Description | iOS | Android | Windows |
| ------------ | ----------- | --- | ------- | ------- |
| `{uri:"http://xxx/xxx.pdf"}` | load pdf from a url | ✔   | ✔ | ✔ |
| `{require("./test.pdf")}` | load pdf relate to js file (do not need add by xcode) | ✔ | ✖ | ✖ |
| `{uri:"bundle-assets://path/to/xxx.pdf"}` | load pdf from assets, the file should be at android/app/src/main/assets/path/to/xxx.pdf | ✖ | ✔ | ✖ |
| `{uri:"bundle-assets://xxx.pdf"}` | load pdf from assets, you must add pdf to project by xcode. this does not support folder. | ✔ | ✖ | ✖ |
| `{uri:"data:application/pdf;base64,JVBERi0xLjcKJc..."}` | load pdf from base64 string | ✔   | ✔ | ✔ |
| `{uri:"file:///absolute/path/to/xxx.pdf"}` | load pdf from local file system | ✔  | ✔ | ✔  |
| `{uri:"ms-appx:///xxx.pdf"}}` | load pdf bundled with UWP app |  ✖ | ✖ | ✔ |
| `{uri:"content://com.example.blobs/xxxxxxxx-...?offset=0&size=xxx"}` | load pdf from content URI | ✔* | ✖ | ✖ |
| `{uri:"blob:xxxxxxxx-...?offset=0&size=xxx"}` | load pdf from blob URL | ✖ | ✔ | ✖ |

\*) requires building React Native from source with [this patch](https://github.com/facebook/react-native/pull/31789)
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
