#include "pch.h"
#include "RCTPdfControl.h"
#if __has_include("RCTPdfControl.g.cpp")
#include "RCTPdfControl.g.cpp"
#endif

using namespace winrt;
using namespace Windows::UI::Xaml;
using namespace Microsoft::ReactNative;
using namespace Windows::Data::Json;
using namespace Windows::Data::Pdf;
using namespace Windows::Foundation;
using namespace Windows::Storage;
using namespace Windows::Storage::Streams;
using namespace Windows::Storage::Pickers;
using namespace Windows::UI;
using namespace Windows::UI::Core;
using namespace Windows::UI::Popups;
using namespace Windows::UI::Xaml;
using namespace Windows::UI::Xaml::Controls;
using namespace Windows::UI::Xaml::Input;
using namespace Windows::UI::Xaml::Media;
using namespace Windows::UI::Xaml::Media::Imaging;

namespace winrt::RCTPdf::implementation
{
  PDFPageInfo::PDFPageInfo(winrt::Windows::UI::Xaml::Controls::Image image, winrt::Windows::Data::Pdf::PdfPage page, double imageScale, double renderScale) :
    image(image), page(page), imageScale(imageScale), renderScale(renderScale), scaledTopOffset(0), scaledLeftOffset(0) {
    auto dims = page.Size();
    height = (unsigned)dims.Height;
    width = (unsigned)dims.Width;
    scaledHeight = (unsigned)(height * imageScale);
    scaledWidth = (unsigned)(width * imageScale);
  }
  PDFPageInfo::PDFPageInfo(const PDFPageInfo& rhs) :
    height(rhs.height), width(rhs.width), scaledHeight(rhs.scaledHeight), scaledWidth(rhs.scaledWidth),
    scaledTopOffset(rhs.scaledTopOffset), scaledLeftOffset(rhs.scaledTopOffset), imageScale(rhs.imageScale),
    renderScale((double)rhs.renderScale), image(rhs.image), page(rhs.page)
  { }
  PDFPageInfo::PDFPageInfo(PDFPageInfo&& rhs) :
    height(rhs.height), width(rhs.width), scaledHeight(rhs.scaledHeight), scaledWidth(rhs.scaledWidth),
    scaledTopOffset(rhs.scaledTopOffset), scaledLeftOffset(rhs.scaledTopOffset), imageScale(rhs.imageScale),
    renderScale((double)rhs.renderScale), image(std::move(rhs.image)), page(std::move(rhs.page))
  { }
  unsigned PDFPageInfo::pageVisiblePixels(bool horizontal, double viewportStart, double viewportEnd) const {
    if (viewportEnd < viewportStart)
      std::swap(viewportStart, viewportEnd);
    auto pageStart = horizontal ? scaledLeftOffset : scaledTopOffset;
    auto pageSize = PDFPageInfo::pageSize(horizontal);
    auto pageEnd = pageStart + pageSize;
    auto uViewportStart = (unsigned)viewportStart;
    auto uViewportEnd = (unsigned)viewportEnd;
    if (pageStart >= uViewportStart && pageStart <= uViewportEnd) { // we see the top edge
      return (std::min)(pageEnd, uViewportEnd) - pageStart;
    }
    if (pageEnd >= uViewportStart && pageEnd <= uViewportEnd) { // we see the bottom edge
      return pageEnd - (std::max)(pageStart, uViewportStart);
    }
    if (pageStart <= uViewportStart && pageEnd >= uViewportEnd) {// we see the entire page
      return uViewportEnd - uViewportStart;
    }
    return 0;
  }
  unsigned PDFPageInfo::pageSize(bool horizontal) const {
    return horizontal ? scaledWidth : scaledHeight;
  }
  bool PDFPageInfo::needsRender() const {
    double currentRenderScale = renderScale;
    return currentRenderScale < imageScale || currentRenderScale > imageScale * m_downscaleTreshold;
  }
  winrt::Windows::Foundation::IAsyncAction PDFPageInfo::render() {
    return render(imageScale);
  }
  winrt::Windows::Foundation::IAsyncAction PDFPageInfo::render(double useScale) {
    double currentRenderScale;
    while (true) {
      currentRenderScale = renderScale;
      if (!(currentRenderScale < imageScale || currentRenderScale > imageScale * m_downscaleTreshold))
        co_return;
      if (renderScale.compare_exchange_weak(currentRenderScale, useScale))
        break;
      if (renderScale > useScale)
        co_return;
    }
    PdfPageRenderOptions renderOptions;
    auto dims = page.Size();
    renderOptions.DestinationHeight(static_cast<uint32_t>(dims.Height * useScale));
    renderOptions.DestinationWidth(static_cast<uint32_t>(dims.Width * useScale));
    InMemoryRandomAccessStream stream;
    co_await page.RenderToStreamAsync(stream, renderOptions);
    BitmapImage bitmap;
    co_await bitmap.SetSourceAsync(stream);
    if (renderScale == useScale)
      image.Source(bitmap);
  }
  
  RCTPdfControl::RCTPdfControl(IReactContext const& reactContext) : m_reactContext(reactContext) {
    InitializeComponent();
  }

  winrt::Windows::Foundation::Collections::IMapView<winrt::hstring, winrt::Microsoft::ReactNative::ViewManagerPropertyType> RCTPdfControl::NativeProps() noexcept {
    auto nativeProps = winrt::single_threaded_map<hstring, ViewManagerPropertyType>();
    nativeProps.Insert(L"path", ViewManagerPropertyType::String);
    nativeProps.Insert(L"page", ViewManagerPropertyType::Number);
    nativeProps.Insert(L"scale", ViewManagerPropertyType::Number);
    nativeProps.Insert(L"minScale", ViewManagerPropertyType::Number);
    nativeProps.Insert(L"maxScale", ViewManagerPropertyType::Number);
    nativeProps.Insert(L"horizontal", ViewManagerPropertyType::Boolean);
    nativeProps.Insert(L"fitWidth", ViewManagerPropertyType::Boolean);
    nativeProps.Insert(L"fitPolicy", ViewManagerPropertyType::Number);
    nativeProps.Insert(L"spacing", ViewManagerPropertyType::Number);
    nativeProps.Insert(L"password", ViewManagerPropertyType::String);
    nativeProps.Insert(L"background", ViewManagerPropertyType::Color);
    nativeProps.Insert(L"enablePaging", ViewManagerPropertyType::Boolean);
    nativeProps.Insert(L"enableRTL", ViewManagerPropertyType::Boolean);
    nativeProps.Insert(L"singlePage", ViewManagerPropertyType::Boolean);

    return nativeProps.GetView();
  }

  void RCTPdfControl::UpdateProperties(winrt::Microsoft::ReactNative::IJSValueReader const& propertyMapReader) noexcept {    
    const JSValueObject& propertyMap = JSValue::ReadObjectFrom(propertyMapReader);
    std::optional<std::string> pdfURI;
    std::optional<std::string> pdfPassword;
    std::optional<int> setPage;
    std::optional<double> minScale, maxScale, scale;
    std::optional<bool> horizontal;
    std::optional<bool> fitWidth;
    std::optional<int> fitPolicy;
    std::optional<int> spacing;
    std::optional<bool> reverse;
    std::optional<bool> singlePage;
    std::optional<bool> enablePaging;
    for (auto const& pair : propertyMap) {
      auto const& propertyName = pair.first;
      auto const& propertyValue = pair.second;
      if (propertyName == "path") {
        pdfURI = propertyValue != nullptr ? propertyValue.AsString() : "";
      }
      else if (propertyName == "password") {
        pdfPassword = propertyValue != nullptr ? propertyValue.AsString() : "";
      }
      else if (propertyName == "page" && propertyValue != nullptr) {
        setPage = propertyValue.AsInt32() - 1;
      }
      else if (propertyName == "scale" && propertyValue != nullptr) {
        scale = propertyValue.AsDouble();
      }
      else if (propertyName == "minScale" && propertyValue != nullptr) {
        minScale = propertyValue.AsDouble();
      }
      else if (propertyName == "maxScale" && propertyValue != nullptr) {
        maxScale = propertyValue.AsDouble();
      }
      else if (propertyName == "horizontal" && propertyValue != nullptr) {
        horizontal = propertyValue.AsBoolean();
      }
      else if (propertyName == "enablePaging" && propertyValue != nullptr) {
        enablePaging = propertyValue.AsBoolean();
      }
      else if (propertyName == "fitWidth" && propertyValue != nullptr) {
        fitWidth = propertyValue.AsBoolean();
      }
      else if (propertyName == "fitPolicy" && propertyValue != nullptr) {
        fitPolicy = propertyValue.AsInt32();
      }
      else if (propertyName == "spacing" && propertyValue != nullptr) {
        maxScale = propertyValue.AsInt32();
      }
      else if (propertyName == "enableRTL" && propertyValue != nullptr) {
        reverse = propertyValue.AsBoolean();
      }
      else if (propertyName == "singlePage" && propertyValue != nullptr) {
        singlePage = propertyValue.AsBoolean();
      }
      else if (propertyName == "backgroundColor" && propertyValue != nullptr) {
        auto color = propertyValue.AsInt32();
        winrt::Windows::UI::Color brushColor;
        brushColor.A = (color >> 24) & 0xff;
        brushColor.R = (color >> 16) & 0xff;
        brushColor.G = (color >> 8) & 0xff;
        brushColor.B = color & 0xff;
        PagesContainer().Background(SolidColorBrush(brushColor));
      }
    }
    // If we are loading a new PDF:
    std::shared_lock lock(m_rwlock);
    if (pdfURI && *pdfURI != m_pdfURI ||
        pdfPassword && *pdfPassword != m_pdfPassword ||
        (reverse && *reverse != m_reverse) ||
        (enablePaging && *enablePaging != m_enablePaging) ||
        (singlePage && (m_pages.empty() || *singlePage && m_pages.size() != 1 || !*singlePage && m_pages.size() == 1)) ) {
      lock.unlock();
      std::unique_lock write_lock(m_rwlock);
      m_pdfURI = pdfURI.value_or("");
      m_pdfPassword = pdfPassword.value_or("");
      m_currentPage = setPage.value_or(0);
      m_scale = scale.value_or(m_defualtZoom);
      m_minScale = minScale.value_or(m_defaultMinZoom);
      m_maxScale = maxScale.value_or(m_defaultMaxZoom);
      m_horizontal = horizontal.value_or(false);
      m_enablePaging = enablePaging.value_or(false);
      int useFitPolicy = 2;
      if (fitWidth)
        useFitPolicy = 0;
      if (fitPolicy)
        useFitPolicy = *fitPolicy;
      m_margins = spacing.value_or(m_defaultMargins);
      m_reverse = reverse.value_or(false);
      LoadPDF(std::move(write_lock), useFitPolicy, singlePage.value_or(false));
    } else {
      // If we are updating the pdf:
      m_minScale = minScale.value_or(m_minScale);
      m_maxScale = maxScale.value_or(m_maxScale);
      bool needScroll = false;
      if (horizontal && *horizontal != m_horizontal) {
        SetOrientation(*horizontal);
        needScroll = true;
      }
      if (setPage) {
        m_currentPage = *setPage;
        needScroll = true;
      }
      if ((scale && *scale != m_scale) || (spacing && *spacing != m_margins)) {
        Rescale(scale.value_or(m_scale), spacing.value_or(m_margins), !needScroll);
      }
      if (needScroll) {
        GoToPage(m_currentPage);
      }
    }
  }

  winrt::Microsoft::ReactNative::ConstantProviderDelegate RCTPdfControl::ExportedCustomBubblingEventTypeConstants() noexcept {
    return [](IJSValueWriter const& constantWriter) {
      WriteCustomDirectEventTypeConstant(constantWriter, "Change");
    };
  }
  winrt::Microsoft::ReactNative::ConstantProviderDelegate RCTPdfControl::ExportedCustomDirectEventTypeConstants() noexcept {
    return nullptr;
  }
  
  winrt::Windows::Foundation::Collections::IVectorView<winrt::hstring> RCTPdfControl::Commands() noexcept {
    auto commands = winrt::single_threaded_vector<hstring>();
    commands.Append(L"setPage");
    return commands.GetView();
  }

  void RCTPdfControl::DispatchCommand(winrt::hstring const& commandId, winrt::Microsoft::ReactNative::IJSValueReader const& commandArgsReader) noexcept {
    auto commandArgs = JSValue::ReadArrayFrom(commandArgsReader);
    if (commandId == L"setPage" && commandArgs.size() > 0) {
      std::shared_lock lock(m_rwlock);
      auto page = commandArgs[0].AsInt32() - 1;
      GoToPage(page);
    }
  }

  void RCTPdfControl::PagesContainer_PointerWheelChanged(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::Input::PointerRoutedEventArgs const& e) {
    winrt::Windows::System::VirtualKeyModifiers modifiers = e.KeyModifiers();
    if ((modifiers & winrt::Windows::System::VirtualKeyModifiers::Control) != winrt::Windows::System::VirtualKeyModifiers::Control)
      return;
    double delta = (e.GetCurrentPoint(*this).Properties().MouseWheelDelta() / WHEEL_DELTA);
    std::shared_lock lock(m_rwlock);
    auto newScale = (std::max)((std::min)(m_scale * pow(m_zoomMultiplier, delta), m_maxScale), m_minScale);
    Rescale(newScale, m_margins, true);
    e.Handled(true);
  }

  void RCTPdfControl::Pages_SizeChanged(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::SizeChangedEventArgs const&) {
    if (m_targetHorizontalOffset || m_targetVerticalOffset) {
      auto container = PagesContainer();
      PagesContainer().ChangeView(m_targetHorizontalOffset.value_or(container.HorizontalOffset()),
        m_targetVerticalOffset.value_or(container.VerticalOffset()),
        nullptr,
        true);
      m_targetHorizontalOffset.reset();
      m_targetVerticalOffset.reset();
    }
  }

  winrt::fire_and_forget RCTPdfControl::PagesContainer_ViewChanged(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::Controls::ScrollViewerViewChangedEventArgs const& args)
  {
    auto lifetime = get_strong();
    auto container = PagesContainer();
    auto currentHorizontalOffset = container.HorizontalOffset();
    auto currentVerticalOffset = container.VerticalOffset();
    double offsetStart = m_horizontal ? currentHorizontalOffset : currentVerticalOffset;
    double viewSize = m_horizontal ? container.ViewportWidth() : container.ViewportHeight();
    double offsetEnd = offsetStart + viewSize;
    std::shared_lock lock(m_rwlock, std::defer_lock);
    if (args.IsIntermediate() || !lock.try_lock() || viewSize == 0 || m_pages.empty())
      return;
    // Go through pages until we reach a visible page
    int page = 0;
    double visiblePagePixels = 0;
    for (; page < (int)m_pages.size(); ++page) {
      visiblePagePixels = m_pages[page].pageVisiblePixels(m_horizontal, offsetStart, offsetEnd);
      if (visiblePagePixels > 0)
        break;
    }
    if (page == (int)m_pages.size()) {
      --page;
    }
    else {
      double pagePixels = m_pages[page].pageSize(m_horizontal);
      // #"page" is the first visible page. Check how much of the view port this page covers...
      double viewCoveredByPage = visiblePagePixels / viewSize;
      // ...and how much of the page is visible:
      double pageVisiblePart = visiblePagePixels / pagePixels;
      // If:
      //  - less than 50% of the screen is covered by the page
      //  - less than 50% of the page is visible (important if more than one page fits the screen)
      //  - there is a next page
      // move the indicator to that page:
      if (viewCoveredByPage < 0.5 && pageVisiblePart < 0.5 && page + 1 < (int)m_pages.size()) {
        ++page;
      }
    }
    // Render all visible pages - first the current one, then the next visible ones and one
    // more, then the one before that might be partly visible, then one more before
    co_await RenderVisiblePages(page);
    if (page != m_currentPage) {
      m_currentPage = page;
      SignalPageChange(m_currentPage + 1, m_pages.size());
    }
  }

  void RCTPdfControl::PagesContainer_Tapped(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::Input::TappedRoutedEventArgs const& args) {
    auto position = args.GetPosition(*this);
    std::shared_lock lock(m_rwlock);
    int scaledDoubleMargin = (int)(m_scale * m_margins * 2);
    int page = 0;
    int xPosition = (int)(position.X + PagesContainer().HorizontalOffset());
    int yPosition = (int)(position.Y + PagesContainer().VerticalOffset());
    for (; page < (int)m_pages.size(); ++page) {
      if (m_horizontal) {
        if (xPosition >= (int)m_pages[page].scaledLeftOffset &&
            xPosition <= (int)(m_pages[page].scaledLeftOffset + m_pages[page].scaledWidth + scaledDoubleMargin))
          break;   
      } else {
        if (yPosition >= (int)m_pages[page].scaledTopOffset &&
            yPosition <= (int)(m_pages[page].scaledTopOffset + m_pages[page].scaledHeight + scaledDoubleMargin))
          break;
      }
    }
    if (page == (int)m_pages.size()) {
      page = m_currentPage;
    }
    SignalPageTapped(page, (int)position.X, (int)position.Y);
    PagesContainer().Focus(FocusState::Pointer);
    args.Handled(true);
  }


  void RCTPdfControl::PagesContainer_DoubleTapped(winrt::Windows::Foundation::IInspectable const&, winrt::Windows::UI::Xaml::Input::DoubleTappedRoutedEventArgs const& args)
  {
    std::shared_lock lock(m_rwlock);
    double newScale = (std::min)(m_scale * m_zoomMultiplier, m_maxScale);
    Rescale(newScale, m_margins, true);
    PagesContainer().Focus(FocusState::Pointer);
    args.Handled(true);
  }

  void RCTPdfControl::ChangeScroll(double targetHorizontalOffset, double targetVerticalOffset) {
    auto container = PagesContainer();
    auto maxHorizontalOffset = container.ScrollableWidth();
    auto maxVerticalOffset = container.ScrollableHeight();
    // If viewport is bigger than a page, it is possible that target offset is
    // smaller than max offset. Take that into account:
    if (targetHorizontalOffset <= maxHorizontalOffset + container.ViewportWidth() &&
      targetVerticalOffset <= maxVerticalOffset + container.ViewportHeight()) {
      PagesContainer().ChangeView((std::min)(targetHorizontalOffset, maxHorizontalOffset),
        (std::min)(targetVerticalOffset, maxVerticalOffset),
        nullptr, true);
    }
    else {
      m_targetHorizontalOffset = targetHorizontalOffset;
      m_targetVerticalOffset = targetVerticalOffset;
    }
  }

  void RCTPdfControl::UpdatePagesInfoMarginOrScale() {
    unsigned scaledMargin = (unsigned)(m_scale * m_margins);
    for (auto& page : m_pages) {
      page.imageScale = m_scale;
      page.scaledWidth = (unsigned)(page.width * m_scale);
      page.scaledHeight = (unsigned)(page.height * m_scale);
      page.image.Margin(ThicknessHelper::FromUniformLength(scaledMargin));
      page.image.Width(page.scaledWidth);
      page.image.Height(page.scaledHeight);
    }
    unsigned totalTopOffset = 0;
    unsigned totalLeftOffset = 0;
    unsigned doubleScaledMargin = scaledMargin * 2;
    if (m_reverse) {
      for (int page = m_pages.size() - 1; page >= 0; --page) {
        m_pages[page].scaledTopOffset = totalTopOffset;
        totalTopOffset += m_pages[page].scaledHeight + doubleScaledMargin;
        m_pages[page].scaledLeftOffset = totalLeftOffset;
        totalLeftOffset += m_pages[page].scaledWidth + doubleScaledMargin;
      }
    }
    else {
      for (int page = 0; page < (int)m_pages.size(); ++page) {
        m_pages[page].scaledTopOffset = totalTopOffset;
        totalTopOffset += m_pages[page].scaledHeight + doubleScaledMargin;
        m_pages[page].scaledLeftOffset = totalLeftOffset;
        totalLeftOffset += m_pages[page].scaledWidth + doubleScaledMargin;
      }
    }
  }

  void RCTPdfControl::GoToPage(int page) {
    if (page < 0 || page >= (int)m_pages.size()) {
      return;
    }
    if (m_enablePaging) {
      [&](int page) -> winrt::fire_and_forget {
        auto lifetime = get_strong();
        co_await m_pages[page].render();
      }(page);
      Pages().Items().ReplaceAll({ &m_pages[page].image, &m_pages[page].image + 1 });
    } else {
      auto neededOffset = m_horizontal ? m_pages[page].scaledLeftOffset : m_pages[page].scaledTopOffset;
      double horizontalOffset = m_horizontal ? neededOffset : PagesContainer().HorizontalOffset();
      double verticalOffset = m_horizontal ? PagesContainer().VerticalOffset() : neededOffset;
      ChangeScroll(horizontalOffset, verticalOffset);
    }
    SignalPageChange(page + 1, m_pages.size());
  }

  winrt::fire_and_forget RCTPdfControl::LoadPDF(std::unique_lock<std::shared_mutex> lock, int fitPolicy, bool singlePage) {
    auto lifetime = get_strong();
    auto pdfURI = m_pdfURI;
    auto uri = Uri(winrt::to_hstring(pdfURI));
    auto scheme = uri.SchemeName();
    if (scheme == L"file") {
      // backslashes only on Windows
      std::replace(begin(pdfURI), end(pdfURI), '/', '\\');
    }
    PdfDocument document = nullptr;
    try {
      auto file = scheme == L"file"
                  ? co_await StorageFile::GetFileFromPathAsync(winrt::to_hstring(pdfURI))
                  : co_await StorageFile::GetFileFromApplicationUriAsync(uri);
      document = co_await PdfDocument::LoadFromFileAsync(file, winrt::to_hstring(m_pdfPassword));
    }
    catch (winrt::hresult_error const& ex) {
      switch (ex.to_abi()) {
      case __HRESULT_FROM_WIN32(ERROR_WRONG_PASSWORD):
        SignalError("Password required or incorrect password.");
        co_return;
      case E_FAIL:
        SignalError("Document is not a valid PDF.");
        co_return;
      default:
        SignalError(winrt::to_string(ex.message()));
        co_return;
      }
    }
    if (!document) {
      SignalError("Could not load PDF.");
      co_return;
    }
    auto items = Pages().Items();
    items.Clear();
    m_pages.clear();
    SetOrientation(m_horizontal);
    if (document.PageCount() == 0) {
      if (fitPolicy != -1)
        m_scale = 1;
    }
    else {
      auto firstPageSize = document.GetPage(0).Size();
      auto viewWidth = PagesContainer().ViewportWidth();
      auto viewHeight = PagesContainer().ViewportHeight();
      switch (fitPolicy) {
      case 0:
        m_scale = viewWidth / (firstPageSize.Width + 2 * (double)m_margins);
        break;
      case 1:
        m_scale = viewHeight / (firstPageSize.Height + 2 * (double)m_margins);
        break;
      case 2:
        m_scale = (std::min)(viewWidth / (firstPageSize.Width + 2 * (double)m_margins), viewHeight / (firstPageSize.Height + 2 * (double)m_margins));
        break;
      default:
        break;
      }
    }
    unsigned pagesCount = document.PageCount();
    if (singlePage && pagesCount > 0)
      pagesCount = 1;
    for (unsigned pageIdx = 0; pageIdx < pagesCount; ++pageIdx) {
      auto page = document.GetPage(pageIdx);
      auto dims = page.Size();
      Image pageImage;
      pageImage.HorizontalAlignment(HorizontalAlignment::Center);
      pageImage.AllowFocusOnInteraction(false);
      Automation::AutomationProperties::SetName(pageImage, winrt::to_hstring("PDF Page " + std::to_string(pageIdx + 1)));
      m_pages.emplace_back(pageImage, page, m_scale, 0);
    }
    if (m_enablePaging) {
      items.Append(m_pages[m_currentPage].image);
    } else {
      if (m_reverse) {
        for (int page = m_pages.size() - 1; page >= 0; --page)
          items.Append(m_pages[page].image);
      }
      else {
        for (int page = 0; page < (int)m_pages.size(); ++page)
          items.Append(m_pages[page].image);
      }
    }
    UpdatePagesInfoMarginOrScale();
    lock.unlock();
    std::shared_lock shared_lock(m_rwlock);
    if (m_currentPage < 0)
      m_currentPage = 0;
    if (m_currentPage < (int)m_pages.size()) {
      co_await m_pages[m_currentPage].render();
      GoToPage(m_currentPage);
    }
    if (m_pages.empty()) {
      SignalLoadComplete(0, 0, 0);
    }
    else {
      SignalLoadComplete(m_pages.size(), m_pages.front().width, m_pages.front().height);
    }
    // Render low-res preview of the pages
    double useScale = (std::min)(m_scale, m_previewZoom);
    for (unsigned page = 0; page < m_pages.size(); ++page) {
      co_await m_pages[page].render(useScale);
    }
  }

  void RCTPdfControl::Rescale(double newScale, double newMargin, bool goToNewPosition) {
    if (newScale != m_scale || newMargin != m_margins) {
      double rescale = newScale / m_scale;
      double targetHorizontalOffset = PagesContainer().HorizontalOffset() * rescale;
      double targetVerticalOffset = PagesContainer().VerticalOffset() * rescale;
      if (newMargin != m_margins) {
        if (m_horizontal) {
          targetVerticalOffset += (double)m_currentPage * 2 * (newMargin - m_margins) * rescale;
        }
        else {
          targetHorizontalOffset += (double)m_currentPage * 2 * (newMargin - m_margins) * rescale;
        }
      }
      m_scale = newScale;
      m_margins = (int)newMargin;
      UpdatePagesInfoMarginOrScale();
      if (goToNewPosition) {
        ChangeScroll(targetHorizontalOffset, targetVerticalOffset);
      }
      SignalScaleChanged(m_scale);
    }
  }

  void RCTPdfControl::SetOrientation(bool horizontal) {
    m_horizontal = horizontal;
    StackPanel orientationSelector;
    if (FindName(winrt::to_hstring("OrientationSelector")).try_as<StackPanel>(orientationSelector))
    {
      orientationSelector.Orientation(m_horizontal ? Orientation::Horizontal : Orientation::Vertical);
    }
  }

  winrt::Windows::Foundation::IAsyncAction RCTPdfControl::RenderVisiblePages(int page) {
    auto lifetime = get_strong();
    auto container = PagesContainer();
    auto currentHorizontalOffset = container.HorizontalOffset();
    auto currentVerticalOffset = container.VerticalOffset();
    double offsetStart = m_horizontal ? currentHorizontalOffset : currentVerticalOffset;
    double viewSize = m_horizontal ? container.ViewportWidth() : container.ViewportHeight();
    double offsetEnd = offsetStart + viewSize;
    if (m_pages[page].needsRender()) {
      co_await m_pages[page].render();
    }
    auto pageToRender = page + 1;
    while (pageToRender < (int)m_pages.size() &&
      m_pages[pageToRender].pageVisiblePixels(m_horizontal, offsetStart, offsetEnd) > 0) {
      if (m_pages[pageToRender].needsRender()) {
        co_await m_pages[pageToRender].render();
      }
      ++pageToRender;
    }
    if (pageToRender < (int)m_pages.size() && m_pages[pageToRender].needsRender()) {
      co_await m_pages[pageToRender].render();
    }
    if (page >= 1 && m_pages[page - 1].needsRender()) {
      co_await m_pages[page - 1].render();
    }
    if (page >= 2 && m_pages[page - 2].needsRender()) {
      co_await m_pages[page - 2].render();
    }
  }

  void RCTPdfControl::SignalError(const std::string& error) {
    m_reactContext.DispatchEvent(
      *this,
      L"topChange",
      [&](winrt::Microsoft::ReactNative::IJSValueWriter const& eventDataWriter) noexcept {
        eventDataWriter.WriteObjectBegin();
        {
          WriteProperty(eventDataWriter, L"message", winrt::to_hstring("error|" + error));
        }
        eventDataWriter.WriteObjectEnd();
      });
  }
  void RCTPdfControl::SignalLoadComplete(int totalPages, int width, int height) {
    auto message = "loadComplete|" +
                   std::to_string(totalPages) + "|" +
                   std::to_string(width) + "|" +
                   std::to_string(height) + "|";
    m_reactContext.DispatchEvent(
      *this,
      L"topChange",
      [&](winrt::Microsoft::ReactNative::IJSValueWriter const& eventDataWriter) noexcept {
        eventDataWriter.WriteObjectBegin();
        {
          WriteProperty(eventDataWriter, L"message", winrt::to_hstring(message));
        }
        eventDataWriter.WriteObjectEnd();
      });
  }
  void RCTPdfControl::SignalPageChange(int page, int totalPages) {
    auto message = "pageChanged|" + std::to_string(page) + "|" + std::to_string(totalPages);
    m_reactContext.DispatchEvent(
      *this,
      L"topChange",
      [&](winrt::Microsoft::ReactNative::IJSValueWriter const& eventDataWriter) noexcept {
        eventDataWriter.WriteObjectBegin();
        {
          WriteProperty(eventDataWriter, L"message", winrt::to_hstring(message));
        }
        eventDataWriter.WriteObjectEnd();
      });
  }
  void RCTPdfControl::SignalScaleChanged(double scale) {
    m_reactContext.DispatchEvent(
      *this,
      L"topChange",
      [&](winrt::Microsoft::ReactNative::IJSValueWriter const& eventDataWriter) noexcept {
        eventDataWriter.WriteObjectBegin();
        {
          WriteProperty(eventDataWriter, L"message", winrt::to_hstring("scale|" + std::to_string(scale)));
        }
        eventDataWriter.WriteObjectEnd();
      });
  }
  void RCTPdfControl::SignalPageTapped(int page, int x, int y) {
    const std::string message = "pageSingleTap|" +
                                std::to_string(page + 1) + "|" +
                                std::to_string(x) + "|" +
                                std::to_string(y);
    m_reactContext.DispatchEvent(
      *this,
      L"topChange",
      [&](winrt::Microsoft::ReactNative::IJSValueWriter const& eventDataWriter) noexcept {
        eventDataWriter.WriteObjectBegin();
        {
          WriteProperty(eventDataWriter, L"message", winrt::to_hstring(message));
        }
        eventDataWriter.WriteObjectEnd();
      });
  }
}
