package com.example.no_to_distraction

import android.graphics.Rect
import android.util.Log
import android.view.accessibility.AccessibilityNodeInfo
import kotlin.math.abs

data class InteractionPoint(
    val centerX: Int,
    val centerY: Int,
    val node: AccessibilityNodeInfo
)

data class SignalState(
    var hasAudioSignature: Boolean = false
)

data class FacebookContainerSignatureState(
    var hasOriginalAudio: Boolean = false,
    var hasStars: Boolean = false,
    var hasLike: Boolean = false,
    var hasComment: Boolean = false
)

object ScannerEngine {
    private const val TAG = Constants.TAG

    fun detectBySpatialHeuristics(
        root: AccessibilityNodeInfo,
        screenWidthPx: Int,
        screenHeightPx: Int
    ): Boolean {
        if (screenWidthPx <= 0 || screenHeightPx <= 0) return false

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

            // Heuristic B: horizontal action-row means regular feed post.
            if (hasHorizontalInteractionRow(uniquePoints)) {
                return false
            }

            // Heuristic A: must form a right-side vertically stacked interaction signature.
            val stackPassed = passesThreeButtonVerticalStack(uniquePoints, screenWidthPx)
            if (!stackPassed) {
                return false
            }

            // Heuristic C: short-video container must occupy >= 80% screen height.
            val containerPassed = largeScrollableContainers.isNotEmpty() ||
                    hasLargeParentFrameFromInteractions(uniquePoints, screenHeightPx)

            if (!containerPassed) {
                return false
            }

            if (signalState.hasAudioSignature) {
                Log.d(TAG, "Spatial detection confirmed with audio signature")
            }

            return true
        } finally {
            interactionPoints.forEach { try { it.node.recycle() } catch (_: Throwable) {} }
            largeScrollableContainers.forEach { try { it.recycle() } catch (_: Throwable) {} }
        }
    }

    fun isFacebookReel(rootNode: AccessibilityNodeInfo, screenWidthPx: Int, screenHeightPx: Int): Boolean {
        if (hasInstantFastPathSignature(rootNode)) return true
        if (isInCommentSection(rootNode)) return false
        if (screenWidthPx <= 0 || screenHeightPx <= 0) return false

        val fullScreenContainers = ArrayList<AccessibilityNodeInfo>(8)
        try {
            collectFullScreenContainers(rootNode, screenHeightPx, fullScreenContainers)
            if (fullScreenContainers.isEmpty()) return false

            for (container in fullScreenContainers) {
                val rightColumnCandidates = ArrayList<Pair<Int, Int>>(24)
                collectInteractionPoints(container, screenWidthPx, screenHeightPx, rightColumnCandidates)

                if (rightColumnCandidates.size < 3) continue

                val deduped = ArrayList<Pair<Int, Int>>(rightColumnCandidates.size)
                rightColumnCandidates
                    .sortedWith(compareBy<Pair<Int, Int>> { it.first }.thenBy { it.second })
                    .forEach { p ->
                        val exists = deduped.any { abs(it.first - p.first) <= 20 && abs(it.second - p.second) <= 20 }
                        if (!exists) deduped += p
                    }

                if (deduped.size < 3) continue
                if (deduped.any { it.first <= (screenWidthPx * 0.70f).toInt() }) continue

                val minX = deduped.minOf { it.first }
                val maxX = deduped.maxOf { it.first }
                if (maxX - minX > 100) continue

                val sortedY = deduped.map { it.second }.sorted()
                var progressiveCount = 1
                for (idx in 1 until sortedY.size) {
                    if (sortedY[idx] - sortedY[idx - 1] >= 45) progressiveCount++
                }
                if (progressiveCount >= 3) return true
            }
            return false
        } finally {
            fullScreenContainers.forEach { try { it.recycle() } catch (_: Throwable) {} }
        }
    }

    private fun hasInstantFastPathSignature(node: AccessibilityNodeInfo): Boolean {
        val blob = "${node.text} ${node.contentDescription}".lowercase()
        if (blob.contains("double tap to like") || blob.contains("original audio") ||
            blob.contains("send this to friends") || blob.contains("remix this reel")) return true

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try { if (hasInstantFastPathSignature(child)) return true } finally { child.recycle() }
        }
        return false
    }

    private fun isInCommentSection(node: AccessibilityNodeInfo): Boolean {
        val blob = "${node.text} ${node.contentDescription}".lowercase()
        val className = node.className?.toString().orEmpty()

        if (className.contains("EditText", ignoreCase = true)) {
            if (blob.contains("write") && blob.contains("comment")) return true
            if (blob.contains("reply to")) return true
        }

        if (blob.contains("most relevant") || blob.contains("newest") ||
            blob.contains("oldest") || (blob.contains("sort") && blob.contains("comment"))) return true

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try { if (isInCommentSection(child)) return true } finally { child.recycle() }
        }
        return false
    }

    private fun collectFullScreenContainers(node: AccessibilityNodeInfo, screenHeightPx: Int, out: MutableList<AccessibilityNodeInfo>) {
        val className = node.className?.toString().orEmpty()
        val isContainer = className.contains("RecyclerView") || className.contains("ViewPager") || className.contains("FrameLayout")
        
        if (isContainer) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            if (bounds.height() > 0 && bounds.height().toFloat() / screenHeightPx.toFloat() >= 0.85f) {
                out += AccessibilityNodeInfo.obtain(node)
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try { collectFullScreenContainers(child, screenHeightPx, out) } finally { child.recycle() }
        }
    }

    private fun collectInteractionPoints(node: AccessibilityNodeInfo, screenWidth: Int, screenHeight: Int, out: MutableList<Pair<Int, Int>>) {
        val blob = "${node.text} ${node.contentDescription}".lowercase()
        val className = node.className?.toString().orEmpty()

        val hasSignal = blob.contains("like") || blob.contains("comment") || blob.contains("share") ||
                        blob.contains("send") || blob.contains("audio") || blob.contains("reel") || blob.contains("remix")

        val isComment = className.contains("EditText") || (blob.contains("reply") && blob.contains("comment")) ||
                        (className.contains("TextView") && node.text?.length ?: 0 > 10 && (blob.contains(",") || blob.contains(".")))

        if (hasSignal && !isComment && (node.isClickable || node.isFocusable || className.contains("Button") || className.contains("ImageView"))) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            if (!bounds.isEmpty && bounds.width() > 0) {
                val cx = bounds.centerX()
                val cy = bounds.centerY()
                if (cx > (screenWidth * 0.70f).toInt() && cy > (screenHeight * 0.40f).toInt()) {
                    out += Pair(cx, cy)
                }
            }
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try { collectInteractionPoints(child, screenWidth, screenHeight, out) } finally { child.recycle() }
        }
    }

    private fun collectSpatialSignals(node: AccessibilityNodeInfo, interactionPoints: MutableList<InteractionPoint>,
                                       largeScrollableContainers: MutableList<AccessibilityNodeInfo>, signalState: SignalState, screenHeightPx: Int) {
        val blob = "${node.text} ${node.contentDescription}".lowercase()
        if (blob.contains("original audio") || blob.contains("remix")) signalState.hasAudioSignature = true

        if (blob.contains("like") || blob.contains("comment") || blob.contains("share") || blob.contains("send")) {
            val bounds = Rect()
            node.getBoundsInScreen(bounds)
            if (!bounds.isEmpty && bounds.centerX() > 0 && bounds.centerY() > 0) {
                interactionPoints += InteractionPoint(bounds.centerX(), bounds.centerY(), AccessibilityNodeInfo.obtain(node))
            }
        }

        if (isScrollableContainer(node) && occupiesAtLeast80PercentHeight(node, screenHeightPx)) {
            largeScrollableContainers += AccessibilityNodeInfo.obtain(node)
        }

        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            try { collectSpatialSignals(child, interactionPoints, largeScrollableContainers, signalState, screenHeightPx) } finally { child.recycle() }
        }
    }

    private fun deduplicateInteractionPoints(points: List<InteractionPoint>): List<InteractionPoint> {
        if (points.isEmpty()) return emptyList()
        val sorted = points.sortedWith(compareBy<InteractionPoint> { it.centerX }.thenBy { it.centerY })
        val deduped = ArrayList<InteractionPoint>(sorted.size)
        for (candidate in sorted) {
            val hasNear = deduped.any { abs(it.centerX - candidate.centerX) <= Constants.POINT_DEDUP_TOLERANCE_PX && abs(it.centerY - candidate.centerY) <= Constants.POINT_DEDUP_TOLERANCE_PX }
            if (!hasNear) deduped += candidate
        }
        return deduped
    }

    private fun hasHorizontalInteractionRow(points: List<InteractionPoint>): Boolean {
        if (points.size < 2) return false
        for (i in points.indices) {
            for (j in i + 1 until points.size) {
                if (abs(points[i].centerY - points[j].centerY) < Constants.HORIZONTAL_REJECTION_Y_DIFF_PX) return true
            }
        }
        return false
    }

    private fun passesThreeButtonVerticalStack(points: List<InteractionPoint>, screenWidth: Int): Boolean {
        val minX = (screenWidth * Constants.RIGHT_SIDE_MIN_RATIO).toInt()
        val rightSide = points.filter { it.centerX > minX }.sortedBy { it.centerY }
        if (rightSide.size < 3) return false

        for (i in 0..rightSide.size - 3) {
            for (j in i + 1 until rightSide.size - 1) {
                for (k in j + 1 until rightSide.size) {
                    val a = rightSide[i]; val b = rightSide[j]; val c = rightSide[k]
                    val xAligned = abs(a.centerX - b.centerX) <= Constants.STACK_X_ALIGNMENT_TOLERANCE_PX &&
                                   abs(b.centerX - c.centerX) <= Constants.STACK_X_ALIGNMENT_TOLERANCE_PX &&
                                   abs(a.centerX - c.centerX) <= Constants.STACK_X_ALIGNMENT_TOLERANCE_PX
                    val yDistinct = abs(a.centerY - b.centerY) >= Constants.MIN_VERTICAL_STACK_GAP_PX &&
                                    abs(b.centerY - c.centerY) >= Constants.MIN_VERTICAL_STACK_GAP_PX &&
                                    abs(a.centerY - c.centerY) >= Constants.MIN_VERTICAL_STACK_GAP_PX
                    if (xAligned && yDistinct) return true
                }
            }
        }
        return false
    }

    private fun hasLargeParentFrameFromInteractions(points: List<InteractionPoint>, screenHeight: Int): Boolean {
        for (point in points) {
            var depth = 0
            var current = point.node.parent
            while (current != null && depth <= Constants.MAX_PARENT_DEPTH) {
                try {
                    val className = current.className?.toString().orEmpty()
                    val isCandidate = className.contains("FrameLayout") || className.contains("RecyclerView") || className.contains("ViewPager")
                    if (isCandidate && occupiesAtLeast80PercentHeight(current, screenHeight)) return true
                    val next = current.parent
                    current.recycle()
                    current = next
                    depth++
                } catch (_: Throwable) {
                    try { current?.recycle() } catch (_: Throwable) {}
                    current = null
                }
            }
        }
        return false
    }

    private fun isScrollableContainer(node: AccessibilityNodeInfo): Boolean {
        val className = node.className?.toString().orEmpty()
        return node.isScrollable || className.contains("RecyclerView") || className.contains("ViewPager")
    }

    private fun occupiesAtLeast80PercentHeight(node: AccessibilityNodeInfo, screenHeight: Int): Boolean {
        if (screenHeight <= 0) return false
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        return bounds.height() > 0 && bounds.height().toFloat() / screenHeight.toFloat() >= Constants.FULL_SCREEN_MIN_RATIO
    }
}
