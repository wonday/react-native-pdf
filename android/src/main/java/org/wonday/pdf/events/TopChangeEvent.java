package org.wonday.pdf.events;

import androidx.annotation.Nullable;

import com.facebook.react.bridge.WritableMap;
import com.facebook.react.uimanager.events.Event;

public class TopChangeEvent extends Event<TopChangeEvent> {
    private WritableMap eventData;

    public TopChangeEvent(int surfaceId, int viewTag, WritableMap data) {
        super(surfaceId, viewTag);
        eventData = data;
    }

    @Override
    public String getEventName() {
        return "topChange";
    }

    @Nullable
    @Override
    protected WritableMap getEventData() {
        return eventData;
    }
}
