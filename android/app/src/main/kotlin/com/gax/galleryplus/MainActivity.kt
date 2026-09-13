package com.gax.galleryplus

import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Must be called before super.onCreate() per AndroidX SplashScreen docs.
        installSplashScreen()
        super.onCreate(savedInstanceState)
    }
}
