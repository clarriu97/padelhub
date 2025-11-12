#!/bin/bash

# 🔍 Script de verificación pre-commit para PadelHub
# Verifica que no se suban archivos sensibles

echo "🔍 Verificando archivos sensibles antes del commit..."

# Archivos sensibles que NUNCA deben subirse
SENSITIVE_FILES=(
    "lib/firebase_options.dart"
    "android/app/google-services.json"
    "ios/Runner/GoogleService-Info.plist"
    "android/app/keystore.properties"
    ".env"
)

# Patrones sensibles en el contenido
SENSITIVE_PATTERNS=(
    "AIzaSy"  # API Keys de Google/Firebase
    "AAAA.*:.*firebase"  # Firebase server keys
    "sk_live_"  # Stripe live keys
    "sk_test_"  # Stripe test keys
    "password.*=.*\""
    "secret.*=.*\""
)

ERROR_FOUND=0

# Verificar archivos en staging
echo ""
echo "📋 Archivos en staging:"
git diff --cached --name-only

echo ""
echo "🔐 Verificando archivos sensibles..."

# Verificar archivos específicos
for file in "${SENSITIVE_FILES[@]}"; do
    if git diff --cached --name-only | grep -q "^$file$"; then
        echo "❌ ERROR: Intentando subir archivo sensible: $file"
        ERROR_FOUND=1
    fi
done

# Verificar patrones sensibles en el contenido
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if git diff --cached | grep -qE "$pattern"; then
        echo "⚠️  ADVERTENCIA: Posible contenido sensible detectado (patrón: $pattern)"
        echo "   Revisa tus cambios cuidadosamente"
        ERROR_FOUND=1
    fi
done

# Verificar archivos grandes (>10MB)
echo ""
echo "📦 Verificando archivos grandes..."
LARGE_FILES=$(git diff --cached --name-only | xargs -I {} du -sh {} 2>/dev/null | awk '$1 ~ /[0-9]+M/ && $1 !~ /^[0-9]M/ {print}')
if [ ! -z "$LARGE_FILES" ]; then
    echo "⚠️  Archivos grandes detectados (considera Git LFS):"
    echo "$LARGE_FILES"
fi

echo ""
if [ $ERROR_FOUND -eq 1 ]; then
    echo "❌ Verificación FALLIDA - Por favor revisa los errores arriba"
    echo ""
    echo "Para continuar de todos modos (NO RECOMENDADO):"
    echo "  git commit --no-verify -m 'tu mensaje'"
    exit 1
else
    echo "✅ Verificación pasada - No se detectaron problemas"
    exit 0
fi
