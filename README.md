# Moneris Payment — Production Guide (Flutter app + Node backend)

This document collects the production-ready changes and steps for both the backend (Node.js) and the Flutter mobile app that integrates with Moneris. It includes corrected code snippets, environment configuration, build flavors, deployment tips, security and PCI considerations, and monitoring recommendations.

## Contents
- Backend: environment, security, deployment
- Flutter: environment, services, WebView production HTML, build flavors
- Security & PCI compliance
- Monitoring & analytics
- Troubleshooting & checklist

---

## 1. Backend (Node.js) — Production Setup

1. Environment variables (.env)

Create a `.env` file in your backend root (never commit this file):

```bash
# Production
NODE_ENV=production
PORT=5000

# Moneris Production Credentials
MONERIS_STORE_ID=your_production_store_id
MONERIS_API_TOKEN=your_production_api_token
MONERIS_CHECKOUT_ID=your_production_checkout_id
MONERIS_GATEWAY_URL=https://gateway.moneris.com/chkt/request/request.php

# Database
DATABASE_URL=postgresql://user:pass@db-host:5432/dbname

# Security
JWT_SECRET=your_long_random_jwt_secret
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX=100

# Logging
LOG_LEVEL=info

# Optional: Sentry
SENTRY_DSN=https://your_sentry_dsn
```

2. Security middleware (example Express snippet)

```javascript
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const express = require('express');
const app = express();

app.use(helmet());
app.set('trust proxy', 1); // if behind proxy (nginx, Heroku)

const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '900000'),
  max: parseInt(process.env.RATE_LIMIT_MAX || '100'),
});
app.use(limiter);

// Force HTTPS in production (behind a proxy)
if (process.env.NODE_ENV === 'production') {
  app.use((req, res, next) => {
    if (req.header('x-forwarded-proto') && req.header('x-forwarded-proto') !== 'https') {
      return res.redirect(`https://${req.header('host')}${req.url}`);
    }
    next();
  });
}
```

3. Moneris endpoints — secure server-to-server calls

- Keep all Moneris credentials server-side. The mobile app should request the creation of a checkout token (ticket) from the backend. The backend calls Moneris and returns only the token or redirect data.
- Avoid passing API tokens or store ids to the client.

Example route (pseudo):

```javascript
app.post('/create-checkout', async (req, res) => {
  // validate & sanitize input (amount, order no, customerId)
  // call Moneris API using MONERIS_STORE_ID and MONERIS_API_TOKEN
  // return JSON { success: true, ticket: '...', checkout_id: '...' }
});
```

4. Process manager & deployment

- Use PM2, systemd, Docker, or your cloud provider process manager.

PM2 example:

```bash
npm install -g pm2
pm2 start index.js --name moneris-payment
pm2 startup
pm2 save
```

Procfile for Heroku/Railway/DigitalOcean App Platform:

```
web: node index.js
```

Update `package.json` scripts and engines:

```json
"scripts": {
  "start": "node index.js",
  "dev": "nodemon index.js",
  "heroku-postbuild": "echo 'No build needed'"
},
"engines": {
  "node": ">=18.0.0"
}
```

5. TLS/Reverse proxy

- Prefer terminating TLS at a reverse proxy (Nginx, Cloud Load Balancer) or use platform-managed TLS (Heroku, Railway).
- If using Nginx, proxy requests to the internal Node port and set proper headers (see the `Readme.md` already added).

6. Logging and backups

- Integrate Sentry or a similar tool for exception tracking.
- Ship logs to a central logging solution (Papertrail, LogDNA, ELK).
- Ensure database backups and tested recovery procedures exist.

---

## 2. Flutter App — Production Updates & Fixes

This section fixes and finalizes the provided snippets, adding clarifications for production builds and WebView behavior.

1. Environment file (lib/config/environment.dart)

Create `lib/config/environment.dart` (use Dart compile-time constants via --dart-define for production builds):

```dart
abstract class Environment {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:5000', // Emulator dev server
  );

  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Moneris App (Dev)',
  );
}
```

How to pass these values at build/run time:

Android (debug):

```bash
flutter run --flavor development -t lib/main.dart --dart-define=BASE_URL=http://10.0.2.2:5000 --dart-define=IS_PRODUCTION=false --dart-define=APP_NAME="Moneris App (Dev)"
```

Android (release):

```bash
flutter build apk --flavor production -t lib/main.dart --dart-define=BASE_URL=https://your-production-api.com --dart-define=IS_PRODUCTION=true --dart-define=APP_NAME="Moneris App"
```

2. Moneris service (lib/services/moneris_service.dart)

This is the corrected and improved `MonerisService` using your snippet. Keep only server calls and remove client-side secrets. Use production mode to avoid fallbacks.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class MonerisService {
  static const String baseUrl = Environment.baseUrl;
  static const bool isProduction = Environment.isProduction;

  static Future<Map<String, dynamic>> createCheckout({
    required double amount,
    String? orderNo,
    String? customerId,
    String? description,
  }) async {
    try {
      print('💰 ${isProduction ? 'PRODUCTION' : 'TEST'} Checkout: \$${amount.toStringAsFixed(2)}');

      final response = await http.post(
        Uri.parse('$baseUrl/create-checkout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': amount.toStringAsFixed(2),
          'orderNo': orderNo,
          'customerId': customerId,
          'description': description ?? 'App Purchase',
          if (isProduction) ...{
            // Only include non-sensitive metadata required by your backend
            'email': 'customer@example.com',
            'phone': '+1234567890',
          },
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Checkout created in ${isProduction ? 'PRODUCTION' : 'TEST'} mode');
        return result;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e, st) {
      print('❌ Checkout error: $e');
      if (isProduction) {
        rethrow; // surface errors in production
      } else {
        return _createFallbackCheckout(amount);
      }
    }
  }

  static Map<String, dynamic> _createFallbackCheckout(double amount) {
    if (isProduction) {
      throw Exception('Checkout service unavailable');
    }

    return {
      'success': true,
      'ticket': 'fallback_ticket_${DateTime.now().millisecondsSinceEpoch}',
      'checkout_id': 'fallback_checkout',
      'order_no': 'FALLBACK_${DateTime.now().millisecondsSinceEpoch}',
      'amount': amount.toStringAsFixed(2),
      'is_fallback': true,
    };
  }

  // TODO: implement verifyPayment and other methods similarly
}
```

Notes:
- The app should never contain Moneris API tokens. Only the backend does.
- Remove fallback behavior in production or keep it guarded by `isProduction` checks as above.

3. WebView / Checkout HTML (lib/screens/checkout_webview.dart)

Use a minimal, sanitized HTML page that loads Moneris JS in production. This snippet uses `Environment.isProduction` to decide which script URL and which checkout flows to use.

```dart
String _getCheckoutHTML(String ticket, double amount) {
  final isProduction = Environment.isProduction;

  return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Checkout</title>
    ${isProduction ?
      '<script src="https://gateway.moneris.com/chkt/js/chkt_v1.00.js"></script>' :
      '<script src="https://gatewayt.moneris.com/chkt/js/chkt_v1.00.js"></script>'
    }
    <style>body{font-family:sans-serif;margin:0;padding:0}</style>
</head>
<body>
    <div id="container">
        ${isProduction ? '''
        <div id="monerisCheckout"></div>
        <script>
            var myCheckout = new monerisCheckout();
            try {
                myCheckout.setMode("prod");
                myCheckout.setCheckoutDiv("monerisCheckout");

                myCheckout.setCallback("payment_receipt", function(response) {
                    if (window.Flutter) {
                        window.Flutter.postMessage(JSON.stringify({ event: "payment_success", data: response }));
                    }
                });

                myCheckout.setCallback("error_event", function(error) {
                    if (window.Flutter) {
                        window.Flutter.postMessage(JSON.stringify({ event: "payment_error", data: error }));
                    }
                });

                myCheckout.startCheckout('$ticket');
            } catch (e) {
                if (window.Flutter) {
                    window.Flutter.postMessage(JSON.stringify({ event: "payment_error", data: { message: e.toString() } }));
                }
            }
        </script>
        ''' : '''
        <div id="paymentForm">
            <p>Test payment UI (development only)</p>
            <!-- Add a simple test form that posts to your /simulate-checkout endpoint -->
        </div>
        '''}
    </div>
</body>
</html>
''';
}
```

Security notes for WebView:
- Load local HTML where possible, or ensure the HTML is served over HTTPS from your backend.
- Use Content Security Policy (CSP) headers if you serve the HTML from your server.

4. Android build.gradle — flavors & buildConfigField

Edit `android/app/build.gradle` to include flavors and buildConfigFields as you provided. Example (only the relevant section shown):

```gradle
android {
  defaultConfig {
    applicationId "com.yourapp.moneris"
    minSdkVersion 21
    targetSdkVersion 34
  }

  buildTypes {
    release {
      signingConfig signingConfigs.release
      minifyEnabled true
      proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
    debug {
      applicationIdSuffix ".debug"
    }
  }

  flavorDimensions "environment"
  productFlavors {
    development {
      dimension "environment"
      applicationIdSuffix ".dev"
      versionNameSuffix "-dev"
      buildConfigField "String", "BASE_URL", '"http://10.0.2.2:5000"'
      buildConfigField "boolean", "IS_PRODUCTION", "false"
    }
    production {
      dimension "environment"
      buildConfigField "String", "BASE_URL", '"https://your-production-api.com"'
      buildConfigField "boolean", "IS_PRODUCTION", "true"
    }
  }
}
```

Note: Prefer `--dart-define` instead of BuildConfig for cross-platform parity. If you need native build config usage, read them using platform channels or a package like `flutter_dotenv`.

---

## 3. Security & PCI Compliance

- Never store raw card data on your servers. Use Moneris tokenization and transaction IDs.
- Use HTTPS everywhere. Enforce HSTS and modern TLS.
- Limit access to Moneris credentials and rotate them periodically.
- Mask sensitive logs and never log full card numbers, tokens are fine only when necessary and per Moneris guidance.
- Perform regular security scans and dependency vulnerability checks.

PCI-specific tips:
- Work with Moneris to understand which PCI SAQ you need to complete.
- Use hosted payment pages or tokenization to reduce your PCI scope.

---

## 4. Monitoring & Analytics

1. Error tracking: Sentry (backend + app)

Backend (Node):

```javascript
const Sentry = require('@sentry/node');
Sentry.init({ dsn: process.env.SENTRY_DSN, environment: process.env.NODE_ENV });
app.use(Sentry.Handlers.requestHandler());
app.use(Sentry.Handlers.errorHandler());
```

Flutter app (main.dart):

```dart
import 'package:sentry_flutter/sentry_flutter.dart';
import 'config/environment.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
      options.environment = Environment.isProduction ? 'production' : 'development';
    },
    appRunner: () => runApp(MyApp()),
  );
}
```

2. Performance & uptime monitoring

- Use uptime checks and health endpoints for the backend.
- Add analytics to the app (Firebase Analytics, Amplitude) to monitor usage patterns.

---

## 5. Troubleshooting & Checklist

Checklist before going live:

- [ ] All production env variables set on hosting provider
- [ ] Moneris production credentials verified
- [ ] SSL certificate installed and TLS enforced
- [ ] Rate limiting & helmet enabled
- [ ] Logging and Sentry integrated
- [ ] Database backups configured and tested
- [ ] Load and basic functional testing completed
- [ ] PCI compliance steps documented and in progress

Common issues:

- Payment failing: check backend Moneris logs, ensure timestamps and HMAC signatures match Moneris docs.
- WebView not posting messages: verify window.Flutter bridge is available (Android WebView vs. iOS WKWebView differences) and that the HTML is loaded over HTTPS.
- CORS issues: ensure backend sets correct CORS headers only if needed for web clients and not required for native app WebViews.

---

If you want, I can:

- Add a runnable example `create-checkout` endpoint in Node.js that shows how to call Moneris securely (I can implement this with your preferred Moneris SDK/HTTP method).
- Add CI/CD steps for building and releasing Flutter flavors to Google Play / App Store and deploying the backend with GitHub Actions.

Next: I'll mark the todo items as completed and run a quick format/validation. Let me know if you want the backend example implemented now.
