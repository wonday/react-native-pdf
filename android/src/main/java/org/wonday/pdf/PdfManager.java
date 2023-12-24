/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

package org.wonday.pdf;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.facebook.infer.annotation.Assertions;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.module.annotations.ReactModule;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

import com.facebook.react.uimanager.ViewManagerDelegate;
import com.facebook.react.viewmanagers.RNPDFPdfViewManagerDelegate;
import com.facebook.react.viewmanagers.RNPDFPdfViewManagerInterface;

@ReactModule(name = PdfManager.REACT_CLASS)
public class PdfManager extends SimpleViewManager<PdfView> implements RNPDFPdfViewManagerInterface<PdfView> {
    public static final String REACT_CLASS = "RNPDFPdfView";
    private Context context;
    private PdfView pdfView;
    private final ViewManagerDelegate<PdfView> mDelegate;

    @Nullable
    @Override
    protected ViewManagerDelegate<PdfView> getDelegate() {
        return mDelegate;
    }

    public PdfManager() {
        mDelegate = new RNPDFPdfViewManagerDelegate<>(this);
    }

    public PdfManager(ReactApplicationContext reactContext){
        this.context = reactContext;
        mDelegate = new RNPDFPdfViewManagerDelegate<>(this);
    }

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    public PdfView createViewInstance(ThemedReactContext context) {
        this.pdfView = new PdfView(context,null);
        return pdfView;
    }

    @Override
    public void onDropViewInstance(PdfView pdfView) {
        pdfView = null;
    }

    @ReactProp(name = "path")
    public void setPath(PdfView pdfView, String path) {
        pdfView.setPath(path);
    }

    // page start from 1
    @ReactProp(name = "page")
    public void setPage(PdfView pdfView, int page) {
        pdfView.setPage(page);
    }

    @ReactProp(name = "scale")
    public void setScale(PdfView pdfView, float scale) {
        pdfView.setScale(scale);
    }

    @ReactProp(name = "minScale")
    public void setMinScale(PdfView pdfView, float minScale) {
        pdfView.setMinScale(minScale);
    }

    @ReactProp(name = "maxScale")
    public void setMaxScale(PdfView pdfView, float maxScale) {
        pdfView.setMaxScale(maxScale);
    }

    @ReactProp(name = "horizontal")
    public void setHorizontal(PdfView pdfView, boolean horizontal) {
        pdfView.setHorizontal(horizontal);
    }

    @Override
    public void setShowsHorizontalScrollIndicator(PdfView view, boolean value) {
        // NOOP on Android
    }

    @Override
    public void setShowsVerticalScrollIndicator(PdfView view, boolean value) {
        // NOOP on Android
    }

    @ReactProp(name = "spacing")
    public void setSpacing(PdfView pdfView, int spacing) {
        pdfView.setSpacing(spacing);
    }

    @ReactProp(name = "password")
    public void setPassword(PdfView pdfView, String password) {
        pdfView.setPassword(password);
    }

    @ReactProp(name = "enableAntialiasing")
    public void setEnableAntialiasing(PdfView pdfView, boolean enableAntialiasing) {
        pdfView.setEnableAntialiasing(enableAntialiasing);
    }

    @ReactProp(name = "enableAnnotationRendering")
    public void setEnableAnnotationRendering(PdfView pdfView, boolean enableAnnotationRendering) {
        pdfView.setEnableAnnotationRendering(enableAnnotationRendering);
    }

    @ReactProp(name = "enableDoubleTapZoom")
    public void setEnableDoubleTapZoom(PdfView pdfView, boolean enableDoubleTap) {
        pdfView.setEnableDoubleTapZoom(enableDoubleTap);
    }

    @ReactProp(name = "enablePaging")
    public void setEnablePaging(PdfView pdfView, boolean enablePaging) {
        pdfView.setEnablePaging(enablePaging);
    }

    @Override
    public void setEnableRTL(PdfView view, boolean value) {
        // NOOP on Android
    }

    @ReactProp(name = "fitPolicy")
    public void setFitPolicy(PdfView pdfView, int fitPolicy) {
        pdfView.setFitPolicy(fitPolicy);
    }

    @ReactProp(name = "singlePage")
    public void setSinglePage(PdfView pdfView, boolean singlePage) {
        pdfView.setSinglePage(singlePage);
    }

    // It seems funny, but this method is called through delegate on Paper, but on Fabric we need to
    // use `receiveCommand` method and call this one there
    @Override
    public void setNativePage(PdfView view, int page) {
        pdfView.setPage(page);
    }

    @Override
    public void receiveCommand(@NonNull PdfView root, String commandId, @androidx.annotation.Nullable ReadableArray args) {
        Assertions.assertNotNull(root);
        if ("setNativePage".equals(commandId)) {
            Assertions.assertNotNull(args);
            assert args != null;
            setNativePage(root, args.getInt(0));
        }
    }

    @Override
    public void onAfterUpdateTransaction(PdfView pdfView) {
        super.onAfterUpdateTransaction(pdfView);
        pdfView.drawPdf();
    }

}
