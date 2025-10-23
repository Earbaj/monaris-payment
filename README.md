2. Flutter App Production Updates
   Environment Configuration
   Create lib/config/environment.dart:

dart
abstract class Environment {
static const String baseUrl = String.fromEnvironment(
'BASE_URL',
defaultValue: 'http://10.0.2.2:5000', // Development
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
Updated Moneris Service (lib/services/moneris_service.dart)
dart
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
          // Add production-specific fields
          if (isProduction) ...{
            'email': 'customer@example.com', // Get from user profile
            'phone': '+1234567890',
          },
        }),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('✅ Checkout created in ${isProduction ? 'PRODUCTION' : 'TEST'} mode');
        return result;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Checkout error: $e');
      if (isProduction) {
        rethrow; // In production, don't use fallbacks
      } else {
        return _createFallbackCheckout(amount);
      }
    }
}

// Remove fallback methods for production or keep them conditionally
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

// Similar updates for verifyPayment and other methods...
}
Production WebView (lib/screens/checkout_webview.dart)
Update the HTML to use production Moneris JS:

dart
String _getCheckoutHTML(String ticket, double amount) {
final isProduction = Environment.isProduction;

return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Checkout</title>
    <!-- Production Moneris JS -->
    ${isProduction ? 
      '<script src="https://gateway.moneris.com/chkt/js/chkt_v1.00.js"></script>' : 
      '<script src="https://gatewayt.moneris.com/chkt/js/chkt_v1.00.js"></script>'
    }
    <style>
        /* Your existing styles */
    </style>
</head>
<body>
    <div class="container">
        <!-- Your existing HTML structure -->

        ${isProduction ? '''
        <!-- Production Moneris Checkout -->
        <div id="monerisCheckout"></div>
        <script>
            var myCheckout = new monerisCheckout();
            myCheckout.setMode("prod");
            myCheckout.setCheckoutDiv("monerisCheckout");
            
            // Set up callbacks
            myCheckout.setCallback("payment_receipt", function(response) {
                if (window.Flutter) {
                    window.Flutter.postMessage(JSON.stringify({
                        event: "payment_success",
                        data: response
                    }));
                }
            });
            
            myCheckout.setCallback("error_event", function(error) {
                if (window.Flutter) {
                    window.Flutter.postMessage(JSON.stringify({
                        event: "payment_error", 
                        data: error
                    }));
                }
            });
            
            // Start Moneris checkout
            myCheckout.startCheckout('$ticket');
        </script>
        ''' : '''
        <!-- Test payment form (your existing form) -->
        <div id="paymentForm">
            <!-- Your test form HTML -->
        </div>
        '''}
    </div>
</body>
</html>
''';
}
3. Deployment Setup
Backend Deployment (Heroku/ Railway/DigitalOcean)
Create Procfile:

text
web: node index.js
Update package.json scripts:

json
{
"scripts": {
"start": "node index.js",
"dev": "nodemon index.js",
"heroku-postbuild": "echo 'No build needed'"
},
"engines": {
"node": ">=18.0.0"
}
}
Flutter Build Configuration
Update android/app/build.gradle:

gradle
android {
defaultConfig {
applicationId "com.yourapp.moneris"
minSdkVersion 21
targetSdkVersion 34

        // Environment variables for different builds
        buildConfigField "String", "BASE_URL", '"https://your-production-api.com"'
        buildConfigField "boolean", "IS_PRODUCTION", "true"
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
        debug {
            applicationIdSuffix ".debug"
            buildConfigField "String", "BASE_URL", '"http://10.0.2.2:5000"'
            buildConfigField "boolean", "IS_PRODUCTION", "false"
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
4. Security & Compliance
   Add Security Headers (Backend)
   javascript
   // Security middleware
   app.use(helmet());
   app.use(rateLimit({
   windowMs: 15 * 60 * 1000, // 15 minutes
   max: 100 // limit each IP to 100 requests per windowMs
   }));

// HTTPS redirect (production only)
if (process.env.NODE_ENV === 'production') {
app.use((req, res, next) => {
if (req.header('x-forwarded-proto') !== 'https') {
res.redirect(`https://${req.header('host')}${req.url}`);
} else {
next();
}
});
}
PCI Compliance
Never store card details

Use Moneris tokens instead of raw card data

Implement proper logging

Regular security audits

5. Monitoring & Analytics
   Error Tracking
   Add Sentry or similar:

dart
// In main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
await SentryFlutter.init(
(options) {
options.dsn = 'https://your-sentry-dsn@o123456.ingest.sentry.io/1234567';
options.environment = Environment.isProduction ? 'production' : 'development';
},
appRunner: () => runApp(MyApp()),
);
}