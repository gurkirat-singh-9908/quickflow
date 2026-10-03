package com.snaphack.quickflow

import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton

class MainActivity : AppCompatActivity() {

    private lateinit var viewStatusIndicator: View
    private lateinit var tvStatusTitle: TextView
    private lateinit var tvStatusSubtitle: TextView
    private lateinit var btnToggleBubble: MaterialButton

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        viewStatusIndicator = findViewById(R.id.view_status_indicator)
        tvStatusTitle = findViewById(R.id.tv_status_title)
        tvStatusSubtitle = findViewById(R.id.tv_status_subtitle)
        btnToggleBubble = findViewById(R.id.btn_toggle_bubble)

        btnToggleBubble.setOnClickListener {
            handleToggleBubble()
        }

        updateUi()
    }

    override fun onResume() {
        super.onResume()
        updateUi()
    }

    private fun handleToggleBubble() {
        if (!hasOverlayPermission()) {
            requestOverlayPermission()
            return
        }

        if (FloatingBubbleService.isRunning) {
            FloatingBubbleService.stop(this)
            Toast.makeText(this, "Floating bubble stopped", Toast.LENGTH_SHORT).show()
        } else {
            FloatingBubbleService.start(this)
            Toast.makeText(this, "⚡ Floating bubble is now active over your apps!", Toast.LENGTH_LONG).show()
        }

        // Slight delay to allow service lifecycle transition
        btnToggleBubble.postDelayed({ updateUi() }, 150)
    }

    private fun updateUi() {
        val isRunning = FloatingBubbleService.isRunning
        val hasPermission = hasOverlayPermission()

        if (isRunning) {
            tvStatusTitle.text = "Bubble is Running ⚡"
            tvStatusSubtitle.text = "Floating on screen over your apps"
            btnToggleBubble.text = "Stop Floating Bubble"
            btnToggleBubble.setBackgroundColor(Color.parseColor("#EF4444")) // Red to stop
            setStatusIndicatorColor(Color.parseColor("#10B981")) // Green
        } else {
            tvStatusTitle.text = if (!hasPermission) "Permission Needed" else "Bubble is Stopped"
            tvStatusSubtitle.text = if (!hasPermission) {
                "Tap below to grant 'Display over other apps'"
            } else {
                "Tap below to start the floating bubble"
            }
            btnToggleBubble.text = if (!hasPermission) "Grant Overlay Permission" else "Start Floating Bubble"
            btnToggleBubble.setBackgroundColor(Color.parseColor("#6366F1")) // Indigo
            setStatusIndicatorColor(if (!hasPermission) Color.parseColor("#F59E0B") else Color.parseColor("#6B7280"))
        }
    }

    private fun setStatusIndicatorColor(color: Int) {
        val shape = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(color)
        }
        viewStatusIndicator.background = shape
    }

    private fun hasOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Toast.makeText(this, "Please enable 'Display over other apps' for QuickFlow", Toast.LENGTH_LONG).show()
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivity(intent)
        }
    }
}
