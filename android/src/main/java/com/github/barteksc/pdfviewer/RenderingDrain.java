package com.github.barteksc.pdfviewer;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

// Lives in AndroidPdfViewer's package to reach PDFView.renderingHandler, which is package-private.
public final class RenderingDrain {
    private static final long TIMEOUT_MS = 1000;

    private RenderingDrain() {}

    // Stops the renderer and waits for the page it is drawing, so PDFView.recycle() can't close the document mid-render.
    public static void drain(PDFView view) {
        RenderingHandler renderingHandler = view.renderingHandler;
        if (renderingHandler == null) {
            return;
        }
        renderingHandler.stop();
        renderingHandler.removeMessages(RenderingHandler.MSG_RENDER_TASK);
        CountDownLatch idle = new CountDownLatch(1);
        if (!renderingHandler.postAtFrontOfQueue(idle::countDown)) {
            return;
        }
        try {
            idle.await(TIMEOUT_MS, TimeUnit.MILLISECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
