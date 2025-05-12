package com.example.skripshot
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Set the theme back to normal before super.onCreate
        setTheme(R.style.NormalTheme)
        super.onCreate(savedInstanceState)
    }
}
