package com.snaphack.quickflow

import java.util.concurrent.ConcurrentHashMap

/**
 * Smart conversation memory: tracks which categories have been used in which chat app or conversation.
 * If a category is marked as smart-filtered and has already been used in this chat session,
 * it is automatically hidden or filtered out so the user does not repeat themselves.
 */
object SmartChatMemory {
    // Map of packageName -> Set of used category IDs in current session
    private val sessionUsedCategories = ConcurrentHashMap<String, MutableSet<String>>()

    // Map of packageName -> Set of used phrase IDs in current session
    private val sessionUsedPhrases = ConcurrentHashMap<String, MutableSet<String>>()

    // Last interaction timestamp per package to auto-expire sessions after 30 minutes of inactivity
    private val lastActivityMap = ConcurrentHashMap<String, Long>()
    private const val SESSION_TIMEOUT_MS = 30 * 60 * 1000L // 30 minutes

    fun recordUsed(packageName: String, categoryId: String, phraseId: String) {
        val now = System.currentTimeMillis()
        cleanExpiredSessions(now)

        lastActivityMap[packageName] = now

        val catSet = sessionUsedCategories.computeIfAbsent(packageName) { mutableSetOf() }
        catSet.add(categoryId)

        val phraseSet = sessionUsedPhrases.computeIfAbsent(packageName) { mutableSetOf() }
        phraseSet.add(phraseId)
    }

    fun isCategoryUsed(packageName: String, categoryId: String): Boolean {
        cleanExpiredSessions(System.currentTimeMillis())
        val catSet = sessionUsedCategories[packageName] ?: return false
        return catSet.contains(categoryId)
    }

    fun isPhraseUsed(packageName: String, phraseId: String): Boolean {
        cleanExpiredSessions(System.currentTimeMillis())
        val phraseSet = sessionUsedPhrases[packageName] ?: return false
        return phraseSet.contains(phraseId)
    }

    fun resetAll() {
        sessionUsedCategories.clear()
        sessionUsedPhrases.clear()
        lastActivityMap.clear()
    }

    fun resetForPackage(packageName: String) {
        sessionUsedCategories.remove(packageName)
        sessionUsedPhrases.remove(packageName)
        lastActivityMap.remove(packageName)
    }

    private fun cleanExpiredSessions(now: Long) {
        val iterator = lastActivityMap.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (now - entry.value > SESSION_TIMEOUT_MS) {
                sessionUsedCategories.remove(entry.key)
                sessionUsedPhrases.remove(entry.key)
                iterator.remove()
            }
        }
    }
}
