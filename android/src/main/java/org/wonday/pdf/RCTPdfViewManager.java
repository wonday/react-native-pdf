//
//  RCTPdfViewManager
//  
//
//  Created by Wonday on 17/4/21.
//  Copyright (c) wonday.org All rights reserved.
//

package org.wonday.pdf;

import java.io.File;

import android.content.Context;
import android.view.ViewGroup;
import android.util.Log;
import android.graphics.PointF;
import android.net.Uri;

import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.listener.OnPageChangeListener;
import com.github.barteksc.pdfviewer.listener.OnLoadCompleteListener;
import com.github.barteksc.pdfviewer.listener.OnErrorListener;

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


public class RCTPdfViewManager extends SimpleViewManager<PDFView> implements OnPageChangeListener,OnLoadCompleteListener,OnErrorListener {
    private static final String REACT_CLASS = "RCTPdf";
    private Context context;
    private PDFView pdfView;
    int page = 1;               // start from 1
    boolean horizontal = false;
    float scale = 1;
    String asset;
    String path;


    public RCTPdfViewManager(ReactApplicationContext reactContext){
        this.context = reactContext;
    }

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    public PDFView createViewInstance(ThemedReactContext context) {
        pdfView = new PDFView(context, null);
        return pdfView;
    }

    @Override
    public void onPageChanged(int page, int pageCount) {
        // pdf lib page start from 0, convert it to our page (start from 1)
        page = page+1;
        showLog(format("%s %s / %s", path, page, pageCount));

        WritableMap event = Arguments.createMap();
        event.putString("message", "pageChanged|"+page+"|"+pageCount);
        ReactContext reactContext = (ReactContext)pdfView.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            pdfView.getId(),
            "topChange",
            event
         );
    }

    @Override
    public void loadComplete(int pageCount) {
        WritableMap event = Arguments.createMap();
        event.putString("message", "loadComplete|"+pageCount);
        ReactContext reactContext = (ReactContext)pdfView.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            pdfView.getId(),
            "topChange",
            event
         );
    }

    @Override
    public void onError(Throwable t){
        WritableMap event = Arguments.createMap();
        event.putString("message", "error|load pdf failed.");
        ReactContext reactContext = (ReactContext)pdfView.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            pdfView.getId(),
            "topChange",
            event
         );
    }

    private void drawPdf() {
        PointF pivot = new PointF(this.scale, this.scale);

        if (this.path != null){
            File pdfFile = new File(this.path);
            pdfView.fromFile(pdfFile)
                .defaultPage(this.page-1)
                //.showMinimap(false)
                //.enableSwipe(true)
                .swipeHorizontal(this.horizontal)
                .onPageChange(this)
                .onLoad(this)
                .onError(this)
                .load();

            pdfView.zoomCenteredTo(this.scale, pivot);
            showLog(format("drawPdf path:%s %s", this.path, this.page));
        }
    }

    @ReactProp(name = "path")
    public void setPath(PDFView view, String path) {
        this.path = path;
        drawPdf();
    }

    // page start from 1
    @ReactProp(name = "page")
    public void setPage(PDFView view, int page) {
        this.page = page>1?page:1;
        drawPdf();
    }

    @ReactProp(name = "scale")
    public void setScale(PDFView view, float scale) {
        this.scale = scale;
        drawPdf();
    }

    @ReactProp(name = "horizontal")
    public void setHorizontal(PDFView view, boolean horizontal) {
        this.horizontal = horizontal;
        drawPdf();
    }

    private void showLog(final String str) {
        Log.d(REACT_CLASS, str);
    }
}
