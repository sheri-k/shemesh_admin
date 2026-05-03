#!/bin/bash

echo "Deploying ADMIN to Firebase Hosting (preview channel: shemesh-admin)..."

echo "firebase hosting:channel:deploy shemesh-admin"
firebase hosting:channel:deploy shemesh-admin

echo "Admin preview deploy complete."