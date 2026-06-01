Build & Deploy
==============

Step 1 — Build
--------------
# For production database:
./build.sh prod

# For dev/default database:
./build.sh dev

Step 2 — Preview (test before going live)
-----------------------------------------
./admin_test_deploy.sh

The command prints a preview URL when it finishes, e.g.:
  https://shemesh-admin--shemesh-admin-<hash>.web.app

Open that URL to verify the build before promoting to production.

Step 3 — Deploy to production
------------------------------
./admin_deploy.sh

Notes
-----
- build.sh must be run before either deploy script (it produces build/web/).
- Make scripts executable if needed: chmod +x build.sh admin_deploy.sh admin_test_deploy.sh
- Preview channels expire after 7 days by default.
