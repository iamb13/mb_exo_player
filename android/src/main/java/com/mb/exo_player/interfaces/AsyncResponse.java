package com.mb.exo_player.interfaces;

import android.graphics.Bitmap;

import java.util.Map;

public interface AsyncResponse { 
    void processFinish(Map<String, Bitmap> bitmapMap);
}