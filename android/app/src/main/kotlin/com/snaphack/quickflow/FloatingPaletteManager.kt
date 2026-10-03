package com.snaphack.quickflow

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.text.Editable
import android.text.TextWatcher
import android.view.*
import android.widget.*
import kotlin.math.abs

class FloatingPaletteManager(private val service: QuickFlowAccessibilityService) {

    private val windowManager: WindowManager =
        service.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val vibrator: Vibrator? =
        service.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    private val repository = PhraseRepository(service)

    private var bubbleView: View? = null
    private var paletteView: View? = null

    private lateinit var bubbleParams: WindowManager.LayoutParams
    private lateinit var paletteParams: WindowManager.LayoutParams

    private var isBubbleShowing = false
    private var isPaletteShowing = false

    private var selectedCategoryId = "all"
    private var searchQuery = ""

    private val overlayWindowType: Int
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

    init {
        setupLayoutParams()
    }

    private fun setupLayoutParams() {
        // Floating Bubble Window Params (Touch events only, never blocks screen)
        bubbleParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayWindowType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 20
            y = 400
        }

        // Floating Palette Window Params
        paletteParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayWindowType,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 40
            y = 350
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    fun showBubble() {
        if (isBubbleShowing) return

        val inflater = LayoutInflater.from(service)
        bubbleView = inflater.inflate(R.layout.floating_bubble_layout, null)

        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isClick = true

        bubbleView?.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = bubbleParams.x
                    initialY = bubbleParams.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isClick = true
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = (event.rawX - initialTouchX).toInt()
                    val dy = (event.rawY - initialTouchY).toInt()

                    if (abs(dx) > 10 || abs(dy) > 10) {
                        isClick = false
                    }

                    bubbleParams.x = initialX + dx
                    bubbleParams.y = initialY + dy
                    try {
                        windowManager.updateViewLayout(bubbleView, bubbleParams)
                    } catch (_: Exception) {}
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (isClick) {
                        togglePalette()
                    } else {
                        // Snap bubble to nearest screen edge (left or right)
                        snapBubbleToEdge()
                    }
                    true
                }
                else -> false
            }
        }

        try {
            windowManager.addView(bubbleView, bubbleParams)
            isBubbleShowing = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun snapBubbleToEdge() {
        val displayMetrics = service.resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val bubbleWidth = bubbleView?.width ?: 150

        bubbleParams.x = if (bubbleParams.x + bubbleWidth / 2 < screenWidth / 2) {
            20 // Left edge
        } else {
            screenWidth - bubbleWidth - 20 // Right edge
        }

        try {
            windowManager.updateViewLayout(bubbleView, bubbleParams)
        } catch (_: Exception) {}
    }

    fun hideBubble() {
        hidePalette()
        if (isBubbleShowing && bubbleView != null) {
            try {
                windowManager.removeView(bubbleView)
            } catch (_: Exception) {}
            isBubbleShowing = false
            bubbleView = null
        }
    }

    fun togglePalette() {
        if (isPaletteShowing) {
            hidePalette()
        } else {
            showPalette()
        }
    }

    fun isShowing(): Boolean = isBubbleShowing

    private fun showPalette() {
        if (isPaletteShowing) return

        val inflater = LayoutInflater.from(service)
        paletteView = inflater.inflate(R.layout.floating_palette_layout, null)

        // Position palette adjacent to the bubble
        val displayMetrics = service.resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels

        paletteParams.y = (bubbleParams.y - 100).coerceAtLeast(100)
        paletteParams.x = if (bubbleParams.x < screenWidth / 2) {
            bubbleParams.x + 120
        } else {
            (bubbleParams.x - 680).coerceAtLeast(20)
        }

        setupPaletteViews(paletteView!!)

        paletteView?.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_OUTSIDE) {
                hidePalette()
                true
            } else {
                false
            }
        }

        try {
            windowManager.addView(paletteView, paletteParams)
            isPaletteShowing = true
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun hidePalette() {
        if (isPaletteShowing && paletteView != null) {
            try {
                windowManager.removeView(paletteView)
            } catch (_: Exception) {}
            isPaletteShowing = false
            paletteView = null
        }
    }

    private fun setupPaletteViews(view: View) {
        val currentPackage = service.currentPackageName ?: "chat"
        val activeAppLabel = getFriendlyAppName(currentPackage)

        val tvActiveApp = view.findViewById<TextView>(R.id.tv_active_app)
        tvActiveApp.text = activeAppLabel

        val btnClose = view.findViewById<TextView>(R.id.btn_close_palette)
        btnClose.setOnClickListener { hidePalette() }

        val etSearch = view.findViewById<EditText>(R.id.et_search)
        etSearch.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                searchQuery = s?.toString()?.trim() ?: ""
                populatePhrases(view)
            }
            override fun afterTextChanged(s: Editable?) {}
        })

        val etCustom = view.findViewById<EditText>(R.id.et_custom_inject)
        val btnInjectCustom = view.findViewById<Button>(R.id.btn_inject_custom)
        btnInjectCustom.setOnClickListener {
            val text = etCustom.text.toString().trim()
            if (text.isNotEmpty()) {
                injectAndFinish(text, "custom", "custom_${System.currentTimeMillis()}")
            }
        }

        populateCategories(view)
        populatePhrases(view)
    }

    private fun populateCategories(view: View) {
        val layoutCategories = view.findViewById<LinearLayout>(R.id.layout_categories)
        layoutCategories.removeAllViews()

        val currentPackage = service.currentPackageName ?: ""
        val categories = repository.getCategories()
        val allPhrases = repository.getPhrases()

        // "All" chip
        val allChip = createCategoryChip("all", "All (${allPhrases.size})", selectedCategoryId == "all", false) {
            selectedCategoryId = "all"
            populateCategories(view)
            populatePhrases(view)
        }
        layoutCategories.addView(allChip)

        for (cat in categories) {
            // Check Smart Conversation Memory: Has this category already been used in this chat?
            val isUsedInChat = cat.isSmartFilterEnabled && SmartChatMemory.isCategoryUsed(currentPackage, cat.id)

            val label = if (isUsedInChat) {
                "${cat.icon} ${cat.name} ✓"
            } else {
                "${cat.icon} ${cat.name}"
            }

            val isSelected = selectedCategoryId == cat.id
            val chip = createCategoryChip(cat.id, label, isSelected, isUsedInChat) {
                selectedCategoryId = cat.id
                populateCategories(view)
                populatePhrases(view)
            }
            layoutCategories.addView(chip)
        }
    }

    private fun createCategoryChip(
        id: String,
        label: String,
        isSelected: Boolean,
        isDimmed: Boolean,
        onClick: () -> Unit
    ): View {
        val chip = TextView(service).apply {
            text = label
            textSize = 12f
            setPadding(28, 14, 28, 14)
            gravity = Gravity.CENTER
            setBackgroundResource(
                if (isSelected) R.drawable.chip_selected_bg else R.drawable.chip_unselected_bg
            )
            setTextColor(
                if (isDimmed) Color.parseColor("#71717A")
                else if (isSelected) Color.WHITE
                else Color.parseColor("#D4D4D8")
            )
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                marginEnd = 16
            }
            layoutParams = params
            setOnClickListener { onClick() }
        }
        return chip
    }

    private fun populatePhrases(view: View) {
        val layoutPhrases = view.findViewById<LinearLayout>(R.id.layout_phrases)
        layoutPhrases.removeAllViews()

        val currentPackage = service.currentPackageName ?: ""
        val allPhrases = repository.getPhrases()

        val filtered = allPhrases.filter { p ->
            val matchesCategory = selectedCategoryId == "all" || p.categoryId == selectedCategoryId
            val matchesSearch = searchQuery.isEmpty() ||
                    p.text.contains(searchQuery, ignoreCase = true) ||
                    p.tags.any { it.contains(searchQuery, ignoreCase = true) }
            matchesCategory && matchesSearch
        }

        if (filtered.isEmpty()) {
            val emptyTv = TextView(service).apply {
                text = if (searchQuery.isNotEmpty()) "No matching phrases" else "No phrases in this category"
                textSize = 13f
                setTextColor(Color.parseColor("#71717A"))
                gravity = Gravity.CENTER
                setPadding(0, 40, 0, 40)
            }
            layoutPhrases.addView(emptyTv)
            return
        }

        for (phrase in filtered) {
            val item = LayoutInflater.from(service).inflate(R.layout.item_bubble_phrase, layoutPhrases, false)
            val tvText = item.findViewById<TextView>(R.id.tv_phrase_text)
            tvText.text = phrase.text

            val isUsed = SmartChatMemory.isPhraseUsed(currentPackage, phrase.id)
            if (isUsed) {
                tvText.setTextColor(Color.parseColor("#71717A"))
            }

            item.setOnClickListener {
                injectAndFinish(phrase.text, phrase.categoryId, phrase.id)
            }

            layoutPhrases.addView(item)
        }
    }

    private fun injectAndFinish(text: String, categoryId: String, phraseId: String) {
        // Trigger subtle haptic click
        vibrateSubtle()

        val currentPackage = service.currentPackageName ?: "unknown"

        // Inject into focused chat input box!
        service.injectText(text)

        // Record in SmartChatMemory so it knows this category/phrase was used in this chat
        SmartChatMemory.recordUsed(currentPackage, categoryId, phraseId)

        // Read user setting: auto-close or keep open
        val settings = repository.getBubbleSettings()
        val autoClose = settings.optBoolean("autoCloseOnTap", true)
        if (autoClose) {
            hidePalette()
        }
    }

    private fun vibrateSubtle() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator?.vibrate(VibrationEffect.createOneShot(35, VibrationEffect.DEFAULT_AMPLITUDE))
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(35)
            }
        } catch (_: Exception) {}
    }

    private fun getFriendlyAppName(packageName: String): String {
        return when {
            packageName.contains("whatsapp") -> "WhatsApp"
            packageName.contains("instagram") -> "Instagram"
            packageName.contains("telegram") -> "Telegram"
            packageName.contains("orca") || packageName.contains("messenger") -> "Messenger"
            packageName.contains("twitter") || packageName.contains("x.android") -> "X (Twitter)"
            packageName.contains("tinder") -> "Tinder"
            packageName.contains("bumble") -> "Bumble"
            packageName.contains("hinge") -> "Hinge"
            packageName.contains("snapchat") -> "Snapchat"
            packageName.contains("mms") || packageName.contains("messaging") -> "Messages"
            else -> "Active App"
        }
    }
}
