package com.example.typgraphyeditor

import android.content.res.AssetManager
import android.graphics.Typeface
import java.io.IOException

object FontManager {
    private val typefaceCache = mutableMapOf<String, Typeface>()

    // Mapping of family names to their primary asset path
    private val fontAssets = mapOf(
        "Bellota" to "assets/fonts/Bellota-Regular.ttf",
        "BhuTukaExpandedOne" to "assets/fonts/BhuTukaExpandedOne-Regular.ttf",
        "Bokor" to "assets/fonts/Bokor-Regular.ttf",
        "BungeeHairline" to "assets/fonts/BungeeHairline-Regular.ttf",
        "Caramel" to "assets/fonts/Caramel-Regular.ttf",
        "Centralwell" to "assets/fonts/Centralwell.ttf",
        "Chalk Board" to "assets/fonts/Chalk Board.ttf",
        "Eternal" to "assets/fonts/Eternal.ttf",
        "Explora" to "assets/fonts/Explora-Regular.ttf",
        "GrandifloraOne" to "assets/fonts/GrandifloraOne-Regular.ttf",
        "KleeOne" to "assets/fonts/KleeOne-SemiBold.ttf",
        "Lacquer" to "assets/fonts/Lacquer-Regular.ttf",
        "LibreBarcode39Text" to "assets/fonts/LibreBarcode39Text-Regular.ttf",
        "LuckiestGuy" to "assets/fonts/LuckiestGuy-Regular.ttf",
        "MajorMonoDisplay" to "assets/fonts/MajorMonoDisplay-Regular.ttf",
        "Metrophobic" to "assets/fonts/Metrophobic-Regular.ttf",
        "Michroma" to "assets/fonts/Michroma-Regular.ttf",
        "Milker" to "assets/fonts/Milker.otf",
        "NCLNeovibes" to "assets/fonts/NCLNeovibes-Demo.otf",
        "NewRocker" to "assets/fonts/NewRocker-Regular.ttf",
        "NewTegomin" to "assets/fonts/NewTegomin-Regular.ttf",
        "Poppins" to "assets/fonts/Poppins-Regular.ttf",
        "ProtestRevolution" to "assets/fonts/ProtestRevolution-Regular.ttf",
        "RELIGATH" to "assets/fonts/RELIGATH-Demo.otf",
        "akony" to "assets/fonts/akony.otf",
        "modernline" to "assets/fonts/modernline.otf",
        "modernline bold" to "assets/fonts/modernline bold.otf"
    )

    fun getTypeface(assetManager: AssetManager, family: String): Typeface {
        return typefaceCache.getOrPut(family) {
            val path = fontAssets[family]
            if (path != null) {
                try {
                    // Flutter assets are typically in "flutter_assets/" prefix in the APK
                    Typeface.createFromAsset(assetManager, "flutter_assets/$path")
                } catch (e: Exception) {
                    e.printStackTrace()
                    Typeface.DEFAULT
                }
            } else {
                Typeface.DEFAULT
            }
        }
    }
}
