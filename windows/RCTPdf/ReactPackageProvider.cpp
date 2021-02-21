#include "pch.h"
#include "ReactPackageProvider.h"
#if __has_include("ReactPackageProvider.g.cpp")
#  include "ReactPackageProvider.g.cpp"
#endif

#include "RCTPdfViewManager.h"

using namespace winrt::Microsoft::ReactNative;

namespace winrt::RCTPdf::implementation {
  void ReactPackageProvider::CreatePackage(IReactPackageBuilder const &packageBuilder) noexcept {
    packageBuilder.AddViewManager(L"RCTPdfViewManager", []() { return winrt::make<RCTPdfViewManager>(); });
  }
}
