import 'dart:async';
import 'package:app_links/app_links.dart';
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
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'helper/get_di.dart' as di;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/url_strategy.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Masquer temporairement les erreurs overflow dans la console
  RenderErrorBox.backgroundColor = Colors.transparent;
  RenderErrorBox.textStyle = ui.TextStyle(color: ui.Color(0x00000000));
  
  // Intercepter et ignorer les erreurs overflow
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('overflowed') || 
        details.exception.toString().contains('RenderFlex')) {
      // Ignorer silencieusement les erreurs overflow
      debugPrint('Overflow ignored: ${details.exception}');
      return;
    }
    // Afficher les autres erreurs normalement
    FlutterError.presentError(details);
  };
  
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
  String? paymentOrderId;
  String? paymentStatus;

  if (GetPlatform.isMobile && !ResponsiveHelper.isWeb()) {
    try {
      final appLinks = AppLinks();
      final uri = await appLinks.getInitialLink();
      final parsed = _parsePaymentCallbackUri(uri);
      if (parsed != null) {
        paymentOrderId = parsed.$1;
        paymentStatus = parsed.$2;
      }
      appLinks.uriLinkStream.listen((Uri u) {
        final p = _parsePaymentCallbackUri(u);
        if (p != null && Get.currentRoute.isNotEmpty) {
          final status = (p.$2.toLowerCase() == 'success') ? 'success' : 'fail';
          Get.offNamed(RouteHelper.getOrderSuccessRoute(p.$1, status, null, null, isDeliveryOrder: false));
        }
      });
    } catch (_) {}
  }

  if(GetPlatform.isWeb) {
    await Firebase.initializeApp(options: const FirebaseOptions(
      apiKey: "AIzaSyB7yN1-LVdNqMksmHj8gVEJLGtNvvD6c1U",
      authDomain: "fama-7db84.firebaseapp.com",
      projectId: "fama-7db84",
      storageBucket: "fama-7db84.firebasestorage.app",
      messagingSenderId: "888957940076",
      appId: "1:888957940076:web:e739d75fd1630e74ca8349",
    ));
  }else if(GetPlatform.isAndroid) {
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
  runApp(MyApp(languages: languages, body: body, linkBody: linkBody, paymentOrderId: paymentOrderId, paymentStatus: paymentStatus));
}

/// Parse un deep link paiement Wave : Fama://stackfood.com/payment-callback?status=success&order_id=123
(String, String)? _parsePaymentCallbackUri(Uri? uri) {
  if (uri == null || !uri.path.contains('payment-callback')) return null;
  final orderId = uri.queryParameters['order_id'];
  final status = uri.queryParameters['status'];
  if (orderId == null || orderId.isEmpty || status == null || status.isEmpty) return null;
  return (orderId, status);
}

class MyApp extends StatefulWidget {
  final Map<String, Map<String, String>>? languages;
  final NotificationBodyModel? body;
  final DeepLinkBody? linkBody;
  final String? paymentOrderId;
  final String? paymentStatus;
  const MyApp({super.key, required this.languages, required this.body, required this.linkBody, this.paymentOrderId, this.paymentStatus});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();

    _route();
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
            initialRoute: GetPlatform.isWeb ? RouteHelper.getInitialRoute() : RouteHelper.getSplashRoute(widget.body, widget.linkBody, paymentOrderId: widget.paymentOrderId, paymentStatus: widget.paymentStatus),
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