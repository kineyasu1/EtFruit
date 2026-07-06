# Firebase Setup Guide — Agriገበያ

Follow these steps in the Firebase Console to integrate the real Firebase backend.

---

## Step 1: Create a Firebase Project
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** (or **Create a Project**).
3. Name your project (e.g., `AgriMarketMob` or `EtFruit`).
4. Configure Google Analytics preferences and click **Create project**.

---

## Step 2: Register the Android Application
1. On the project overview homepage, click the **Android** icon to add an app.
2. Enter the **Android package name**: `com.farmlink.agrimarketmob` (must match exactly).
3. Enter an optional App nickname.
4. **CRITICAL FOR PHONE AUTH**: Under **Debug signing certificate SHA-1**, paste your SHA-1 key fingerprint.
   * *To get your debug SHA-1 fingerprint on Windows, run this in your terminal:*
     ```powershell
     keytool -list -v -alias androiddebugkey -keystore C:\Users\Kin\.android\debug.keystore
     ```
     *(Password is `android`)*
5. Click **Register App**.

---

## Step 3: Integrate `google-services.json`
1. Download the generated `google-services.json` file from the registration step.
2. Move it directly into the project's Android app module folder at:
   `android/app/google-services.json`
3. Click **Next** through the setup wizard (the Gradle configurations are already wired up in Phase 1).

---

## Step 4: Enable Phone Authentication
1. In the Firebase left sidebar, navigate to **Build** > **Authentication**.
2. Click **Get Started**.
3. Under the **Sign-in method** tab, select the **Phone** provider.
4. Toggle **Enable** and click **Save**.
5. *(Optional for testing)* Expand the Phone section and add test phone numbers & verification codes (e.g. `+251911000000` with code `123456`) to skip network SMS validation during sandbox development.

---

## Step 5: Enable Firestore Database
1. Go to **Build** > **Firestore Database** in the left sidebar.
2. Click **Create Database**.
3. Choose your database location (select a regional location closest to Ethiopia/East Africa, e.g. `europe-west9` or `europe-west1`).
4. Choose **Start in production mode** (our strict rules file `firestore.rules` will protect the collections once deployed).
5. Click **Create**.

---

## Step 6: Enable Firebase Storage
1. Go to **Build** > **Storage** in the left sidebar.
2. Click **Get Started**.
3. Choose **Start in production mode** (our `storage.rules` will govern access).
4. Select the location (matches your database location) and click **Done**.

---

## Step 7: Deploy Rules
Install Firebase CLI globally and run the following command to deploy database & storage rules to your live project:
```bash
npm install -g firebase-tools
firebase login
firebase use --add <your-firebase-project-id>
firebase deploy --only firestore:rules,storage
```
