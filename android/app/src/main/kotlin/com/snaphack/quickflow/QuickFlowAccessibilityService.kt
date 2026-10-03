package com.snaphack.quickflow

import android.accessibilityservice.AccessibilityService
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast

class QuickFlowAccessibilityService : AccessibilityService() {

    companion object {
        var instance: QuickFlowAccessibilityService? = null
            private set

        fun isRunning(): Boolean = instance != null
    }

    var currentPackageName: String? = null
        private set

    private var floatingPaletteManager: FloatingPaletteManager? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        floatingPaletteManager = FloatingPaletteManager(this)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.packageName != null) {
            val pkg = event.packageName.toString()
            // Ignore system UI and keyboard packages
            if (!pkg.contains("inputmethod") && !pkg.contains("systemui") && !pkg.contains("launcher")) {
                currentPackageName = pkg
            }
        }
    }

    override fun onInterrupt() {
        // Handle accessibility interrupt
    }

    override fun onDestroy() {
        floatingPaletteManager?.hideBubble()
        floatingPaletteManager = null
        instance = null
        super.onDestroy()
    }

    fun startBubble() {
        floatingPaletteManager?.showBubble()
    }

    fun stopBubble() {
        floatingPaletteManager?.hideBubble()
    }

    fun isBubbleShowing(): Boolean {
        return floatingPaletteManager?.isShowing() ?: false
    }

    /**
     * Injects the given text directly into the currently active/focused input box.
     * Tries ACTION_SET_TEXT first; falls back to ACTION_PASTE via clipboard if the app requires it.
     */
    fun injectText(text: String): Boolean {
        val rootNode = rootInActiveWindow ?: return fallbackClipboard(text)

        val focusedNode = findFocusedEditableNode(rootNode)
        if (focusedNode != null) {
            // First attempt: direct text replacement
            val arguments = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
            }
            val setResult = focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)

            if (!setResult) {
                // Second attempt: paste via clipboard
                copyToClipboard(text)
                val pasteResult = focusedNode.performAction(AccessibilityNodeInfo.ACTION_PASTE)
                if (!pasteResult) {
                    fallbackClipboard(text)
                }
            }
            return true
        } else {
            return fallbackClipboard(text)
        }
    }

    private fun findFocusedEditableNode(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        if (node == null) return null

        if (node.isFocused && (node.isEditable || node.className?.contains("EditText") == true)) {
            return node
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val found = findFocusedEditableNode(child)
            if (found != null) return found
        }
        return null
    }

    private fun fallbackClipboard(text: String): Boolean {
        copyToClipboard(text)
        Toast.makeText(this, "Copied: \"$text\"", Toast.LENGTH_SHORT).show()
        return false
    }

    private fun copyToClipboard(text: String) {
        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val clip = ClipData.newPlainText("QuickFlow Phrase", text)
        clipboard.setPrimaryClip(clip)
    }
}
