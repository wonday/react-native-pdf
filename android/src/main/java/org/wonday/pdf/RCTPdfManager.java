/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

package org.wonday.pdf;

import java.io.File;

import android.content.Context;
import android.view.ViewGroup;
import android.util.Log;
import android.graphics.PointF;
import android.net.Uri;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import static java.lang.String.format;
import java.lang.ClassCastException;

import com.github.barteksc.pdfviewer.util.FitPolicy;

public class RCTPdfManager extends SimpleViewManager<PdfView> {
    private static final String REACT_CLASS = "RCTPdf";
    private Context context;
    private PdfView pdfView;


    public RCTPdfManager(ReactApplicationContext reactContext){
        this.context = reactContext;
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

    @ReactProp(name = "horizontal")
    public void setHorizontal(PdfView pdfView, boolean horizontal) {
        pdfView.setHorizontal(horizontal);
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

    @ReactProp(name = "enablePaging")
    public void setEnablePaging(PdfView pdfView, boolean enablePaging) {
        pdfView.setEnablePaging(enablePaging);
    }

    @ReactProp(name = "fitPolicy")
    public void setFitPolycy(PdfView pdfView, int fitPolicy) {
        pdfView.setFitPolicy(fitPolicy);
    }

    @Override
    public void onAfterUpdateTransaction(PdfView pdfView) {
        super.onAfterUpdateTransaction(pdfView);
        pdfView.drawPdf();
    }

}
