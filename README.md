# Chat Clone (Flutter + Supabase)

## Setup steps

### 1. Supabase
1. supabase.com par naya project banao.
2. SQL Editor me `supabase/schema.sql` run karo.
3. Authentication > Providers > **Google** ON karo. "Client IDs" me Web client ID (aur Android client ID) comma se daalo. "Skip nonce check" ON rakho.
4. Authentication > Providers > **Phone** ON karo (neeche note dekho, SMS provider chahiye).
5. Settings > API se `Project URL` aur `anon public key` copy karo.

### 2. Google Cloud Console (free)
1. APIs & Services > OAuth consent screen banao.
2. Credentials > Create OAuth client ID:
   - **Web application** -> iska Client ID = `GOOGLE_WEB_CLIENT_ID`
   - **Android** -> package name `com.shadowarc.whatsapp_clone` + SHA-1 fingerprint
3. Release APK ka SHA-1: apni keystore ka SHA-1 daalo (debug-signed APK ke liye
   GitHub Action ke artifact APK se `keytool -printcert -jarfile app-release.apk` se mil jayega).

### 3. GitHub
Repo me ye code push karo, phir Settings > Secrets and variables > Actions me:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GOOGLE_WEB_CLIENT_ID`

Push karte hi Actions tab me build chalega, aur Artifacts me APK + AAB milega.

## Phone login free testing
Supabase Auth > Providers > Phone me "Test phone numbers and OTPs" me
`919999999999=123456` jaisa daalo. Is number pe SMS nahi jayega, OTP 123456 se login ho jayega (bilkul free).
