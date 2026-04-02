package com.example.no_to_distraction

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.graphics.Color
import android.graphics.Rect
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.util.concurrent.TimeUnit
import kotlin.math.abs

class ShortVideoAccessibilityService : AccessibilityService() {

    private var isShortVideoDetected: Boolean = false
    private var lastProcessedAtMs: Long = 0L
    private var lastPublishedState: Boolean? = null
    
    // State to persist comment section opening so deep scrolling won't trigger Reel block
    private var isCommentSectionOpen: Boolean = false
    private var lastCommentSectionSeenAtMs: Long = 0L

    private val overlayHandler = Handler(Looper.getMainLooper())
    private var blockOverlayView: View? = null
    private var blockOverlayPackageName: String? = null
    private var blockRemainingTimeView: TextView? = null
    private var activeBlockEndTimeMs: Long = 0L
    private var reelsOverlayView: View? = null
    private var reelsOverlayShownAtMs: Long = 0L
    private var reelsOverlayDeferredHide: Runnable? = null

    private var suppressPackageAfterHomeClick: String? = null
    private var suppressUntilElapsedMs: Long = 0L

    private val overlayCountdownRunnable = object : Runnable {
        override fun run() {
            val remainingView = blockRemainingTimeView
            if (remainingView == null || blockOverlayView == null) {
                return
            }

            val remainingMs = activeBlockEndTimeMs - System.currentTimeMillis()
            remainingView.text = formatRemainingTime(remainingMs)
            overlayHandler.postDelayed(this, 1_000L)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        serviceInfo = serviceInfo.apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_VIEW_SCROLLED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 120
            flags = flags or
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
            // Keep package filter open so Quick Block can work for any selected app.
            packageNames = null
        }
        Log.i(TAG, "ShortVideoAccessibilityService connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) {
            return
        }

        // Rule 1: Quick Block is isolated and must run before everything else.
        if (handleQuickBlockFirst(event)) {
            return
        }

        if (event.eventType !in TARGET_EVENT_TYPES) {
            return
        }

        val packageName = resolvePackageName(event).orEmpty()

        // FOCUS MODE GATE: During focus mode, selected distracting apps are blocked immediately.
        // Reels/shorts are still handled by the regular detection pipeline below.
        if (isFocusModeActive()) {
            if (packageName.isNotEmpty()) {
                val isDistractingApp = isDistractingApp(packageName)

                if (isDistractingApp) {
                    // Block distracting app during focus mode
                    showFocusModeOverlay(isAppBlock = true)
                    performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK)
                    return
                }
            }
        }

        // Step 1: Gatekeeper
        if (packageName.isEmpty() || packageName !in TARGET_REELS_PACKAGES) {
            updateDetectionState(false, "gatekeeper: $packageName")
            return
        }

        // Per-app toggles apply normally, but focus mode always enforces reels/shorts blocking.
        if (!isFocusModeActive() && !isBlockingEnabledForPackage(packageName)) {
            updateDetectionState(false, "toggle disabled: $packageName")
            return
        }

        // Debounce noisy scroll/content updates.
        val nowMs = SystemClock.elapsedRealtime()
        if ((event.eventType == AccessibilityEvent.TYPE_VIEW_SCROLLED ||
                event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) &&
            nowMs - lastProcessedAtMs < EVENT_DEBOUNCE_MS
        ) {
            return
        }
        lastProcessedAtMs = nowMs

        val root = rootInActiveWindow ?: run {
            updateDetectionState(false, "root not available")
            return
        }
        try {
            val screenWidthPx = getScreenWidthPx()
            val screenHeightPx = getScreenHeightPx()

            val detected = if (packageName == FACEBOOK_PACKAGE) {
                isFacebookReel(root)
            } else {
                detectBySpatialHeuristics(
                    root = root,
                    screenWidthPx = screenWidthPx,
                    screenHeightPx = screenHeightPx
                )
            }

            // Step 3 strict reset is naturally enforced by publishing false immediately on no-match.
            updateDetectionState(detected, "spatial engine: $packageName", packageName)
        } catch (t: Throwable) {
            Log.w(TAG, "Detection pipeline failed", t)
        } finally {
            root.recycle()
        }
    }

    private fun isFacebookReel(rootNode: AccessibilityNodeInfo): Boolean {
        data class RailPoint(val x: Int, val y: Int)

        fun hasInstantFastPathSignature(node: AccessibilityNodeInfo): Boolean {
            val text = node.text?.toString().orEmpty().lowercase()
            val desc = node.contentDescription?.toString().orEmpty().lowercase()
            val blob = "$text $desc"

            if (blob.contains("double tap to like") ||
                blob.contains("original audio") ||
                blob.contains("send this to friends") ||
                blob.contains("remix this reel")
            ) {
                return true
            }

            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                try {
                    if (hasInstantFastPathSignature(child)) {
                        return true
                    }
                } finally {
                    child.recycle()
                }
            }

            return false
        }

        fun isInCommentSection(node: AccessibilityNodeInfo): Boolean {
            // Detect if we're in a Facebook comment thread/modal.
            // Comment sections typically have:
            // 1. Input field with "comment" or "reply" text
            // 2. "Most Relevant" or "Newest" sorting indicators
            // 3. Comment thread containers with text-heavy content
            
            fun searchForCommentIndicators(n: AccessibilityNodeInfo): Boolean {
                val text = n.text?.toString().orEmpty().lowercase()
                val desc = n.contentDescription?.toString().orEmpty().lowercase()
                val className = n.className?.toString().orEmpty()
                val blob = "$text $desc"

                // Check for comment input field signatures
                if (className.contains("EditText", ignoreCase = true)) {
                    if (blob.contains("write") && blob.contains("comment")) {
                        return true
                    }
                    if (blob.contains("reply to")) {
                        return true
                    }
                }

                // Check for individual comment signatures which are prevalent during deep scrolling
                if (text == "reply" || desc == "reply" || 
                    blob.contains("view previous replies") || 
                    blob.contains("hide replies") || 
                    blob.contains("view more comments")) {
                    return true
                }

                // Check for comment thread headers
                if (blob.contains("most relevant") ||
                    blob.contains("newest") ||
                    blob.contains("oldest") ||
                    (blob.contains("sort") && blob.contains("comment"))
                ) {
                    return true
                }

                // Recursive search through children
                for (i in 0 until n.childCount) {
                    val child = n.getChild(i) ?: continue
                    try {
                        if (searchForCommentIndicators(child)) {
                            return true
                        }
                    } finally {
                        child.recycle()
                    }
                }

                return false
            }

            return searchForCommentIndicators(node)
        }

        // Instant fast-path for zero-latency detection on strong FB Reel signatures.
        if (hasInstantFastPathSignature(rootNode)) {
            return true
        }

        // State persistent logic for Comment Section
        val currentlyInComment = isInCommentSection(rootNode)
        
        if (currentlyInComment) {
            isCommentSectionOpen = true
            lastCommentSectionSeenAtMs = SystemClock.elapsedRealtime()
            return false
        } else if (isCommentSectionOpen) {
            // We didn't find any comment indicators on this frame.
            // If the user is scrolling rapidly or comments are loading, indicators might briefly disappear.
            // We use a 2000ms debounce to prevent false block triggers.
            if (SystemClock.elapsedRealtime() - lastCommentSectionSeenAtMs < 2000L) {
                return false
            } else {
                // Time expired and no comment nodes found. Safe to assume the bottom sheet is closed.
                isCommentSectionOpen = false
                Log.d(TAG, "isCommentSectionOpen timed out -> reset to false")
            }
        }

        val screenWidthPx = getScreenWidthPx()
        val screenHeightPx = getScreenHeightPx()
        if (screenWidthPx <= 0 || screenHeightPx <= 0) {
            return false
        }

        val fullScreenContainers = ArrayList<AccessibilityNodeInfo>(8)
        val rightColumnCandidates = ArrayList<RailPoint>(24)

        fun isFullScreenContainer(node: AccessibilityNodeInfo): Boolean {
            val className = node.className?.toString().orEmpty()
            val isContainerType =
                className.contains("RecyclerView", ignoreCase = true) ||
                    className.contains("ViewPager2", ignoreCase = true) ||
                    className.contains("ViewPager", ignoreCase = true) ||
                    className.contains("FrameLayout", ignoreCase = true)
            if (!isContainerType) {
                return false
            }

            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            if (bounds.height() <= 0) {
                return false
            }

            return bounds.height().toFloat() / screenHeightPx.toFloat() >= 0.85f
        }

        fun collectFullScreenContainers(node: AccessibilityNodeInfo) {
            if (isFullScreenContainer(node)) {
                fullScreenContainers += AccessibilityNodeInfo.obtain(node)
            }

            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                try {
                    collectFullScreenContainers(child)
                } finally {
                    child.recycle()
                }
            }
        }

        fun collectInteractionPoints(containerNode: AccessibilityNodeInfo) {
            val bounds = Rect()
            containerNode.getBoundsInScreen(bounds)

            val text = containerNode.text?.toString().orEmpty().lowercase()
            val desc = containerNode.contentDescription?.toString().orEmpty().lowercase()
            val className = containerNode.className?.toString().orEmpty()
            val blob = "$text $desc"

            // Reduce false positives on non-reels surfaces (e.g., Search/Notifications)
            // by only accepting interaction nodes that resemble reel action rail semantics.
            val hasReelActionSignal =
                blob.contains("like") ||
                    blob.contains("comment") ||
                    blob.contains("share") ||
                    blob.contains("send") ||
                    blob.contains("audio") ||
                    blob.contains("reel") ||
                    blob.contains("remix")

            // Exclude nodes that are part of a comment (have scrollable comment text, etc.)
            val looksLikeCommentContent =
                className.contains("EditText", ignoreCase = true) ||
                    (blob.contains("reply") && (blob.contains("comment") || blob.contains("reply to"))) ||
                    className.contains("TextView", ignoreCase = true) && 
                        (text.length > 10 && (text.contains(",") || text.contains("."))) // Likely comment text

            val looksInteractive =
                hasReelActionSignal &&
                    !looksLikeCommentContent &&
                    (containerNode.isClickable ||
                        containerNode.isFocusable ||
                        containerNode.isCheckable ||
                        className.contains("ImageButton", ignoreCase = true) ||
                        className.contains("ImageView", ignoreCase = true) ||
                        className.contains("Button", ignoreCase = true))

            val validBounds = !bounds.isEmpty && bounds.width() > 0 && bounds.height() > 0
            val centerX = bounds.centerX()
            val centerY = bounds.centerY()

            if (looksInteractive && validBounds) {
                // Bottom-right interaction rail candidates.
                if (centerX > (screenWidthPx * 0.70f).toInt() && centerY > (screenHeightPx * 0.40f).toInt()) {
                    rightColumnCandidates += RailPoint(centerX, centerY)
                }
            }

            for (i in 0 until containerNode.childCount) {
                val child = containerNode.getChild(i) ?: continue
                try {
                    collectInteractionPoints(child)
                } finally {
                    child.recycle()
                }
            }
        }

        return try {
            // Constraint D prerequisite: must have >=85% full-screen vertical container.
            collectFullScreenContainers(rootNode)
            if (fullScreenContainers.isEmpty()) {
                return false
            }

            for (container in fullScreenContainers) {
                rightColumnCandidates.clear()
                collectInteractionPoints(container)

                if (rightColumnCandidates.size < 3) {
                    continue
                }

                val deduped = ArrayList<RailPoint>(rightColumnCandidates.size)
                rightColumnCandidates
                    .sortedWith(compareBy<RailPoint> { it.x }.thenBy { it.y })
                    .forEach { p ->
                        val exists = deduped.any {
                            abs(it.x - p.x) <= 20 && abs(it.y - p.y) <= 20
                        }
                        if (!exists) {
                            deduped += p
                        }
                    }

                if (deduped.size < 3) {
                    continue
                }

                // Constraint A: all points must be in rigid right-most column.
                if (deduped.any { it.x <= (screenWidthPx * 0.70f).toInt() }) {
                    continue
                }

                // Constraint B: X-axis strict alignment (within +/- 50px).
                val minX = deduped.minOf { it.x }
                val maxX = deduped.maxOf { it.x }
                if (maxX - minX > 100) {
                    continue
                }

                // Constraint C: at least 3 points with clear top-to-bottom Y progression.
                val sortedY = deduped.map { it.y }.sorted()
                var progressiveCount = 1
                for (idx in 1 until sortedY.size) {
                    if (sortedY[idx] - sortedY[idx - 1] >= 45) {
                        progressiveCount++
                    }
                }
                if (progressiveCount >= 3) {
                    return true
                }
            }

            false
        } finally {
            fullScreenContainers.forEach {
                try {
                    it.recycle()
                } catch (_: Throwable) {
                }
            }
        }
    }

    private fun hasFacebookFastReelsSignal(node: AccessibilityNodeInfo): Boolean {
        val text = node.text?.toString().orEmpty().trim().lowercase()
        val desc = node.contentDescription?.toString().orEmpty().trim().lowercase()
        val className = node.className?.toString().orEmpty()

        val isHeaderContext =
            className.contains("TextView", ignoreCase = true) ||
                className.contains("Toolbar", ignoreCase = true) ||
                className.contains("AppBar", ignoreCase = true)

        if (desc.contains("selected, reels tab") ||
            desc.contains("create reel") ||
            (text == "reels" && isHeaderContext) ||
            (desc == "reels" && isHeaderContext)
        ) {
            return true
        }

        for (index in 0 until node.childCount) {
            val child = node.getChild(index) ?: continue
            try {
                if (hasFacebookFastReelsSignal(child)) {
                    return true
                }
            } finally {
                child.recycle()
            }
        }

        return false
    }

    private fun collectFacebookFullScreenContainers(
        node: AccessibilityNodeInfo,
        screenHeightPx: Int,
        out: MutableList<AccessibilityNodeInfo>
    ) {
        val className = node.className?.toString().orEmpty()
        val isContainerClass =
            className.contains("RecyclerView", ignoreCase = true) ||
                className.contains("ViewPager2", ignoreCase = true) ||
                className.contains("ViewPager", ignoreCase = true) ||
                className.contains("FrameLayout", ignoreCase = true)

        if (isContainerClass && occupiesAtLeast80PercentHeight(node, screenHeightPx)) {
            out += AccessibilityNodeInfo.obtain(node)
        }

        for (index in 0 until node.childCount) {
            val child = node.getChild(index) ?: continue
            try {
                collectFacebookFullScreenContainers(child, screenHeightPx, out)
            } finally {
                child.recycle()
            }
        }
    }

    private fun hasFacebookReelsSignaturesInContainer(container: AccessibilityNodeInfo): Boolean {
        val state = FacebookContainerSignatureState()
        collectFacebookContainerSignatures(container, state)
        return state.hasOriginalAudio || state.hasStars || (state.hasLike && state.hasComment)
    }

    private fun collectFacebookContainerSignatures(
        node: AccessibilityNodeInfo,
        state: FacebookContainerSignatureState
    ) {
        val text = node.text?.toString().orEmpty().lowercase()
        val desc = node.contentDescription?.toString().orEmpty().lowercase()
        val blob = "$text $desc"

        if (blob.contains("original audio")) {
            state.hasOriginalAudio = true
        }
        if (blob.contains("stars")) {
            state.hasStars = true
        }
        if (blob.contains("like")) {
            state.hasLike = true
        }
        if (blob.contains("comment")) {
            state.hasComment = true
        }

        if (state.hasOriginalAudio || state.hasStars || (state.hasLike && state.hasComment)) {
            return
        }

        for (index in 0 until node.childCount) {
            val child = node.getChild(index) ?: continue
            try {
                collectFacebookContainerSignatures(child, state)
                if (state.hasOriginalAudio || state.hasStars || (state.hasLike && state.hasComment)) {
                    return
                }
            } finally {
                child.recycle()
            }
        }
    }

    private fun handleQuickBlockFirst(event: AccessibilityEvent): Boolean {
        val nowMs = System.currentTimeMillis()
        val nowElapsedMs = SystemClock.elapsedRealtime()

        if (nowElapsedMs >= suppressUntilElapsedMs) {
            suppressPackageAfterHomeClick = null
            suppressUntilElapsedMs = 0L
        }

        val packageName = resolvePackageName(event).orEmpty()
        val state = QuickBlockStorage.readActive(this, nowMs)

        if (packageName.isNotEmpty() &&
            packageName == suppressPackageAfterHomeClick &&
            nowElapsedMs < suppressUntilElapsedMs
        ) {
            return false
        }

        if (packageName.isNotEmpty() && state.isPackageBlocked(packageName, nowMs)) {
            val endTimeMs = state.packageEndTime(packageName) ?: 0L
            hideReelsBlockOverlay(force = true)
            showBlockOverlay(packageName, endTimeMs)
            return true
        }

        val overlayPackage = blockOverlayPackageName
        if (overlayPackage != null && blockOverlayView != null) {
            if (packageName.isBlank() ||
                isTransientSystemPackage(packageName) ||
                isInternalOverlayPackage(packageName)
            ) {
                return true
            }

            if (packageName == overlayPackage) {
                return true
            }

            // Keep the block screen visible until user explicitly taps Go Home.
            return true
        }

        return false
    }

    private fun resolvePackageName(event: AccessibilityEvent): String? {
        val eventPackage = event.packageName?.toString()
        if (!eventPackage.isNullOrEmpty()) {
            return eventPackage
        }

        val root: AccessibilityNodeInfo = rootInActiveWindow ?: return null
        return try {
            root.packageName?.toString()
        } finally {
            root.recycle()
        }
    }

    private fun updateDetectionState(
        newState: Boolean,
        reason: String,
        detectedPackageName: String? = null
    ) {
        isShortVideoDetected = newState
        if (lastPublishedState != newState) {
            ReelDetectionChannelBridge.publishReelDetected(newState)
            lastPublishedState = newState

            if (newState) {
                applyReelsLockForTwoDays(detectedPackageName)

                try {
                    val prefs = getSharedPreferences("reels_block_prefs", MODE_PRIVATE)
                    val current = prefs.getInt("pending_blocks", 0)
                    prefs.edit().putInt("pending_blocks", current + 1).apply()
                } catch (t: Throwable) {
                    Log.w(TAG, "Failed to increment pending blocks", t)
                }

                if (isFocusModeActive()) {
                    showFocusModeOverlay(isAppBlock = false)
                } else {
                    showReelsBlockOverlay()
                }
                val backSuccess = performGlobalAction(AccessibilityService.GLOBAL_ACTION_BACK)
                Log.d(TAG, "GLOBAL_ACTION_BACK triggered on reel detect: $backSuccess")
            } else {
                // Do not auto-dismiss; user must tap Go Home.
            }

            Log.d(TAG, "Reel detection changed -> $newState ($reason)")
        }
    }

    private fun detectBySpatialHeuristics(
        root: AccessibilityNodeInfo,
        screenWidthPx: Int,
        screenHeightPx: Int
    ): Boolean {
        if (screenWidthPx <= 0 || screenHeightPx <= 0) {
            return false
        }

        val interactionPoints = ArrayList<InteractionPoint>(16)
        val largeScrollableContainers = ArrayList<AccessibilityNodeInfo>(10)
        val signalState = SignalState()

        try {
            collectSpatialSignals(
                node = root,
                interactionPoints = interactionPoints,
                largeScrollableContainers = largeScrollableContainers,
                signalState = signalState,
                screenHeightPx = screenHeightPx
            )

            val uniquePoints = deduplicateInteractionPoints(interactionPoints)

            // Heuristic B (CRITICAL): horizontal action-row means regular feed post.
            if (hasHorizontalInteractionRow(uniquePoints)) {
                return false
            }

            // Heuristic A: must form a right-side vertically stacked interaction signature.
            val stackPassed = passesThreeButtonVerticalStack(uniquePoints, screenWidthPx)
            if (!stackPassed) {
                return false
            }

            // Heuristic C: short-video container must occupy >= 80% screen height.
            val containerPassed =
                hasLargeScrollableContainer(largeScrollableContainers) ||
                    hasLargeParentFrameFromInteractions(uniquePoints, screenHeightPx)

            if (!containerPassed) {
                return false
            }

            // Heuristic D (optional strong confirm): Original audio / Remix markers.
            if (signalState.hasAudioSignature) {
                Log.d(TAG, "Spatial detection confirmed with audio signature")
            }

            return true
        } finally {
            interactionPoints.forEach {
                try {
                    it.node.recycle()
                } catch (_: Throwable) {
                }
            }

            largeScrollableContainers.forEach {
                try {
                    it.recycle()
                } catch (_: Throwable) {
                }
            }
        }
    }

    private fun collectSpatialSignals(
        node: AccessibilityNodeInfo,
        interactionPoints: MutableList<InteractionPoint>,
        largeScrollableContainers: MutableList<AccessibilityNodeInfo>,
        signalState: SignalState,
        screenHeightPx: Int
    ) {
        val text = node.text?.toString().orEmpty().lowercase()
        val desc = node.contentDescription?.toString().orEmpty().lowercase()
        val blob = "$text $desc"

        if (blob.contains("original audio") || blob.contains("remix")) {
            signalState.hasAudioSignature = true
        }

        val isInteractionNode =
            blob.contains("like") ||
                blob.contains("comment") ||
                blob.contains("share") ||
                blob.contains("send")

        if (isInteractionNode) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            if (!bounds.isEmpty && bounds.centerX() > 0 && bounds.centerY() > 0) {
                interactionPoints += InteractionPoint(
                    centerX = bounds.centerX(),
                    centerY = bounds.centerY(),
                    node = AccessibilityNodeInfo.obtain(node)
                )
            }
        }

        if (isScrollableContainer(node) && occupiesAtLeast80PercentHeight(node, screenHeightPx)) {
            largeScrollableContainers += AccessibilityNodeInfo.obtain(node)
        }

        for (index in 0 until node.childCount) {
            val child = node.getChild(index) ?: continue
            try {
                collectSpatialSignals(
                    node = child,
                    interactionPoints = interactionPoints,
                    largeScrollableContainers = largeScrollableContainers,
                    signalState = signalState,
                    screenHeightPx = screenHeightPx
                )
            } finally {
                child.recycle()
            }
        }
    }

    private fun deduplicateInteractionPoints(
        points: List<InteractionPoint>
    ): List<InteractionPoint> {
        if (points.isEmpty()) {
            return emptyList()
        }

        val sorted = points.sortedWith(compareBy<InteractionPoint> { it.centerX }.thenBy { it.centerY })
        val deduped = ArrayList<InteractionPoint>(sorted.size)

        for (candidate in sorted) {
            val hasNearDuplicate = deduped.any {
                abs(it.centerX - candidate.centerX) <= POINT_DEDUP_TOLERANCE_PX &&
                    abs(it.centerY - candidate.centerY) <= POINT_DEDUP_TOLERANCE_PX
            }
            if (!hasNearDuplicate) {
                deduped += candidate
            }
        }

        return deduped
    }

    private fun hasHorizontalInteractionRow(points: List<InteractionPoint>): Boolean {
        if (points.size < 2) {
            return false
        }

        for (i in 0 until points.size) {
            for (j in i + 1 until points.size) {
                if (abs(points[i].centerY - points[j].centerY) < HORIZONTAL_REJECTION_Y_DIFF_PX) {
                    return true
                }
            }
        }

        return false
    }

    private fun passesThreeButtonVerticalStack(
        points: List<InteractionPoint>,
        screenWidthPx: Int
    ): Boolean {
        if (points.size < 3) {
            return false
        }

        val minRightX = (screenWidthPx * RIGHT_SIDE_MIN_RATIO).toInt()
        val rightSide = points
            .filter { it.centerX > minRightX }
            .sortedBy { it.centerY }

        if (rightSide.size < 3) {
            return false
        }

        for (i in 0..rightSide.size - 3) {
            for (j in i + 1 until rightSide.size - 1) {
                for (k in j + 1 until rightSide.size) {
                    val a = rightSide[i]
                    val b = rightSide[j]
                    val c = rightSide[k]

                    val xAligned =
                        abs(a.centerX - b.centerX) <= STACK_X_ALIGNMENT_TOLERANCE_PX &&
                            abs(b.centerX - c.centerX) <= STACK_X_ALIGNMENT_TOLERANCE_PX &&
                            abs(a.centerX - c.centerX) <= STACK_X_ALIGNMENT_TOLERANCE_PX

                    val yDistinct =
                        abs(a.centerY - b.centerY) >= MIN_VERTICAL_STACK_GAP_PX &&
                            abs(b.centerY - c.centerY) >= MIN_VERTICAL_STACK_GAP_PX &&
                            abs(a.centerY - c.centerY) >= MIN_VERTICAL_STACK_GAP_PX

                    if (xAligned && yDistinct) {
                        return true
                    }
                }
            }
        }

        return false
    }

    private fun hasLargeScrollableContainer(
        containers: List<AccessibilityNodeInfo>
    ): Boolean {
        return containers.isNotEmpty()
    }

    private fun hasLargeParentFrameFromInteractions(
        points: List<InteractionPoint>,
        screenHeightPx: Int
    ): Boolean {
        for (point in points) {
            var depth = 0
            var current = point.node.parent
            while (current != null && depth <= MAX_PARENT_DEPTH) {
                try {
                    val className = current.className?.toString().orEmpty()
                    val isCandidateFrame =
                        className.contains("FrameLayout", ignoreCase = true) ||
                            className.contains("RecyclerView", ignoreCase = true) ||
                            className.contains("ViewPager", ignoreCase = true)

                    if (isCandidateFrame && occupiesAtLeast80PercentHeight(current, screenHeightPx)) {
                        return true
                    }

                    val next = current.parent
                    current.recycle()
                    current = next
                    depth++
                } catch (_: Throwable) {
                    try {
                        current.recycle()
                    } catch (_: Throwable) {
                    }
                    current = null
                }
            }
        }

        return false
    }

    private fun isScrollableContainer(node: AccessibilityNodeInfo): Boolean {
        val className = node.className?.toString().orEmpty()
        return node.isScrollable ||
            className.contains("RecyclerView", ignoreCase = true) ||
            className.contains("ViewPager2", ignoreCase = true) ||
            className.contains("ViewPager", ignoreCase = true)
    }

    private fun occupiesAtLeast80PercentHeight(
        node: AccessibilityNodeInfo,
        screenHeightPx: Int
    ): Boolean {
        if (screenHeightPx <= 0) {
            return false
        }

        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        if (bounds.height() <= 0) {
            return false
        }

        return bounds.height().toFloat() / screenHeightPx.toFloat() >= FULL_SCREEN_MIN_RATIO
    }

    override fun onInterrupt() {
        hideBlockOverlay()
        hideReelsBlockOverlay(force = true)
        Log.w(TAG, "Accessibility service interrupted")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        Log.i(TAG, "onUnbind called - allowing rebind")
        return true
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.i(TAG, "onTaskRemoved called - service will continue running")
    }

    override fun onDestroy() {
        hideBlockOverlay()
        hideReelsBlockOverlay(force = true)
        Log.i(TAG, "onDestroy called")
        super.onDestroy()
    }

    private fun showReelsBlockOverlay() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Log.w(TAG, "Cannot show Reels overlay: overlay permission missing")
            return
        }

        if (reelsOverlayView != null) {
            return
        }

        val wm = getSystemService(WINDOW_SERVICE) as WindowManager

        val rootLayout = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#E6000000"))
            isClickable = true
            isFocusable = true
            isFocusableInTouchMode = true
            // Consume taps on the dim background so nothing reaches the underlying app.
            setOnClickListener { }
        }

        val contentLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }

        val titleView = TextView(this).apply {
            text = "Reels Blocked!"
            setTextColor(Color.WHITE)
            textSize = 28f
            gravity = Gravity.CENTER
        }

        val subtitleView = TextView(this).apply {
            text = "Return fresh from launcher to use regular feed."
            setTextColor(Color.parseColor("#CCFFFFFF"))
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, 12, 0, 0)
        }

        val goHomeButton = Button(this).apply {
            text = "Go Home"
            isAllCaps = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = 32
            }
            setOnClickListener {
                performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
                hideReelsBlockOverlay(force = true)
            }
        }

        contentLayout.addView(titleView)
        contentLayout.addView(subtitleView)
        contentLayout.addView(goHomeButton)
        rootLayout.addView(
            contentLayout,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
            PixelFormat.TRANSLUCENT
        )

        try {
            wm.addView(rootLayout, params)
            reelsOverlayView = rootLayout
            reelsOverlayShownAtMs = SystemClock.elapsedRealtime()
            reelsOverlayDeferredHide?.let { overlayHandler.removeCallbacks(it) }
            reelsOverlayDeferredHide = null
            ReelDetectionChannelBridge.publishBlockScreenShown(reason = "reels")
            Log.i(TAG, "Reels block overlay shown")
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to show Reels block overlay", t)
            hideReelsBlockOverlay(force = true)
        }
    }

    private fun hideReelsBlockOverlay(force: Boolean = false) {
        if (!force) {
            return
        }

        val view = reelsOverlayView ?: return

        reelsOverlayDeferredHide?.let { overlayHandler.removeCallbacks(it) }
        reelsOverlayDeferredHide = null

        try {
            val wm = getSystemService(WINDOW_SERVICE) as WindowManager
            wm.removeView(view)
        } catch (_: Throwable) {
        }
        reelsOverlayView = null
        reelsOverlayShownAtMs = 0L
    }

    private fun showFocusModeOverlay(isAppBlock: Boolean = false) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Log.w(TAG, "Cannot show Focus overlay: overlay permission missing")
            return
        }

        if (reelsOverlayView != null) {
            return
        }

        val wm = getSystemService(WINDOW_SERVICE) as WindowManager

        val rootLayout = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#E6000000"))
            isClickable = true
            isFocusable = true
            isFocusableInTouchMode = true
            setOnClickListener { }
        }

        val contentLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }

        // Motivational quote
        val quoteView = TextView(this).apply {
            text = getMotivationalQuote()
            setTextColor(Color.parseColor("#FFD4A5"))
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 24)
        }

        val titleView = TextView(this).apply {
            text = if (isAppBlock) "App Blocked" else "Reels Blocked"
            setTextColor(Color.WHITE)
            textSize = 28f
            gravity = Gravity.CENTER
        }

        val statusView = TextView(this).apply {
            text = "Focus Mode is Running"
            setTextColor(Color.parseColor("#CCFFFFFF"))
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, 12, 0, 0)
        }

        val timerView = TextView(this).apply {
            val minutes = getFocusModeRemainingMinutes()
            text = "Time remaining: $minutes min"
            setTextColor(Color.parseColor("#99FFFFFF"))
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, 8, 0, 0)
        }

        contentLayout.addView(quoteView)
        contentLayout.addView(titleView)
        contentLayout.addView(statusView)
        contentLayout.addView(timerView)

        if (isAppBlock) {
            val lockInfoView = TextView(this).apply {
                text = "This app stays blocked until you tap Go Home."
                setTextColor(Color.parseColor("#FF6B6B"))
                textSize = 14f
                gravity = Gravity.CENTER
                setPadding(0, 16, 0, 0)
            }
            contentLayout.addView(lockInfoView)
        }

        val goHomeButton = Button(this).apply {
            text = "Go Home"
            isAllCaps = false
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = 32
            }
            setOnClickListener {
                performGlobalAction(AccessibilityService.GLOBAL_ACTION_HOME)
                hideReelsBlockOverlay(force = true)
            }
        }

        contentLayout.addView(goHomeButton)
        rootLayout.addView(
            contentLayout,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
            PixelFormat.TRANSLUCENT
        )

        try {
            wm.addView(rootLayout, params)
            reelsOverlayView = rootLayout
            reelsOverlayShownAtMs = SystemClock.elapsedRealtime()
            reelsOverlayDeferredHide?.let { overlayHandler.removeCallbacks(it) }
            reelsOverlayDeferredHide = null
            ReelDetectionChannelBridge.publishBlockScreenShown(
                reason = if (isAppBlock) "focus_app" else "focus_reels"
            )
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to show focus mode overlay", e)
        }
    }

    private fun showBlockOverlay(packageName: String, endTimeMs: Long) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Log.w(TAG, "Cannot show Quick Block overlay: overlay permission missing")
            return
        }

        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        val existingView = blockOverlayView
        if (existingView != null) {
            blockOverlayPackageName = packageName
            activeBlockEndTimeMs = endTimeMs
            blockRemainingTimeView?.text = formatRemainingTime(endTimeMs - System.currentTimeMillis())
            scheduleOverlayCountdown()
            return
        }

        val rootLayout = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#CC000000"))
            isClickable = true
            isFocusable = false
        }

        val contentLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)
        }

        val iconView = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_lock_lock)
            setColorFilter(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(140, 140).apply {
                bottomMargin = 32
            }
        }

        val titleView = TextView(this).apply {
            text = "App Blocked by Quick Block"
            setTextColor(Color.WHITE)
            textSize = 24f
            gravity = Gravity.CENTER
        }

        val subtitleView = TextView(this).apply {
            text = packageName
            setTextColor(Color.parseColor("#B3FFFFFF"))
            textSize = 14f
            gravity = Gravity.CENTER
            setPadding(0, 16, 0, 0)
        }

        val remainingView = TextView(this).apply {
            text = formatRemainingTime(endTimeMs - System.currentTimeMillis())
            setTextColor(Color.parseColor("#E6FFFFFF"))
            textSize = 16f
            gravity = Gravity.CENTER
            setPadding(0, 12, 0, 0)
        }

        val homeButton = Button(this).apply {
            text = "Go to Home"
            isAllCaps = false
            setOnClickListener {
                openPhoneHomeScreen()
            }
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = 40
            }
        }

        contentLayout.addView(iconView)
        contentLayout.addView(titleView)
        contentLayout.addView(subtitleView)
        contentLayout.addView(remainingView)
        contentLayout.addView(homeButton)
        rootLayout.addView(
            contentLayout,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        )

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
            PixelFormat.TRANSLUCENT
        )

        try {
            wm.addView(rootLayout, params)
            blockOverlayView = rootLayout
            blockOverlayPackageName = packageName
            blockRemainingTimeView = remainingView
            activeBlockEndTimeMs = endTimeMs
            scheduleOverlayCountdown()
            ReelDetectionChannelBridge.publishBlockScreenShown(
                reason = "quick_block",
                packageName = packageName,
            )
            Log.i(TAG, "Quick Block overlay shown for $packageName")
        } catch (t: Throwable) {
            Log.w(TAG, "Failed to show Quick Block overlay", t)
            hideBlockOverlay()
        }
    }

    private fun hideBlockOverlay() {
        overlayHandler.removeCallbacks(overlayCountdownRunnable)

        val view = blockOverlayView
        if (view != null) {
            try {
                val wm = getSystemService(WINDOW_SERVICE) as WindowManager
                wm.removeView(view)
            } catch (_: Throwable) {
            }
        }

        blockOverlayView = null
        blockOverlayPackageName = null
        blockRemainingTimeView = null
        activeBlockEndTimeMs = 0L
    }

    private fun scheduleOverlayCountdown() {
        overlayHandler.removeCallbacks(overlayCountdownRunnable)
        overlayHandler.post(overlayCountdownRunnable)
    }

    private fun formatRemainingTime(remainingMsRaw: Long): String {
        val remainingMs = maxOf(0L, remainingMsRaw)
        val totalSeconds = TimeUnit.MILLISECONDS.toSeconds(remainingMs)
        val days = totalSeconds / 86_400
        val hours = (totalSeconds % 86_400) / 3_600
        val minutes = (totalSeconds % 3_600) / 60
        val seconds = totalSeconds % 60
        return "Remaining: ${days}d ${hours}h ${minutes}m ${seconds}s"
    }

    private fun openPhoneHomeScreen() {
        try {
            val blockedPackage = blockOverlayPackageName
            if (!blockedPackage.isNullOrBlank()) {
                suppressPackageAfterHomeClick = blockedPackage
                suppressUntilElapsedMs = SystemClock.elapsedRealtime() + HOME_CLICK_SUPPRESS_MS
            }

            hideBlockOverlay()
            hideReelsBlockOverlay(force = true)

            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(homeIntent)
        } catch (t: Throwable) {
            Log.w(TAG, "Unable to open phone home screen", t)
        }
    }

    private fun isTransientSystemPackage(packageName: String): Boolean {
        return packageName == "com.android.systemui" ||
            packageName.startsWith("com.miui.") ||
            packageName.contains("launcher")
    }

    private fun isInternalOverlayPackage(packageName: String): Boolean {
        val selfPackage = applicationContext.packageName
        return packageName == selfPackage || packageName.startsWith("$selfPackage:")
    }

    private fun getScreenHeightPx(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val wm = getSystemService(WINDOW_SERVICE) as WindowManager
            return wm.currentWindowMetrics.bounds.height()
        }
        return resources.displayMetrics.heightPixels
    }

    private fun getScreenWidthPx(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val wm = getSystemService(WINDOW_SERVICE) as WindowManager
            return wm.currentWindowMetrics.bounds.width()
        }
        return resources.displayMetrics.widthPixels
    }

    private fun isBlockingEnabledForPackage(packageName: String): Boolean {
        if (isReelsLockActiveForPackage(packageName)) {
            return true
        }

        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        return when (packageName) {
            FACEBOOK_PACKAGE -> prefs.getBoolean(PREF_BLOCK_FB_REELS, false)
            INSTAGRAM_PACKAGE -> prefs.getBoolean(PREF_BLOCK_INSTA_REELS, false)
            YOUTUBE_PACKAGE -> prefs.getBoolean(PREF_BLOCK_YT_SHORTS, false)
            else -> true
        }
    }

    private fun isReelsLockActiveForPackage(
        packageName: String,
        nowMs: Long = System.currentTimeMillis()
    ): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val key = when (packageName) {
            FACEBOOK_PACKAGE -> PREF_FB_REELS_LOCK_UNTIL_MS
            INSTAGRAM_PACKAGE -> PREF_INSTA_REELS_LOCK_UNTIL_MS
            YOUTUBE_PACKAGE -> PREF_YT_SHORTS_LOCK_UNTIL_MS
            else -> return false
        }
        val lockUntilMs = prefs.getLong(key, 0L)
        return lockUntilMs > nowMs
    }

    private fun applyReelsLockForTwoDays(detectedPackageName: String?) {
        val packageName = detectedPackageName ?: return
        val lockKey = when (packageName) {
            FACEBOOK_PACKAGE -> PREF_FB_REELS_LOCK_UNTIL_MS
            INSTAGRAM_PACKAGE -> PREF_INSTA_REELS_LOCK_UNTIL_MS
            YOUTUBE_PACKAGE -> PREF_YT_SHORTS_LOCK_UNTIL_MS
            else -> return
        }

        val nowMs = System.currentTimeMillis()
        val newLockUntilMs = nowMs + REELS_LOCK_DURATION_MS
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val existingLockUntilMs = prefs.getLong(lockKey, 0L)
        val finalLockUntilMs = maxOf(existingLockUntilMs, newLockUntilMs)

        val editor = prefs.edit().putLong(lockKey, finalLockUntilMs)
        when (packageName) {
            FACEBOOK_PACKAGE -> editor.putBoolean(PREF_BLOCK_FB_REELS, true)
            INSTAGRAM_PACKAGE -> editor.putBoolean(PREF_BLOCK_INSTA_REELS, true)
            YOUTUBE_PACKAGE -> editor.putBoolean(PREF_BLOCK_YT_SHORTS, true)
        }
        editor.apply()
    }

    private fun isFocusModeActive(): Boolean {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val endTimeMs = prefs.getLong(PREF_FOCUS_MODE_END_TIME_MS, 0L)
        return endTimeMs > System.currentTimeMillis()
    }

    private fun getFocusModeRemainingMinutes(): Int {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val endTimeMs = prefs.getLong(PREF_FOCUS_MODE_END_TIME_MS, 0L)
        val nowMs = System.currentTimeMillis()
        if (endTimeMs <= nowMs) {
            return 0
        }
        return ((endTimeMs - nowMs) / 60 / 1000).toInt()
    }

    private fun getDistractingApps(): List<String> {
        val prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
        val json = prefs.getString(PREF_DISTRACTING_APPS, "[]")
        return try {
            json?.split(",")?.filter { it.isNotEmpty() } ?: emptyList()
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun isDistractingApp(packageName: String): Boolean {
        return getDistractingApps().contains(packageName)
    }

    private fun getMotivationalQuote(): String {
        val quotes = listOf(
            "Focus is the gateway to success. You've got this!",
            "Every moment of focus brings you closer to your goals.",
            "Your future self will thank you for focusing now.",
            "Distractions are temporary, but your goals are permanent.",
            "You are stronger than your distractions.",
            "Focus turns dreams into reality.",
            "This moment of focus will compound into greatness.",
            "Your goals are worth the sacrifice of distractions.",
            "Stay focused. Stay disciplined. Stay unstoppable.",
            "The only way out is through. Keep focusing.",
            "One focused hour beats ten distracted hours.",
            "You've already done the hard part—now just focus.",
            "This session will bring you closer to who you want to be.",
            "Your potential is waiting. Focus and unlock it.",
            "Every second of focus is a step toward excellence."
        )
        return quotes.random()
    }

    companion object {
        private const val TAG = "ShortVideoA11yService"
        private const val PREFS_NAME = "reels_block_prefs"
        private const val PREF_BLOCK_FB_REELS = "block_fb_reels"
        private const val PREF_BLOCK_INSTA_REELS = "block_insta_reels"
        private const val PREF_BLOCK_YT_SHORTS = "block_yt_shorts"
        private const val PREF_DISTRACTING_APPS = "distracting_apps"
        private const val PREF_FOCUS_MODE_END_TIME_MS = "focus_mode_end_ms"
        private const val PREF_FB_REELS_LOCK_UNTIL_MS = "fb_reels_lock_until_ms"
        private const val PREF_INSTA_REELS_LOCK_UNTIL_MS = "insta_reels_lock_until_ms"
        private const val PREF_YT_SHORTS_LOCK_UNTIL_MS = "yt_shorts_lock_until_ms"

        private const val FACEBOOK_PACKAGE = "com.facebook.katana"
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
        private const val YOUTUBE_PACKAGE = "com.google.android.youtube"

        private const val EVENT_DEBOUNCE_MS = 400L
        private const val HOME_CLICK_SUPPRESS_MS = 2_500L
        private const val MIN_REELS_OVERLAY_VISIBLE_MS = 1_500L
        private const val REELS_LOCK_DURATION_MS = 2L * 24L * 60L * 60L * 1000L

        private const val RIGHT_SIDE_MIN_RATIO = 0.60f
        private const val FULL_SCREEN_MIN_RATIO = 0.80f

        private const val STACK_X_ALIGNMENT_TOLERANCE_PX = 50
        private const val MIN_VERTICAL_STACK_GAP_PX = 50
        private const val HORIZONTAL_REJECTION_Y_DIFF_PX = 40
        private const val POINT_DEDUP_TOLERANCE_PX = 24
        private const val MAX_PARENT_DEPTH = 12

        private val TARGET_REELS_PACKAGES = setOf(
            FACEBOOK_PACKAGE,
            INSTAGRAM_PACKAGE,
            YOUTUBE_PACKAGE
        )

        private val TARGET_EVENT_TYPES = setOf(
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED,
            AccessibilityEvent.TYPE_VIEW_SCROLLED
        )
    }

    private data class InteractionPoint(
        val centerX: Int,
        val centerY: Int,
        val node: AccessibilityNodeInfo
    )

    private data class SignalState(
        var hasAudioSignature: Boolean = false
    )

    private data class FacebookContainerSignatureState(
        var hasOriginalAudio: Boolean = false,
        var hasStars: Boolean = false,
        var hasLike: Boolean = false,
        var hasComment: Boolean = false
    )
}
