#!/bin/bash
# ═══════════════════════════════════════
# Retrofit ADAS - İlk Kurulum
# ═══════════════════════════════════════
# Bu script gradle wrapper jar'ını indirir.
# Sadece bir kez çalıştırmanız yeterli.

echo "🚗 Retrofit ADAS - Gradle Wrapper kuruluyor..."

WRAPPER_JAR="gradle/wrapper/gradle-wrapper.jar"
WRAPPER_URL="https://raw.githubusercontent.com/gradle/gradle/v8.5.0/gradle/wrapper/gradle-wrapper.jar"
FALLBACK_URL="https://services.gradle.org/distributions/gradle-8.5-bin.zip"

if [ -f "$WRAPPER_JAR" ]; then
    echo "✅ gradle-wrapper.jar zaten mevcut."
else
    echo "📥 gradle-wrapper.jar indiriliyor..."
    mkdir -p gradle/wrapper
    
    # Try downloading wrapper jar directly
    if command -v curl &>/dev/null; then
        curl -sL "https://raw.githubusercontent.com/nicoulaj/gradle-wrapper/master/gradle/wrapper/gradle-wrapper.jar" -o "$WRAPPER_JAR" 2>/dev/null
    elif command -v wget &>/dev/null; then
        wget -q "https://raw.githubusercontent.com/nicoulaj/gradle-wrapper/master/gradle/wrapper/gradle-wrapper.jar" -O "$WRAPPER_JAR" 2>/dev/null
    fi
    
    if [ -f "$WRAPPER_JAR" ] && [ -s "$WRAPPER_JAR" ]; then
        echo "✅ gradle-wrapper.jar indirildi!"
    else
        echo ""
        echo "⚠️  Otomatik indirme başarısız."
        echo ""
        echo "Manuel çözüm (Android Studio):"
        echo "  1. Android Studio → File → Open → bu klasör"
        echo "  2. Android Studio wrapper'ı otomatik oluşturur"
        echo ""
        echo "Manuel çözüm (Terminal):"
        echo "  gradle wrapper --gradle-version 8.5"
        exit 1
    fi
fi

echo ""
echo "✅ Kurulum tamamlandı!"
echo "   Build: ./gradlew assembleDebug"
echo "   Test:  ./gradlew testDebugUnitTest"
