#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-}"

case "$ENV" in
  prod|production)
    DB_ID="production"
    ;;
  dev|default)
    DB_ID="(default)"
    ;;
  *)
    echo "Usage: $0 [prod|dev]"
    echo "  prod  — builds with databaseId='production'"
    echo "  dev   — builds with databaseId='(default)'"
    exit 1
    ;;
esac

echo "Building Flutter web with databaseId='$DB_ID'..."
flutter build web --dart-define=DATABASE_ID="$DB_ID"
echo "Done. Output: build/web/"
