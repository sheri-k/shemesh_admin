#!/bin/bash

echo "🚀 Deploying ADMIN to Firebase Hosting (production)..."
echo "firebase deploy --only hosting:admin"

firebase deploy --only hosting:admin

echo "Admin deploy complete."