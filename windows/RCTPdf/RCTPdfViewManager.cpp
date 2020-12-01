#include "pch.h"
#include "NativeModules.h"
#include "JSValueXaml.h"
#include "RCTPdfViewManager.h"
#include "RCTPdfControl.h"

namespace winrt {
    using namespace Microsoft::ReactNative;
    using namespace Windows::Foundation;
    using namespace Windows::Foundation::Collections;
    using namespace Windows::UI;
    using namespace Windows::UI::Xaml;
    using namespace Windows::UI::Xaml::Controls;
}

namespace winrt::RCTPdf::implementation {
    // IViewManager
    winrt::hstring RCTPdfViewManager::Name() noexcept {
        return L"RCTPdf";
    }

    winrt::FrameworkElement RCTPdfViewManager::CreateView() noexcept {
        return winrt::RCTPdf::RCTPdfControl(m_reactContext);
    }

    // IViewManagerWithReactContext
    winrt::IReactContext RCTPdfViewManager::ReactContext() noexcept {
        return m_reactContext;
    }

    void RCTPdfViewManager::ReactContext(IReactContext reactContext) noexcept {
        m_reactContext = reactContext;
    }

    // IViewManagerWithNativeProperties
    IMapView<hstring, ViewManagerPropertyType> RCTPdfViewManager::NativeProps() noexcept {
        return winrt::RCTPdf::implementation::RCTPdfControl::NativeProps();
    }

    void RCTPdfViewManager::UpdateProperties(
        FrameworkElement const& view,
        IJSValueReader const& propertyMapReader) noexcept {
         if (auto module = view.try_as<winrt::RCTPdf::RCTPdfControl>()) {
            module.UpdateProperties(propertyMapReader);
        }
    }
    // IViewManagerWithExportedEventTypeConstants
    ConstantProviderDelegate RCTPdfViewManager::ExportedCustomBubblingEventTypeConstants() noexcept {
        return winrt::RCTPdf::implementation::RCTPdfControl::ExportedCustomBubblingEventTypeConstants();
    }

    ConstantProviderDelegate RCTPdfViewManager::ExportedCustomDirectEventTypeConstants() noexcept {
       return winrt::RCTPdf::implementation::RCTPdfControl::ExportedCustomDirectEventTypeConstants();
    }

    // IViewManagerWithCommands
    IVectorView<hstring> RCTPdfViewManager::Commands() noexcept {
        return winrt::RCTPdf::implementation::RCTPdfControl::Commands();
    }

    void RCTPdfViewManager::DispatchCommand(
        FrameworkElement const& view,
        winrt::hstring const& commandId,
        winrt::IJSValueReader const& commandArgsReader) noexcept {
        if (auto module = view.try_as<winrt::RCTPdf::RCTPdfControl>()) {
            module.DispatchCommand(commandId, commandArgsReader);
        }
    }
}
