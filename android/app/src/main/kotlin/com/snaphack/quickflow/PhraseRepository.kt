package com.snaphack.quickflow

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

data class Category(
    val id: String,
    val name: String,
    val icon: String,
    val colorValue: Int,
    val isSmartFilterEnabled: Boolean
)

data class Phrase(
    val id: String,
    val text: String,
    val categoryId: String,
    val usageCount: Int = 0,
    val tags: List<String> = emptyList()
)

class PhraseRepository(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("QuickFlowSharedPrefs", Context.MODE_PRIVATE)

    fun saveSyncedData(jsonString: String) {
        prefs.edit().putString("synced_data", jsonString).apply()
    }

    fun getCategories(): List<Category> {
        val jsonString = prefs.getString("synced_data", null) ?: return getDefaultCategories()
        val list = mutableListOf<Category>()
        try {
            val root = JSONObject(jsonString)
            val catsArray = root.optJSONArray("categories") ?: return getDefaultCategories()
            for (i in 0 until catsArray.length()) {
                val obj = catsArray.getJSONObject(i)
                list.add(
                    Category(
                        id = obj.getString("id"),
                        name = obj.getString("name"),
                        icon = obj.optString("icon", "💬"),
                        colorValue = obj.optInt("colorValue", 0xFF6366F1.toInt()),
                        isSmartFilterEnabled = obj.optBoolean("isSmartFilterEnabled", true)
                    )
                )
            }
        } catch (e: Exception) {
            return getDefaultCategories()
        }
        return if (list.isEmpty()) getDefaultCategories() else list
    }

    fun getPhrases(): List<Phrase> {
        val jsonString = prefs.getString("synced_data", null) ?: return getDefaultPhrases()
        val list = mutableListOf<Phrase>()
        try {
            val root = JSONObject(jsonString)
            val phrasesArray = root.optJSONArray("phrases") ?: return getDefaultPhrases()
            for (i in 0 until phrasesArray.length()) {
                val obj = phrasesArray.getJSONObject(i)
                val tagsList = mutableListOf<String>()
                val tagsArr = obj.optJSONArray("tags")
                if (tagsArr != null) {
                    for (j in 0 until tagsArr.length()) {
                        tagsList.add(tagsArr.getString(j))
                    }
                }
                list.add(
                    Phrase(
                        id = obj.getString("id"),
                        text = obj.getString("text"),
                        categoryId = obj.optString("categoryId", "general"),
                        usageCount = obj.optInt("usageCount", 0),
                        tags = tagsList
                    )
                )
            }
        } catch (e: Exception) {
            return getDefaultPhrases()
        }
        return if (list.isEmpty()) getDefaultPhrases() else list
    }

    fun getBubbleSettings(): JSONObject {
        val jsonString = prefs.getString("synced_data", null) ?: return JSONObject()
        return try {
            JSONObject(jsonString).optJSONObject("settings") ?: JSONObject()
        } catch (e: Exception) {
            JSONObject()
        }
    }

    private fun getDefaultCategories(): List<Category> {
        return listOf(
            Category("openers", "Openers", "👋", 0xFF6366F1.toInt(), true),
            Category("small_talk", "Small Talk", "💬", 0xFF0EA5E9.toInt(), true),
            Category("followups", "Follow-ups", "⏰", 0xFFF59E0B.toInt(), false),
            Category("quick_replies", "Quick Replies", "⚡", 0xFF10B981.toInt(), false)
        )
    }

    private fun getDefaultPhrases(): List<Phrase> {
        return listOf(
            // Openers
            Phrase("op_1", "Hey! How are you doing today?", "openers"),
            Phrase("op_2", "Hey there! Hope you're having a wonderful week.", "openers"),
            Phrase("op_3", "Hi! Long time no see, how have you been?", "openers"),

            // Small Talk
            Phrase("st_1", "Where are you from originally?", "small_talk"),
            Phrase("st_2", "What do you enjoy doing in your free time?", "small_talk"),
            Phrase("st_3", "What line of work are you in?", "small_talk"),
            Phrase("st_4", "Any exciting plans for the weekend?", "small_talk"),

            // Follow-ups
            Phrase("fl_1", "Just following up on my previous message!", "followups"),
            Phrase("fl_2", "Let me know when you get a chance to take a look.", "followups"),
            Phrase("fl_3", "Sounds great, looking forward to it!", "followups"),

            // Quick Replies
            Phrase("qr_1", "I'm in a quick meeting, will get back to you shortly!", "quick_replies"),
            Phrase("qr_2", "On my way now! See you in about 10 minutes.", "quick_replies"),
            Phrase("qr_3", "Could you please send over the link or details?", "quick_replies"),
            Phrase("qr_4", "Thanks a lot, really appreciate your help! 🙌", "quick_replies")
        )
    }
}
