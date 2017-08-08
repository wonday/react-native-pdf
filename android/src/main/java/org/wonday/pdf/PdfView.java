package org.wonday.pdf;

import android.content.Context;
import android.graphics.Canvas;
import android.util.AttributeSet;

import com.github.barteksc.pdfviewer.PDFView;

public class PdfView extends PDFView {

    public PdfView(Context context, AttributeSet set) {
        super(context, set);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        super.onDraw(canvas);

        // on android 4.4.4 should be set to null
        canvas.setDrawFilter(null);
    }
}
