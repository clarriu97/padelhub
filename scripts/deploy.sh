#!/bin/bash

# Script de deployment para Firebase
# Uso: ./scripts/deploy.sh [functions|firestore|storage|all]

set -e

cd "$(dirname "$0")/.."

case "$1" in
  functions)
    echo "🚀 Deploying Cloud Functions..."
    firebase deploy --only functions
    ;;
  firestore)
    echo "🔒 Deploying Firestore rules..."
    firebase deploy --only firestore:rules
    echo "📊 Deploying Firestore indexes..."
    firebase deploy --only firestore:indexes
    ;;
  storage)
    echo "🗄️ Deploying Storage rules..."
    firebase deploy --only storage
    ;;
  all)
    echo "🚀 Deploying everything..."
    firebase deploy
    ;;
  *)
    echo "Usage: $0 [functions|firestore|storage|all]"
    echo ""
    echo "Examples:"
    echo "  $0 functions   # Deploy only Cloud Functions"
    echo "  $0 firestore   # Deploy Firestore rules & indexes"
    echo "  $0 storage     # Deploy Storage rules"
    echo "  $0 all         # Deploy everything"
    exit 1
    ;;
esac

echo "✅ Deployment complete!"
