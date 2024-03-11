/**
 * Copyright (c) 2017-present, Wonday (@wonday.org)
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

package org.wonday.pdf;

import java.io.File;

import android.content.ContentResolver;
import android.content.Context;
import android.util.SizeF;
import android.view.View;
import android.view.ViewGroup;
import android.util.Log;
import android.net.Uri;
import android.util.AttributeSet;
import android.view.MotionEvent;
import android.graphics.Canvas;


import com.github.barteksc.pdfviewer.PDFView;
import com.github.barteksc.pdfviewer.listener.OnPageChangeListener;
import com.github.barteksc.pdfviewer.listener.OnLoadCompleteListener;
import com.github.barteksc.pdfviewer.listener.OnErrorListener;
import com.github.barteksc.pdfviewer.listener.OnTapListener;
import com.github.barteksc.pdfviewer.listener.OnDrawListener;
import com.github.barteksc.pdfviewer.listener.OnPageScrollListener;
import com.github.barteksc.pdfviewer.util.FitPolicy;
import com.github.barteksc.pdfviewer.util.Constants;
import com.github.barteksc.pdfviewer.link.LinkHandler;
import com.github.barteksc.pdfviewer.model.LinkTapEvent;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.uimanager.events.RCTEventEmitter;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.common.logging.FLog;
import com.facebook.react.common.ReactConstants;

import static java.lang.String.format;

import java.io.FileNotFoundException;
import java.io.InputStream;

import com.google.gson.Gson;

public class PdfView extends PDFView implements OnPageChangeListener,OnLoadCompleteListener,OnErrorListener,OnTapListener,OnDrawListener,OnPageScrollListener, LinkHandler {
    private int page = 1;               // start from 1
    private boolean horizontal = false;
    private float scale = 1;
    private float minScale = 1;
    private float maxScale = 3;
    private String path;
    private int spacing = 10;
    private String password = "";
    private boolean enableAntialiasing = true;
    private boolean enableAnnotationRendering = true;
    private boolean enableDoubleTapZoom = true;

    private boolean enablePaging = false;
    private boolean autoSpacing = false;
    private boolean pageFling = false;
    private boolean pageSnap = false;
    private FitPolicy fitPolicy = FitPolicy.WIDTH;
    private boolean singlePage = false;

    private float originalWidth = 0;
    private float lastPageWidth = 0;
    private float lastPageHeight = 0;

    // used to store the parameters for `super.onSizeChanged`
    private int oldW = 0;
    private int oldH = 0;

    public PdfView(Context context, AttributeSet set){
        super(context, set);
    }

    @Override
    public void onPageChanged(int page, int numberOfPages) {
        // pdf lib page start from 0, convert it to our page (start from 1)
        page = page+1;
        this.page = page;
        showLog(format("%s %s / %s", path, page, numberOfPages));

        WritableMap event = Arguments.createMap();
        event.putString("message", "pageChanged|"+page+"|"+numberOfPages);
        ReactContext reactContext = (ReactContext)this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            this.getId(),
            "topChange",
            event
         );
    }

    // In some cases Yoga (I think) will measure the view only along one axis first, resulting in
    // onSizeChanged being called with either w or h set to zero. This in turn starts the rendering
    // of the pdf under the hood with one dimension being set to zero and the follow-up call to
    // onSizeChanged with the correct dimensions doesn't have any effect on the already started process.
    // The offending class is DecodingAsyncTask, which tries to get width and height of the pdfView
    // in the constructor, and is created as soon as the measurement is complete, which in some cases
    // may be incomplete as described above.
    // By delaying calling super.onSizeChanged until the size in both dimensions is correct we are able
    // to prevent this from happening.
    //
    // I'm not sure whether the second condition is necessary, but without it, it would be impossible
    // to set the dimensions to zero after first measurement.
    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        if ((w > 0 && h > 0) || this.oldW > 0 || this.oldH > 0) {
            super.onSizeChanged(w, h, this.oldW, this.oldH);
            this.oldW = w;
            this.oldH = h;
        }
    }

    @Override
    public void loadComplete(int numberOfPages) {
        SizeF pageSize = getPageSize(0);
        float width = pageSize.getWidth();
        float height = pageSize.getHeight();

        this.zoomTo(this.scale);
        WritableMap event = Arguments.createMap();

        //create a new json Object for the TableOfContents
        Gson gson = new Gson();
        event.putString("message", "loadComplete|"+numberOfPages+"|"+width+"|"+height+"|"+gson.toJson(this.getTableOfContents()));
        ReactContext reactContext = (ReactContext)this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            this.getId(),
            "topChange",
            event
         );

        //Log.e("ReactNative", gson.toJson(this.getTableOfContents()));

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

    @Override
    public void onPageScrolled(int page, float positionOffset){

        // maybe change by other instance, restore zoom setting
        Constants.Pinch.MINIMUM_ZOOM = this.minScale;
        Constants.Pinch.MAXIMUM_ZOOM = this.maxScale;

    }

    @Override
    public boolean onTap(MotionEvent e){

        // maybe change by other instance, restore zoom setting
        //Constants.Pinch.MINIMUM_ZOOM = this.minScale;
        //Constants.Pinch.MAXIMUM_ZOOM = this.maxScale;

        WritableMap event = Arguments.createMap();
        event.putString("message", "pageSingleTap|"+page+"|"+e.getX()+"|"+e.getY());

        ReactContext reactContext = (ReactContext)this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            this.getId(),
            "topChange",
            event
         );

        // process as tap
         return true;

    }

    @Override
    public void onLayerDrawn(Canvas canvas, float pageWidth, float pageHeight, int displayedPage){
        if (originalWidth == 0) {
            originalWidth = pageWidth;
        }
        
        if (lastPageWidth>0 && lastPageHeight>0 && (pageWidth!=lastPageWidth || pageHeight!=lastPageHeight)) {
            // maybe change by other instance, restore zoom setting
            Constants.Pinch.MINIMUM_ZOOM = this.minScale;
            Constants.Pinch.MAXIMUM_ZOOM = this.maxScale;

            WritableMap event = Arguments.createMap();
            event.putString("message", "scaleChanged|"+(pageWidth/originalWidth));

            ReactContext reactContext = (ReactContext)this.getContext();
            reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                this.getId(),
                "topChange",
                event
             );
        }

        lastPageWidth = pageWidth;
        lastPageHeight = pageHeight;
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        if (this.isRecycled())
            this.drawPdf();
    }

    public void drawPdf() {
        showLog(format("drawPdf path:%s %s", this.path, this.page));

        if (this.path != null){

            // set scale
            this.setMinZoom(this.minScale);
            this.setMaxZoom(this.maxScale);
            this.setMidZoom((this.maxScale+this.minScale)/2);
            Constants.Pinch.MINIMUM_ZOOM = this.minScale;
            Constants.Pinch.MAXIMUM_ZOOM = this.maxScale;

            Configurator configurator;

            if (this.path.startsWith("content://")) {
                ContentResolver contentResolver = getContext().getContentResolver();
                InputStream inputStream = null;
                Uri uri = Uri.parse(this.path);
                try {
                    inputStream = contentResolver.openInputStream(uri);
                } catch (FileNotFoundException e) {
                    throw new RuntimeException(e.getMessage());
                }
                configurator = this.fromStream(inputStream);
            } else {
                configurator = this.fromUri(getURI(this.path));
            }

            configurator.defaultPage(this.page-1)
                .swipeHorizontal(this.horizontal)
                .onPageChange(this)
                .onLoad(this)
                .onError(this)
                .onDraw(this)
                .onPageScroll(this)
                .spacing(this.spacing)
                .password(this.password)
                .enableAntialiasing(this.enableAntialiasing)
                .pageFitPolicy(this.fitPolicy)
                .pageSnap(this.pageSnap)
                .autoSpacing(this.autoSpacing)
                .pageFling(this.pageFling)
                .enableSwipe(!this.singlePage)
                .enableDoubletap(!this.singlePage && this.enableDoubleTapZoom)
                .enableAnnotationRendering(this.enableAnnotationRendering)
                .linkHandler(this);

            if (this.singlePage) {
                configurator.pages(this.page-1);
                setTouchesEnabled(false);
            } else {
                configurator.onTap(this);
            }

            configurator.load();
        }
    }

    public void setEnableDoubleTapZoom(boolean enableDoubleTapZoom) {
        this.enableDoubleTapZoom = enableDoubleTapZoom;
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

    public void setMinScale(float minScale) {
        this.minScale = minScale;
    }

    public void setMaxScale(float maxScale) {
        this.maxScale = maxScale;
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

    public void setEnableAnnotationRendering(boolean enableAnnotationRendering) {
        this.enableAnnotationRendering = enableAnnotationRendering;
    }

    public void setEnablePaging(boolean enablePaging) {
        this.enablePaging = enablePaging;
        if (this.enablePaging) {
            this.autoSpacing = true;
            this.pageFling = true;
            this.pageSnap = true;
        } else {
            this.autoSpacing = false;
            this.pageFling = false;
            this.pageSnap = false;
        }
    }

    public void setFitPolicy(int fitPolicy) {
        switch(fitPolicy){
            case 0:
                this.fitPolicy = FitPolicy.WIDTH;
                break;
            case 1:
                this.fitPolicy = FitPolicy.HEIGHT;
                break;
            case 2:
            default:
            {
                this.fitPolicy = FitPolicy.BOTH;
                break;
            }
        }

    }

    public void setSinglePage(boolean singlePage) {
        this.singlePage = singlePage;
    }

    /**
     * @see https://github.com/barteksc/AndroidPdfViewer/blob/master/android-pdf-viewer/src/main/java/com/github/barteksc/pdfviewer/link/DefaultLinkHandler.java
     */
    public void handleLinkEvent(LinkTapEvent event) {
        String uri = event.getLink().getUri();
        Integer page = event.getLink().getDestPageIdx();
        if (uri != null && !uri.isEmpty()) {
            handleUri(uri);
        } else if (page != null) {
            handlePage(page);
        }
    }

    /**
     * @see https://github.com/barteksc/AndroidPdfViewer/blob/master/android-pdf-viewer/src/main/java/com/github/barteksc/pdfviewer/link/DefaultLinkHandler.java
     */
    private void handleUri(String uri) {
        WritableMap event = Arguments.createMap();
        event.putString("message", "linkPressed|"+uri);

        ReactContext reactContext = (ReactContext)this.getContext();
        reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
            this.getId(),
            "topChange",
            event
        );
    }

    /**
     * @see https://github.com/barteksc/AndroidPdfViewer/blob/master/android-pdf-viewer/src/main/java/com/github/barteksc/pdfviewer/link/DefaultLinkHandler.java
     */
    private void handlePage(int page) {
        this.jumpTo(page);
    }

    private void showLog(final String str) {
        Log.d("PdfView", str);
    }

    private Uri getURI(final String uri) {
        Uri parsed = Uri.parse(uri);

        if (parsed.getScheme() == null || parsed.getScheme().isEmpty()) {
          return Uri.fromFile(new File(uri));
        }
        return parsed;
    }

    private void setTouchesEnabled(final boolean enabled) {
        setTouchesEnabled(this, enabled);
    }

    private static void setTouchesEnabled(View v, final boolean enabled) {
        if (enabled) {
            v.setOnTouchListener(null);
        } else {
            v.setOnTouchListener(new View.OnTouchListener() {
                @Override
                public boolean onTouch(View v, MotionEvent event) {
                    return true;
                }
            });
        }

        if (v instanceof ViewGroup) {
            ViewGroup vg = (ViewGroup) v;
            for (int i = 0; i < vg.getChildCount(); i++) {
                View child = vg.getChildAt(i);
                setTouchesEnabled(child, enabled);
            }
        }
    }
}
