# react-native-pdf Windows Implementation

Since the module uses react-native-progress-view, it also needs to be referenced in the App:
- Open your solution in Visual Studio 2019 (eg. `windows\yourapp.sln`)
- Right-click Solution icon in Solution Explorer > Add > Existing Project...
- Add `node_modules\@react-native-community\progress-view\windows\progress-view\progress-view.vcxproj`
- If running RNW 0.62: add `node_modules\react-native-pdf\windows\RCTPdf\RCTPdf.vcxproj`
- If running RNW 0.62: add `node_modules\rn-fetch-blob\windows\RNFetchBlob\RNFetchBlob.vcxproj`
- Right-click main application project > Add > Reference...
  - Select `progress-view` and  in Solution Projects
  - If running 0.62, also select `RCTPdf` and `RNFetchBlob`
- In app `pch.h` add `#include "winrt/progress_view.h"` and `#include "winrt/RCTPdf.h"`
  - If running 0.62, also select `#include "winrt/RNFetchBlob.h"`
- In `App.cpp` add `PackageProviders().Append(winrt::progress_view::ReactPackageProvider());` before `InitializeComponent();`
- If running RNW 0.62, also add `PackageProviders().Append(winrt::RCTPdf::ReactPackageProvider());` and `PackageProviders().Append(winrt::RNFetchBlob::ReactPackageProvider());`


## Bundling PDFs with the app
To add a `test.pdf` like in the example add:
```
<None Include="..\..\test.pdf">
  <DeploymentContent>true</DeploymentContent>
</None>
```
in the app `.vcxproj` file, before `<None Include="packages.config" />`.
