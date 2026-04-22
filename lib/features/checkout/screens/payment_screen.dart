import 'dart:async';
import 'dart:convert';
import 'package:stackfood_multivendor/features/checkout/widgets/payment_failed_dialog.dart';
import 'package:stackfood_multivendor/features/cart/controllers/cart_controller.dart';
import 'package:stackfood_multivendor/features/dashboard/controllers/dashboard_controller.dart';
import 'package:stackfood_multivendor/features/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/features/order/domain/models/order_model.dart';
import 'package:stackfood_multivendor/features/location/domain/models/zone_response_model.dart';
import 'package:stackfood_multivendor/features/loyalty/controllers/loyalty_controller.dart';
import 'package:stackfood_multivendor/features/wallet/controllers/wallet_controller.dart';
import 'package:stackfood_multivendor/features/wallet/widgets/fund_payment_dialog_widget.dart';
import 'package:stackfood_multivendor/helper/address_helper.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:stackfood_multivendor/util/app_constants.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor/common/widgets/menu_drawer_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget {
  final OrderModel orderModel;
  final String paymentMethod;
  final String? addFundUrl;
  final String? subscriptionUrl;
  final String guestId;
  final String contactNumber;
  final int? restaurantId;
  final int? packageId;
  const PaymentScreen({
    super.key,
    required this.orderModel,
    required this.paymentMethod,
    this.addFundUrl,
    this.subscriptionUrl,
    required this.guestId,
    required this.contactNumber,
    this.restaurantId,
    this.packageId,
  });

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  late String selectedUrl;
  double value = 0.0;
  bool _isLoading = true;
  PullToRefreshController? pullToRefreshController;
  late MyInAppBrowser browser;
  double? maxCodOrderAmount;

  @override
  void initState() {
    super.initState();

    if (_isOrderPaymentFlow()) {
      selectedUrl =
          '${AppConstants.baseUrl}/payment-mobile?customer_id=${widget.orderModel.userId == 0 ? widget.guestId : widget.orderModel.userId}&order_id=${widget.orderModel.id}&payment_method=${widget.paymentMethod}';
    } else if (!_isNullOrEmpty(widget.subscriptionUrl)) {
      selectedUrl = widget.subscriptionUrl!;
    } else {
      selectedUrl = widget.addFundUrl!;
    }
    _initData();
  }

  void _initData() async {
    if (_isOrderPaymentFlow()) {
      ZoneData zoneData = AddressHelper.getAddressFromSharedPref()!.zoneData!
          .firstWhere(
            (data) => data.id == widget.orderModel.restaurant!.zoneId,
          );
      maxCodOrderAmount = zoneData.maxCodOrderAmount;
    }

    selectedUrl = await _resolveCheckoutUrl(selectedUrl);

    browser = MyInAppBrowser(
      orderID: widget.orderModel.id.toString(),
      orderAmount: widget.orderModel.orderAmount,
      maxCodOrderAmount: maxCodOrderAmount,
      addFundUrl: widget.addFundUrl,
      subscriptionUrl: widget.subscriptionUrl,
      contactNumber: widget.contactNumber,
      restaurantId: widget.restaurantId,
      packageId: widget.packageId,
      isDeliveryOrder: widget.orderModel.orderType == 'delivery',
    );

    if (!GetPlatform.isIOS) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(true);

      bool swAvailable = await WebViewFeature.isFeatureSupported(
        WebViewFeature.SERVICE_WORKER_BASIC_USAGE,
      );
      bool swInterceptAvailable = await WebViewFeature.isFeatureSupported(
        WebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST,
      );

      if (swAvailable && swInterceptAvailable) {
        ServiceWorkerController serviceWorkerController =
            ServiceWorkerController.instance();
        await serviceWorkerController.setServiceWorkerClient(
          ServiceWorkerClient(
            shouldInterceptRequest: (request) async {
              if (kDebugMode) {
                print(request);
              }
              return null;
            },
          ),
        );
      }
    }

    if (_shouldOpenWaveExternally(selectedUrl)) {
      final Uri? uri = Uri.tryParse(selectedUrl);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    await browser.openUrlRequest(
      urlRequest: URLRequest(url: WebUri(selectedUrl)),
      settings: InAppBrowserClassSettings(
        webViewSettings: InAppWebViewSettings(
          useShouldOverrideUrlLoading: true,
          useOnLoadResource: true,
        ),
        browserSettings: InAppBrowserSettings(
          hideUrlBar: true,
          hideToolbarTop: GetPlatform.isAndroid,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isNullOrEmpty(String? value) =>
      value == null || value.isEmpty || value == 'null';

  bool _isOrderPaymentFlow() =>
      _isNullOrEmpty(widget.addFundUrl) &&
      _isNullOrEmpty(widget.subscriptionUrl);

  bool _isOrangePaymentMethod() =>
      widget.paymentMethod.toLowerCase().contains('orange');

  Future<String> _resolveCheckoutUrl(String fallbackUrl) async {
    if (_isOrderPaymentFlow() && _isOrangePaymentMethod()) {
      final String orangeEndpointUrl =
          '${AppConstants.baseUrl}/payment/orange-money/pay?payment_id=${widget.orderModel.id}&payment_platform=app';
      final String? orangeCheckoutUrl = await _resolveFromJsonEndpoint(
        orangeEndpointUrl,
      );
      if (orangeCheckoutUrl != null) {
        return orangeCheckoutUrl;
      }
    }

    final String? resolvedFromFallbackEndpoint = await _resolveFromJsonEndpoint(
      fallbackUrl,
    );
    if (resolvedFromFallbackEndpoint != null) {
      return resolvedFromFallbackEndpoint;
    }
    return fallbackUrl;
  }

  Future<String?> _resolveFromJsonEndpoint(String endpointUrl) async {
    final Uri? uri = Uri.tryParse(endpointUrl);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }

    try {
      final http.Response response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic body = jsonDecode(response.body);
      final String? resolvedUrl = _extractCheckoutUrlFromBody(body);
      if (resolvedUrl == null || resolvedUrl.isEmpty) {
        return null;
      }

      // If backend returns an intermediate orange endpoint, resolve it once.
      if (resolvedUrl.contains('/payment/orange-money/pay')) {
        final String? nested = await _resolveFromJsonEndpoint(resolvedUrl);
        return nested ?? resolvedUrl;
      }
      return resolvedUrl;
    } catch (_) {
      return null;
    }
  }

  String? _extractCheckoutUrlFromBody(dynamic body) {
    if (body is String && body.startsWith('http')) {
      return body;
    }
    if (body is! Map) {
      return null;
    }

    final Map<String, dynamic> map = Map<String, dynamic>.from(body);
    final List<List<String>> paths = <List<String>>[
      ['data', 'checkout_url'],
      ['data', 'payment_url'],
      ['data', 'redirect_link'],
      ['data', 'url'],
      ['checkout_url'],
      ['payment_url'],
      ['redirect_link'],
      ['url'],
      ['short_link'],
      ['orange_response', 'payment_url'],
      ['orange_response', 'short_link'],
      ['raw_orange', 'checkout_url'],
      ['raw_orange', 'payment_url'],
    ];

    for (final List<String> path in paths) {
      final String? value = _readNestedString(map, path);
      if (value != null && value.startsWith('http')) {
        return value;
      }
    }
    return null;
  }

  String? _readNestedString(Map<String, dynamic> map, List<String> path) {
    dynamic current = map;
    for (final String key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else {
        return null;
      }
    }
    return current is String ? current : null;
  }

  bool _shouldOpenWaveExternally(String url) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return false;
    final String host = uri.host.toLowerCase();
    return host.contains('pay.wave.com') ||
        host.contains('qr.pay.wave.com') ||
        uri.scheme.toLowerCase() == 'wave';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async {
        _exitApp().then((value) => value!);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: CustomAppBarWidget(
          title: 'payment'.tr,
          onBackPressed: () => _exitApp(),
        ),
        endDrawer: const MenuDrawerWidget(),
        endDrawerEnableOpenDragGesture: false,
        body: Center(
          child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: Stack(
              children: [
                _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _exitApp() async {
    if (kDebugMode) {
      print(
        '---------- : ${widget.orderModel.orderStatus} / ${widget.orderModel.paymentMethod}/ ${widget.orderModel.id}',
      );
      print(
        '---check------- : ${widget.addFundUrl == null} && ${widget.addFundUrl!.isEmpty} && ${widget.subscriptionUrl == ''} && ${widget.subscriptionUrl!.isEmpty}',
      );
    }
    if (_isOrderPaymentFlow()) {
      return Get.dialog(
        PaymentFailedDialog(
          orderID: widget.orderModel.id.toString(),
          orderAmount: widget.orderModel.orderAmount,
          maxCodOrderAmount: maxCodOrderAmount,
          contactPersonNumber: widget.contactNumber,
        ),
      );
    } else {
      return Get.dialog(
        FundPaymentDialogWidget(
          isSubscription:
              widget.subscriptionUrl != null &&
              widget.subscriptionUrl!.isNotEmpty,
        ),
      );
    }
  }
}

class MyInAppBrowser extends InAppBrowser {
  static const String _clientCallbackPrefix =
      'fama://stackfood.com/payment-callback';
  final String orderID;
  final double? orderAmount;
  final double? maxCodOrderAmount;
  final String? addFundUrl;
  final String? subscriptionUrl;
  final String? contactNumber;
  final int? restaurantId;
  final int? packageId;
  final bool isDeliveryOrder;
  MyInAppBrowser({
    required this.orderID,
    required this.orderAmount,
    required this.maxCodOrderAmount,
    this.contactNumber,
    super.windowId,
    super.initialUserScripts,
    this.addFundUrl,
    this.subscriptionUrl,
    this.restaurantId,
    this.packageId,
    this.isDeliveryOrder = false,
  });

  bool _canRedirect = true;

  @override
  Future onBrowserCreated() async {
    if (kDebugMode) {
      print("\n\nBrowser Created!\n\n");
    }
  }

  @override
  Future onLoadStart(url) async {
    if (kDebugMode) {
      print("\n\nStarted: $url\n\n");
    }
  }

  @override
  Future onLoadStop(url) async {
    pullToRefreshController?.endRefreshing();
    if (kDebugMode) {
      print("\n\nStopped: $url\n\n");
    }
    _redirect(url.toString(), contactNumber, restaurantId, packageId);
  }

  @override
  void onLoadError(url, code, message) {
    pullToRefreshController?.endRefreshing();
    if (kDebugMode) {
      print("Can't load [$url] Error: $message");
    }
  }

  @override
  void onProgressChanged(progress) {
    if (progress == 100) {
      pullToRefreshController?.endRefreshing();
    }
    if (kDebugMode) {
      print("Progress: $progress");
    }
  }

  @override
  void onExit() {
    if (_canRedirect) {
      // Get.dialog(PaymentFailedDialog(orderID: orderID, orderAmount: orderAmount, maxCodOrderAmount: maxCodOrderAmount));
      if ((addFundUrl == null || addFundUrl!.isEmpty) &&
          subscriptionUrl == '' &&
          subscriptionUrl!.isEmpty) {
        Get.dialog(
          PaymentFailedDialog(
            orderID: orderID,
            orderAmount: orderAmount,
            maxCodOrderAmount: maxCodOrderAmount,
            contactPersonNumber: contactNumber,
          ),
        );
      } else {
        Get.dialog(
          FundPaymentDialogWidget(
            isSubscription:
                subscriptionUrl != null && subscriptionUrl!.isNotEmpty,
          ),
        );
      }
    }
    if (kDebugMode) {
      print("\n\nBrowser closed!\n\n");
    }
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(
    navigationAction,
  ) async {
    if (kDebugMode) {
      print("\n\nOverride ${navigationAction.request.url}\n\n");
    }
    final Uri? uri = navigationAction.request.url;
    if (uri == null) {
      return NavigationActionPolicy.CANCEL;
    }

    if (_isWaveHttpUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return NavigationActionPolicy.CANCEL;
    }

    if (_isClientPaymentCallback(uri)) {
      _redirect(uri.toString(), contactNumber, restaurantId, packageId);
      return NavigationActionPolicy.CANCEL;
    }

    if (![
      "http",
      "https",
      "file",
      "chrome",
      "data",
      "javascript",
      "about",
    ].contains(uri.scheme)) {
      await _launchExternalForCustomScheme(uri);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  bool _isWaveHttpUrl(Uri uri) {
    final String host = uri.host.toLowerCase();
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        (host.contains('pay.wave.com') || host.contains('qr.pay.wave.com'));
  }

  Future<void> _launchExternalForCustomScheme(Uri uri) async {
    final String rawUrl = uri.toString();
    if (_isClientPaymentCallback(uri)) {
      return;
    }

    // Wave can return deep-links like:
    // wave://capture/https://pay.wave.com/...
    if (rawUrl.startsWith('wave://capture/')) {
      final String extracted = Uri.decodeFull(
        rawUrl.substring('wave://capture/'.length),
      );
      final Uri? extractedUri = Uri.tryParse(extracted);
      if (extractedUri != null) {
        await launchUrl(extractedUri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback if http URL is embedded in custom scheme payload.
    final String decoded = Uri.decodeFull(rawUrl);
    final int httpIndex = decoded.indexOf('http');
    if (httpIndex != -1) {
      final Uri? fallbackUri = Uri.tryParse(decoded.substring(httpIndex));
      if (fallbackUri != null) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  void onLoadResource(resource) {
    if (kDebugMode) {
      print(
        "Started at: ${resource.startTime}ms ---> duration: ${resource.duration}ms ${resource.url ?? ''}",
      );
    }
  }

  @override
  void onConsoleMessage(consoleMessage) {
    if (kDebugMode) {
      print("""
    console output:
      message: ${consoleMessage.message}
      messageLevel: ${consoleMessage.messageLevel.toValue()}
   """);
    }
  }

  void _redirect(
    String url,
    String? contactNumber,
    int? restaurantId,
    int? packageId,
  ) {
    final bool forOrder = _isOrderPaymentFlow();
    final bool forSubscription = _isSubscriptionFlow();

    if (_canRedirect) {
      final PaymentRedirectResult result = _resolvePaymentStatus(
        url,
        forSubscription: forSubscription,
      );
      if (result.status != PaymentResultStatus.none) {
        _canRedirect = false;
        close();
      }

      if (forOrder) {
        _orderPaymentDoneDecision(result.status);
      } else {
        _decideSubscriptionOrWallet(result.status, restaurantId, packageId);
      }
    }
  }

  bool _isNullOrEmpty(String? value) =>
      value == null || value.isEmpty || value == 'null';

  bool _isOrderPaymentFlow() =>
      _isNullOrEmpty(addFundUrl) && _isNullOrEmpty(subscriptionUrl);

  bool _isSubscriptionFlow() =>
      !_isNullOrEmpty(subscriptionUrl) && _isNullOrEmpty(addFundUrl);

  bool _isClientPaymentCallback(Uri uri) =>
      uri.toString().startsWith(_clientCallbackPrefix);

  PaymentRedirectResult _resolvePaymentStatus(
    String url, {
    required bool forSubscription,
  }) {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      return const PaymentRedirectResult(status: PaymentResultStatus.none);
    }

    final String? token = uri.queryParameters['token'];
    final String? queryFlag = _normalizedStatus(uri.queryParameters['flag']);
    final String? queryStatus = _normalizedStatus(
      uri.queryParameters['status'],
    );
    final String? resolvedFromQuery = queryFlag ?? queryStatus;

    if (resolvedFromQuery != null) {
      return PaymentRedirectResult(
        status: _mapStatus(resolvedFromQuery),
        token: token,
      );
    }

    final String path = uri.path.toLowerCase();
    if (_isClientPaymentCallback(uri)) {
      return PaymentRedirectResult(
        status: _mapStatus(queryStatus ?? 'fail'),
        token: token,
      );
    }
    final String successPath = forSubscription
        ? '/subscription-success'
        : '/payment-success';
    final String failPath = forSubscription
        ? '/subscription-fail'
        : '/payment-fail';
    final String cancelPath = forSubscription
        ? '/subscription-cancel'
        : '/payment-cancel';

    if (path.contains(successPath)) {
      return PaymentRedirectResult(
        status: PaymentResultStatus.success,
        token: token,
      );
    }
    if (path.contains(failPath)) {
      return PaymentRedirectResult(
        status: PaymentResultStatus.fail,
        token: token,
      );
    }
    if (path.contains(cancelPath)) {
      return PaymentRedirectResult(
        status: PaymentResultStatus.cancel,
        token: token,
      );
    }
    return const PaymentRedirectResult(status: PaymentResultStatus.none);
  }

  String? _normalizedStatus(String? rawStatus) {
    if (rawStatus == null || rawStatus.isEmpty) {
      return null;
    }
    return rawStatus.toLowerCase();
  }

  PaymentResultStatus _mapStatus(String status) {
    if (status == 'success' || status == 'succeeded' || status == 'paid') {
      return PaymentResultStatus.success;
    }
    if (status == 'fail' ||
        status == 'failed' ||
        status == 'failure' ||
        status == 'error') {
      return PaymentResultStatus.fail;
    }
    if (status == 'cancel' || status == 'canceled' || status == 'cancelled') {
      return PaymentResultStatus.cancel;
    }
    return PaymentResultStatus.none;
  }

  void _orderPaymentDoneDecision(PaymentResultStatus status) {
    if (status == PaymentResultStatus.success) {
      double total =
          ((orderAmount! / 100) *
          Get.find<SplashController>()
              .configModel!
              .loyaltyPointItemPurchasePoint!);
      Get.find<LoyaltyController>().saveEarningPoint(total.toStringAsFixed(0));
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().getRunningOrders(1, notify: false);
      }
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().getCartDataOnline();
      }
      Get.offNamed(
        RouteHelper.getOrderSuccessRoute(
          orderID,
          'success',
          orderAmount,
          contactNumber,
          isDeliveryOrder: isDeliveryOrder,
        ),
      );
    } else if (status == PaymentResultStatus.fail ||
        status == PaymentResultStatus.cancel) {
      final String statusText = status == PaymentResultStatus.cancel
          ? 'cancel'
          : 'fail';
      if (Get.isRegistered<OrderController>()) {
        Get.find<OrderController>().getRunningOrders(1, notify: false);
      }
      Get.offNamed(
        RouteHelper.getOrderSuccessRoute(
          orderID,
          statusText,
          orderAmount,
          contactNumber,
          isDeliveryOrder: isDeliveryOrder,
        ),
      );
    }
  }

  void _decideSubscriptionOrWallet(
    PaymentResultStatus status,
    int? restaurantId,
    int? packageId,
  ) {
    if (status != PaymentResultStatus.none) {
      if (Get.currentRoute.contains(RouteHelper.payment)) {
        Get.back();
      }
      final String statusText = status == PaymentResultStatus.success
          ? 'success'
          : status == PaymentResultStatus.fail
          ? 'fail'
          : 'cancel';
      if (_isSubscriptionFlow()) {
        Get.find<DashboardController>().saveRegistrationSuccessfulSharedPref(
          true,
        );
        Get.find<DashboardController>().saveIsRestaurantRegistrationSharedPref(
          true,
        );
        Get.offAllNamed(
          RouteHelper.getSubscriptionSuccessRoute(
            status: statusText,
            fromSubscription: true,
            restaurantId: restaurantId,
            packageId: packageId,
          ),
        );
      } else {
        if (Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().getWalletTransactionList(
            '1',
            true,
            'all',
          );
        }
        Get.back();
        Get.offAllNamed(RouteHelper.getWalletRoute(fundStatus: statusText));
      }
    }
  }
}

enum PaymentResultStatus { success, fail, cancel, none }

class PaymentRedirectResult {
  final PaymentResultStatus status;
  final String? token;
  const PaymentRedirectResult({required this.status, this.token});
}
