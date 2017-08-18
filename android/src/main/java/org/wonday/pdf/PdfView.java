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
import android.view.View;
import android.view.ViewGroup;
import android.util.Log;
import android.graphics.PointF;
import android.net.Uri;
import android.util.AttributeSet;

import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.listener.OnPageChangeListener;
import com.github.barteksc.pdfviewer.listener.OnLoadCompleteListener;
import com.github.barteksc.pdfviewer.listener.OnErrorListener;
import com.github.barteksc.pdfviewer.listener.OnRenderListener;

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


public class PdfView extends PDFView implements OnPageChangeListener,OnLoadCompleteListener,OnErrorListener {
    private Context context;
    private int page = 1;               // start from 1
    private boolean horizontal = false;
    private float scale = 1;
    private String asset;
    private String path;
    private int spacing = 10;
    private String password = "";
    private boolean enableAntialiasing = true;
    private boolean fitWidth = false;
    private static PdfView instance = null;


    public PdfView(Context context, AttributeSet set){
        super(context,set);
        this.context = context;
        this.instance = this;
    }

    @Override
    public void onPageChanged(int page, int pageCount) {
        // pdf lib page start from 0, convert it to our page (start from 1)
        page = page+1;
        this.page = page;
        showLog(format("%s %s / %s", path, page, pageCount));

        WritableMap event = Arguments.createMap();
        event.putString("message", "pageChanged|"+page+"|"+pageCount);
        ReactContext reactContext = (ReactContext)this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            this.getId(),
            "topChange",
            event
         );
    }

    @Override
    public void loadComplete(int pageCount) {
        WritableMap event = Arguments.createMap();
        event.putString("message", "loadComplete|"+pageCount);
        ReactContext reactContext = (ReactContext)this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            this.getId(),
            "topChange",
            event
         );
    }

    @Override
    public void onError(Throwable t){
        WritableMap event = Arguments.createMap();
        if (t.getMessage().contains("Password required or incorrect password")) {
            event.putString("message", "error|Password required or incorrect password.");
        } else {
            event.putString("message", "error|"+t.getMessage());
        }

        ReactContext reactContext = (ReactContext)this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            this.getId(),
            "topChange",
            event
         );
    }

    public void drawPdf() {
        showLog(format("drawPdf path:%s %s", this.path, this.page));

        PointF pivot = new PointF(this.scale, this.scale);

        if (this.path != null){
            File pdfFile = new File(this.path);
            this.fromFile(pdfFile)
                .defaultPage(this.page-1)
                //.showMinimap(false)
                //.enableSwipe(true)
                .swipeHorizontal(this.horizontal)
                .onPageChange(this)
                .onLoad(this)
                .onError(this)
                .spacing(this.spacing)
                .password(this.password)
                .enableAntialiasing(this.enableAntialiasing)
                .onRender(new OnRenderListener() {
                                @Override
                                public void onInitiallyRendered(int nbPages, float pageWidth, float pageHeight) {
                                    if (fitWidth) {
                                        instance.fitToWidth(page-1);
                                    }
                                }
                            })
                .load();

            this.zoomCenteredTo(this.scale, pivot);

        }
    }

    public void setPath(String path) {
        this.path = path;
    }

    // page start from 1
    public void setPage(int page) {
        this.page = page>1?page:1;
    }

    public void setScale(float scale) {
        this.scale = scale;
    }

    public void setHorizontal(boolean horizontal) {
        this.horizontal = horizontal;
    }

    public void setSpacing(int spacing) {
        this.spacing = spacing;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setEnableAntialiasing(boolean enableAntialiasing) {
        this.enableAntialiasing = enableAntialiasing;
    }

    public void setFitWidth(boolean fitWidth) {
        this.fitWidth = fitWidth;
    }

    private void showLog(final String str) {
        Log.d("PdfView", str);
    }
}
