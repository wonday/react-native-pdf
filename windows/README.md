# react-native-pdf Windows Implementation

- Open your solution in Visual Studio 2019 (eg. `windows\yourapp.sln`)
- Right-click Solution icon in Solution Explorer > Add > Existing Project...
  - If running RNW 0.62: add `node_modules\react-native-pdf\windows\RCTPdf\RCTPdf.vcxproj`
  - If running RNW 0.62: add `node_modules\rn-fetch-blob\windows\RNFetchBlob\RNFetchBlob.vcxproj`
- Right-click main application project > Add > Reference...
  - If running 0.62, also select `RCTPdf` and `RNFetchBlob`
- In app `pch.h` add `#include "winrt/RCTPdf.h"`
  - If running 0.62, also select `#include "winrt/RNFetchBlob.h"`
  - If running RNW 0.62, add `PackageProviders().Append(winrt::RCTPdf::ReactPackageProvider());` and `PackageProviders().Append(winrt::RNFetchBlob::ReactPackageProvider());` before `InitializeComponent();`


## Bundling PDFs with the app
To add a `test.pdf` like in the example add:
```
<None Include="..\..\test.pdf">
  <DeploymentContent>true</DeploymentContent>
</None>
```
in the app `.vcxproj` file, before `<None Include="packages.config" />`.
