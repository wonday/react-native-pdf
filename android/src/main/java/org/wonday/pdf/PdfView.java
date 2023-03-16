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
 import android.view.View;
 import android.view.ViewGroup;
 import android.util.Log;
 import android.graphics.PointF;
 import android.net.Uri;
 import android.util.AttributeSet;
 import android.view.MotionEvent;
 import android.graphics.Canvas;
 import javax.annotation.Nullable;
 
 
 import com.github.barteksc.pdfviewer.PDFView;
 import com.github.barteksc.pdfviewer.listener.OnActionEnd;
 import com.github.barteksc.pdfviewer.listener.OnPageChangeListener;
 import com.github.barteksc.pdfviewer.listener.OnLoadCompleteListener;
 import com.github.barteksc.pdfviewer.listener.OnErrorListener;
 import com.github.barteksc.pdfviewer.listener.OnPageSwipeChangeListener;
 import com.github.barteksc.pdfviewer.listener.OnRenderListener;
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
 import com.facebook.react.uimanager.ThemedReactContext;
 import com.facebook.react.uimanager.annotations.ReactProp;
 import com.facebook.react.uimanager.events.RCTEventEmitter;
 import com.facebook.react.common.MapBuilder;
 import com.facebook.react.modules.core.DeviceEventManagerModule;
 import com.facebook.common.logging.FLog;
 import com.facebook.react.common.ReactConstants;
 
 import static java.lang.String.format;
 
 import java.io.FileNotFoundException;
 import java.io.InputStream;
 import java.lang.ClassCastException;
 import java.util.ArrayList;
 import java.util.List;
 
 import com.github.barteksc.pdfviewer.util.Hotspot;
 import com.github.barteksc.pdfviewer.util.Note;
 import com.github.barteksc.pdfviewer.util.TextLine;
 import com.github.barteksc.pdfviewer.util.TextNote;
 import com.google.gson.JsonArray;
 import com.google.gson.JsonElement;
 import com.google.gson.JsonObject;
 import com.shockwave.pdfium.PdfDocument;
 import com.google.gson.Gson;
 import com.google.gson.GsonBuilder;
 import com.shockwave.pdfium.util.SizeF;
 
 public class PdfView extends PDFView implements OnPageChangeListener,OnLoadCompleteListener,OnErrorListener,OnTapListener,OnDrawListener,OnPageScrollListener, LinkHandler, OnPageSwipeChangeListener, OnActionEnd {
     private ThemedReactContext context;
     private int page = 1;               // start from 1
     private boolean horizontal = false;
     private float scale = 1;
     private float minScale = 1;
     private float maxScale = 3;
     private String asset;
     private String path;
     private String hotspotsString;
     private String notesString;
     private String textNotesString;
     private boolean alreadyDraw;
     private boolean scaleChange;
     private int spacing = 10;
     private String password = "";
     private boolean enableAntialiasing = true;
     private boolean enableAnnotationRendering = true;
 
     private boolean enablePaging = false;
     private boolean autoSpacing = false;
     private boolean pageFling = false;
     private boolean pageSnap = false;
     private FitPolicy fitPolicy = FitPolicy.WIDTH;
     private boolean singlePage = false;
 
     private static PdfView instance = null;
 
     private float originalWidth = 0;
     private float lastPageWidth = 0;
     private float lastPageHeight = 0;
 
     private boolean isDestroyed = false;
 
     public PdfView(ThemedReactContext context, AttributeSet set){
         super(context,set);
         //Constants.PART_SIZE=325;
         this.context = context;
         this.instance = this;
         this.alreadyDraw = false;
         this.scaleChange = false;
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
         WritableMap event = Arguments.createMap();
         event.putString("message", "pageScrolled|"+(this.getCurrentXOffset())+"|"+(this.getCurrentYOffset())+"|"+(positionOffset));
 
         ReactContext reactContext = (ReactContext)this.getContext();
         reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                 this.getId(),
                 "topChange",
                 event
         );
         Constants.Pinch.MINIMUM_ZOOM = this.minScale;
         Constants.Pinch.MAXIMUM_ZOOM = this.maxScale;
 
     }
 
     @Override
     public void onPageScrolledEnd() {
         SizeF pageSize = getPageSize(0);
         float width = pageSize.getWidth();
         float height = pageSize.getHeight();
 
         WritableMap event = Arguments.createMap();
         event.putString("message", "pageScrolledEnd|"+(this.getCurrentXOffset())+"|"+(this.getCurrentYOffset())+"|"+width+"|"+height);
 
         ReactContext reactContext = (ReactContext)this.getContext();
         reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                 this.getId(),
                 "topChange",
                 event
         );
     }
 
     @Override
     public boolean onTap(MotionEvent e){
         WritableMap event = Arguments.createMap();
         event.putString("message", "pageSingleTap|"+page+"|"+e.getRawX()+"|"+e.getRawY()+"|"+getResources().getDisplayMetrics().widthPixels+"|"+getResources().getDisplayMetrics().heightPixels);
 
 
         ReactContext reactContext = (ReactContext)this.getContext();
         reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                 this.getId(),
                 "topChange",
                 event
         );
         return true;
 
     }
 
     @Override
     public void onLayerDrawn(Canvas canvas, float pageWidth, float pageHeight, int displayedPage){
         if (originalWidth == 0) {
             originalWidth = pageWidth;
         }
 
         if (lastPageWidth>0 && lastPageHeight>0 && (pageWidth!=lastPageWidth || pageHeight!=lastPageHeight)) {
             Constants.Pinch.MINIMUM_ZOOM = this.minScale;
             Constants.Pinch.MAXIMUM_ZOOM = this.maxScale;
 
             WritableMap event = Arguments.createMap();
             event.putString("message", "scaleChanged|"+getZoomScale()+"|"+(this.getCurrentXOffset())+"|"+(this.getCurrentYOffset())+"|"+(this.getPositionOffset()));
 
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
 
 
     @Override
     protected void onDetachedFromWindow() {
         super.onDetachedFromWindow();
         this.isDestroyed = true;
     }
 
 
     protected List<Note> constructNotes() {
         List<Note> notes = new ArrayList<>();
         if(!this.notesString.isEmpty()) {
             JsonArray array = stringToArray(this.notesString);
             for(JsonElement element : array) {
                 JsonObject object = element.getAsJsonObject();
                 Note note = new Note(Double.valueOf(object.get("xPos").getAsString()).doubleValue(), Double.valueOf(object.get("yPos").getAsString()).doubleValue(), object.get("color").getAsString());
                 notes.add(note);
             }
         }
         return notes;
     }
 
 
     protected List<Hotspot> constructHotspots() {
         List<Hotspot> hotspots = new ArrayList<>();
         if(!this.hotspotsString.isEmpty()) {
             JsonArray array = stringToArray(this.hotspotsString);
             for(JsonElement element : array) {
                 JsonObject object = element.getAsJsonObject();
                 Hotspot hotspot = new Hotspot(Double.valueOf(object.get("xPos").getAsString()).doubleValue(), Double.valueOf(object.get("yPos").getAsString()).doubleValue(), object.get("type").getAsString());
                 hotspots.add(hotspot);
             }
         }
         return hotspots;
     }
 
 
     protected List<TextNote> constructTextNotes() {
         List<TextNote> textNotes = new ArrayList<>();
         if(!this.textNotesString.isEmpty()) {
 
             JsonArray array = stringToArray(this.textNotesString);
             for(JsonElement element : array) {
                 JsonObject object = element.getAsJsonObject();
                 List<TextLine> lines = new ArrayList<>();
                 for(JsonElement lineElement : object.getAsJsonArray("lines")) {
                     JsonObject objectLine = lineElement.getAsJsonObject();
                     lines.add(new TextLine(
                             Double.valueOf(objectLine.get("fontSize").getAsString()).doubleValue(),
                             objectLine.get("fontColor").getAsString(),
                             Double.valueOf(objectLine.get("fontOpacity").getAsString()).floatValue(),
                             objectLine.get("text").getAsString()));
                 }
                 TextNote note = new TextNote(
                         Double.valueOf(object.get("xPos").getAsString()).doubleValue(),
                         Double.valueOf(object.get("yPos").getAsString()).doubleValue(),
                         Double.valueOf(object.get("width").getAsString()).doubleValue(),
                         Double.valueOf(object.get("height").getAsString()).doubleValue(),
                         object.get("backgroundColor").getAsString(),
                         Double.valueOf(object.get("backgroundOpacity").getAsString()).floatValue(),
                         object.get("borderColor").getAsString(),
                         object.get("borderSize").getAsInt(),
                         Double.valueOf(object.get("borderOpacity").getAsString()).floatValue(),
                         lines);
                 textNotes.add(note);
             }
         }
         return textNotes;
     }
 
 
     public void drawPdf() {
         if(this.alreadyDraw) {
             if(this.scaleChange) {
                 this.zoomWithAnimation(this.scale);
                 this.scaleChange = false;
             }
             else {
                 List<Note> notes = constructNotes();
                 this.setNotes(notes);
                 List<TextNote> textNotes = constructTextNotes();
                 this.setTextNotes(textNotes);
                 List<Hotspot> hotspots = constructHotspots();
                 this.setHotspots(hotspots);
                 this.redraw();
                 this.moveEnds();
             }
         }
         else {
             if (this.path != null && !isDestroyed){
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
 
                 List<Hotspot> hotspots = constructHotspots();
                 List<Note> notes = constructNotes();
                 List<TextNote> textNotes = constructTextNotes();
 
                 configurator.defaultPage(this.page-1)
                         .swipeHorizontal(this.horizontal)
                         .withHotspots(hotspots)
                         .withNotes(notes)
                         .withTextNotes(textNotes)
                         .onActionEnd(this)
                         .onPageChange(this)
                         .onLoad(this)
                         .onError(this)
                         .onDraw(this)
                         .onPageScroll(this)
                         .onPageSwipeChange(this)
                         .spacing(this.spacing)
                         .password(this.password)
                         .enableAntialiasing(this.enableAntialiasing)
                         .pageFitPolicy(this.fitPolicy)
                         .pageSnap(this.pageSnap)
                         .autoSpacing(this.autoSpacing)
                         .pageFling(this.pageFling)
                         .enableSwipe(!this.singlePage)
                         .enableDoubletap(!this.singlePage)
                         .enableAnnotationRendering(this.enableAnnotationRendering)
                         .linkHandler(this);
 
                 if (this.singlePage) {
                     configurator.pages(this.page-1);
                     setTouchesEnabled(false);
                 } else {
                     configurator.onTap(this);
                 }
 
                 if(!isDestroyed) {
                     configurator.load();
                 }
 
                 this.alreadyDraw = true;
             }
         }
     }
 
     public static JsonArray stringToArray(String string) {
         Gson gson = new GsonBuilder()
                 .setDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ")
                 .setPrettyPrinting()
                 .disableHtmlEscaping()
                 .create();
         return gson.fromJson(string, JsonArray.class);
     }
 
     public void setPath(String path) {
         this.path = path;
     }
 
     public void setHotspotsString(String hotspotsString) {
         this.hotspotsString = hotspotsString;
     }
     public void setNotesString(String notesString) {
         if(!notesString.equals(this.notesString )) {
             this.notesString = notesString;
         }
     }
 
     public void setTextNotesString(String textNotesString) {
         if(!textNotesString.equals(this.textNotesString )) {
             this.textNotesString = textNotesString;
         }
     }
 
     public void setUpdate() {
         this.moveEnds();
     }
 
 
     // page start from 1
     public void setPage(int page) {
         this.page = page>1?page:1;
     }
 
     public void setScale(float scale) {
         if(this.alreadyDraw) {
             this.scaleChange = true;
         }
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
 
 
     public void handleLinkEvent(LinkTapEvent event) {
         String uri = event.getLink().getUri();
         Integer page = event.getLink().getDestPageIdx();
         if (uri != null && !uri.isEmpty()) {
             handleUri(uri);
         } else if (page != null) {
             handlePage(page);
         }
     }
 
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
 
     private void handlePage(int page) {
         this.jumpTo(page);
     }
 
     private void showLog(final String str) {
         //Log.d("PdfView", str);
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
 
     @Override
     public void onPageSwipeChange(int offset) {
         WritableMap event = Arguments.createMap();
         if(Math.abs(offset) > 300*getResources().getDisplayMetrics().density) {
             if(offset > 0) {
                 event.putString("message", "prevPage|");
             }
             else {
                 event.putString("message", "nextPage|");
             }
             ReactContext reactContext = (ReactContext)this.getContext();
             reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                     this.getId(),
                     "topChange",
                     event
             );
         }
     }
 
     @Override
     public void actionEnd() {
         SizeF pageSize = getPageSize(0);
         float width = pageSize.getWidth();
         float height = pageSize.getHeight();
 
         WritableMap event = Arguments.createMap();
         event.putString("message", "actionEnd|"+getZoomScale()+"|"+(this.getCurrentXOffset())+"|"+(this.getCurrentYOffset())+"|"+(this.getPositionOffset())+"|"+width+"|"+height);
         ReactContext reactContext = (ReactContext)this.getContext();
         reactContext.getJSModule(RCTEventEmitter.class).receiveEvent(
                 this.getId(),
                 "topChange",
                 event
         );
     }
 }
 