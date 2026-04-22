import 'dart:async';
import 'package:stackfood_multivendor/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor/features/cart/controllers/cart_controller.dart';
import 'package:stackfood_multivendor/features/language/controllers/localization_controller.dart';
import 'package:stackfood_multivendor/features/notification/domain/models/notification_body_model.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/features/splash/controllers/theme_controller.dart';
import 'package:stackfood_multivendor/features/favourite/controllers/favourite_controller.dart';
import 'package:stackfood_multivendor/features/splash/domain/models/deep_link_body.dart';
import 'package:stackfood_multivendor/helper/notification_helper.dart';
import 'package:stackfood_multivendor/helper/responsive_helper.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:stackfood_multivendor/theme/dark_theme.dart';
import 'package:stackfood_multivendor/theme/light_theme.dart';
import 'package:stackfood_multivendor/util/app_constants.dart';
import 'package:stackfood_multivendor/util/messages.dart';
import 'package:stackfood_multivendor/common/widgets/cookies_view_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:app_links/app_links.dart';
import 'helper/get_di.dart' as di;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // // Pass all uncaught "fatal" errors from the framework to Crashlytics
  // FlutterError.onError = (errorDetails) {
  //   FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  // };
  // // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  // PlatformDispatcher.instance.onError = (error, stack) {
  //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //   return true;
  // };

  DeepLinkBody? linkBody;

  // iOS is initialized natively in AppDelegate (FirebaseApp.configure()).
  // Avoid duplicate default-app initialization that causes a white screen.
  if (GetPlatform.isIOS) {
    // No-op on iOS: Firebase is already configured natively.
  } else if (Firebase.apps.isEmpty) {
    // Projet Firebase: fama-7db84 — Pour le web, ajouter une app Web dans la console Firebase et remplacer appId.
    if(GetPlatform.isWeb) {
      await Firebase.initializeApp(options: const FirebaseOptions(
        apiKey: "AIzaSyDKFPeONsJTzc9OcNRnexNCItpqVX41UhE",
        authDomain: "fama-7db84.firebaseapp.com",
        projectId: "fama-7db84",
        storageBucket: "fama-7db84.firebasestorage.app",
        messagingSenderId: "888957940076",
        appId: "1:888957940076:web:REPLACE_AFTER_ADDING_WEB_APP_IN_FIREBASE_CONSOLE",
      ));
    } else if(GetPlatform.isAndroid) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDKFPeONsJTzc9OcNRnexNCItpqVX41UhE',
          appId: '1:888957940076:android:3be42b0f67a1a5c3ca8349',
          messagingSenderId: '888957940076',
          projectId: 'fama-7db84',
          storageBucket: 'fama-7db84.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  }

  Map<String, Map<String, String>> languages = await di.init();

  NotificationBodyModel? body;
  try {
    if (GetPlatform.isMobile) {
      final RemoteMessage? remoteMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (remoteMessage != null) {
        body = NotificationHelper.convertNotification(remoteMessage.data);
      }
      await NotificationHelper.initialize(flutterLocalNotificationsPlugin);
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  }catch(_) {}

  if (ResponsiveHelper.isWeb()) {
    await FacebookAuth.instance.webAndDesktopInitialize(
      appId: "452131619626499",
      cookie: true,
      xfbml: true,
      version: "v13.0",
    );
  }
  runApp(MyApp(languages: languages, body: body, linkBody: linkBody));
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>>? languages;
  final NotificationBodyModel? body;
  final DeepLinkBody? linkBody;
  const MyApp({super.key, required this.languages, required this.body, required this.linkBody});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri?>? _uriLinkSubscription;
  AppLinks? _appLinks;

  @override
  void initState() {
    super.initState();

    _route();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _uriLinkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _route() async {
    if(GetPlatform.isWeb) {
      Get.find<SplashController>().initSharedData();
      if(!Get.find<AuthController>().isLoggedIn() && !Get.find<AuthController>().isGuestLoggedIn() /*&& !ResponsiveHelper.isDesktop(Get.context!)*/) {
        await Get.find<AuthController>().guestLogin();
      }
      if(Get.find<AuthController>().isLoggedIn() || Get.find<AuthController>().isGuestLoggedIn()) {
        Get.find<CartController>().getCartDataOnline();
      }
      Get.find<SplashController>().getConfigData(fromMainFunction: true);
      if (Get.find<AuthController>().isLoggedIn()) {
        Get.find<AuthController>().updateToken();
        await Get.find<FavouriteController>().getFavouriteList();
      }
    }
  }

  Future<void> _initDeepLinks() async {
    if (GetPlatform.isWeb) {
      return;
    }

    try {
      _appLinks ??= AppLinks();
      final Uri? initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleIncomingUri(initialUri);
      }
    } catch (_) {}

    _uriLinkSubscription = _appLinks!.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleIncomingUri(uri);
      }
    }, onError: (_) {});
  }

  void _handleIncomingUri(Uri uri) {
    final String? targetRoute = _resolvePaymentRouteFromUri(uri);
    if (targetRoute == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Get.offAllNamed(targetRoute);
    });
  }

  String? _resolvePaymentRouteFromUri(Uri uri) {
    final String path = uri.path.toLowerCase();
    final String host = uri.host.toLowerCase();
    final String scheme = uri.scheme.toLowerCase();

    final bool isCustomPaymentCallback = scheme == 'fama'
        && host == 'stackfood.com'
        && path.contains('/payment-callback');
    final bool isHttpsPaymentCallback =
        (scheme == 'https' && (host == 'fama' || host.contains('hostingersite.com')))
        && (path.contains('/payment-success')
            || path.contains('/payment-fail')
            || path.contains('/payment-cancel'));

    if (!isCustomPaymentCallback && !isHttpsPaymentCallback) {
      return null;
    }

    final String? status = _extractPaymentStatus(uri, path);
    final String? orderId = _extractOrderId(uri);

    if (status == null || orderId == null || orderId.isEmpty) {
      return null;
    }

    final double? amount = double.tryParse(uri.queryParameters['amount'] ?? '');
    final String? contactNumber = uri.queryParameters['contact_number'];
    final bool isDeliveryOrder = uri.queryParameters['is_delivery_order'] == 'true';

    return RouteHelper.getOrderSuccessRoute(
      orderId,
      status,
      amount,
      contactNumber,
      isDeliveryOrder: isDeliveryOrder,
    );
  }

  String? _extractPaymentStatus(Uri uri, String path) {
    final String? rawStatus = uri.queryParameters['flag'] ?? uri.queryParameters['status'];
    final String? normalized = _normalizeStatus(rawStatus);
    if (normalized != null) {
      return normalized;
    }

    if (path.contains('/payment-success')) {
      return 'success';
    }
    if (path.contains('/payment-fail')) {
      return 'fail';
    }
    if (path.contains('/payment-cancel')) {
      return 'cancel';
    }
    return null;
  }

  String? _extractOrderId(Uri uri) {
    final String? queryOrderId =
        uri.queryParameters['order_id'] ?? uri.queryParameters['id'] ?? uri.queryParameters['ref'];
    if (queryOrderId != null && queryOrderId.isNotEmpty) {
      return queryOrderId;
    }

    final List<String> segments = uri.pathSegments.where((String s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final String lastSegment = segments.last;
      if (!lastSegment.contains('payment-success')
          && !lastSegment.contains('payment-fail')
          && !lastSegment.contains('payment-cancel')) {
        return lastSegment;
      }
    }
    return null;
  }

  String? _normalizeStatus(String? status) {
    if (status == null || status.isEmpty) {
      return null;
    }
    final String value = status.toLowerCase();
    if (value == 'success' || value == 'succeeded' || value == 'paid') {
      return 'success';
    }
    if (value == 'fail' || value == 'failed' || value == 'failure' || value == 'error') {
      return 'fail';
    }
    if (value == 'cancel' || value == 'cancelled' || value == 'canceled') {
      return 'cancel';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {

    return GetBuilder<ThemeController>(builder: (themeController) {
      return GetBuilder<LocalizationController>(builder: (localizeController) {
        return GetBuilder<SplashController>(builder: (splashController) {
          return (GetPlatform.isWeb && splashController.configModel == null) ? const SizedBox() : GetMaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            navigatorKey: Get.key,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch},
            ),
            theme: themeController.darkTheme ? dark : light,
            locale: localizeController.locale,
            translations: Messages(languages: widget.languages),
            fallbackLocale: Locale(AppConstants.languages[0].languageCode!, AppConstants.languages[0].countryCode),
            initialRoute: GetPlatform.isWeb ? RouteHelper.getInitialRoute() : RouteHelper.getSplashRoute(widget.body, widget.linkBody),
            getPages: RouteHelper.routes,
            defaultTransition: Transition.topLevel,
            transitionDuration: const Duration(milliseconds: 500),
            builder: (BuildContext context, widget) {
              return MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)), child: Material(
                child: SafeArea(
                  top: false, bottom: GetPlatform.isAndroid,
                  child: Stack(children: [
                    widget!,

                    GetBuilder<SplashController>(builder: (splashController){

                      if(!splashController.savedCookiesData || !splashController.getAcceptCookiesStatus(splashController.configModel?.cookiesText ?? "")){
                        return ResponsiveHelper.isWeb() ? const Align(alignment: Alignment.bottomCenter, child: CookiesViewWidget()) : const SizedBox();
                      }else{
                        return const SizedBox();
                      }
                    })
                  ]),
                )),
              );
            }
          );
        });
      });
    });
  }
}