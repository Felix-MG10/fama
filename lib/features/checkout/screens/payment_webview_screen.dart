import 'dart:collection';
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
import 'package:stackfood_multivendor/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor/common/widgets/menu_drawer_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final OrderModel orderModel;
  final String paymentMethod;
  final String? addFundUrl;
  final String? subscriptionUrl;
  final String guestId;
  final String contactNumber;
  final int? restaurantId;
  final int? packageId;
  const PaymentWebViewScreen({
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

class PaymentScreenState extends State<PaymentWebViewScreen> {
  static const String _callbackPrefix = 'fama://stackfood.com/payment-callback';
  late String selectedUrl;
  bool _isLoading = true;
  bool _canRedirect = true;
  double? _maximumCodOrderAmount;
  PullToRefreshController? pullToRefreshController;
  InAppWebViewController? webViewController;

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
      _maximumCodOrderAmount = zoneData.maxCodOrderAmount;
    }

    selectedUrl = await _resolveCheckoutUrl(selectedUrl);

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

    pullToRefreshController =
        GetPlatform.isWeb ||
            ![
              TargetPlatform.iOS,
              TargetPlatform.android,
            ].contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS) {
                webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: await webViewController?.getUrl(),
                  ),
                );
              }
            },
          );
  }

  bool _isNullOrEmpty(String? value) =>
      value == null || value.isEmpty || value == 'null';

  bool _isOrderPaymentFlow() =>
      _isNullOrEmpty(widget.addFundUrl) &&
      _isNullOrEmpty(widget.subscriptionUrl);

  bool _isSubscriptionFlow() =>
      !_isNullOrEmpty(widget.subscriptionUrl) &&
      _isNullOrEmpty(widget.addFundUrl);

  bool _isOrangePaymentMethod() =>
      widget.paymentMethod.toLowerCase().contains('orange');

  Future<String> _resolveCheckoutUrl(String fallbackUrl) async {
    if (_isOrderPaymentFlow() && _isOrangePaymentMethod()) {
      final String? orangeCheckoutUrl = await _resolveOrangeCheckoutUrl();
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

  Future<String?> _resolveOrangeCheckoutUrl() async {
    final Uri uri = Uri.parse(
      '${AppConstants.baseUrl}/api/v1/payment/orange-money',
    );

    final Map<String, dynamic> payload = {
      'order_id': widget.orderModel.id.toString(),
      'amount': widget.orderModel.orderAmount ?? 0,
      'callback_url': 'fama://stackfood.com/payment-callback',
    };

    try {
      final http.Response response = await http.post(
        uri,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final dynamic body = jsonDecode(response.body);
      if (body is Map &&
          body['status']?.toString().toLowerCase() != 'success') {
        return null;
      }
      return _extractCheckoutUrlFromBody(body);
    } catch (_) {
      return null;
    }
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
        _exitApp();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: CustomAppBarWidget(title: '', onBackPressed: () => _exitApp()),
        endDrawer: const MenuDrawerWidget(),
        endDrawerEnableOpenDragGesture: false,
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(selectedUrl)),
              initialUserScripts: UnmodifiableListView<UserScript>([]),
              pullToRefreshController: pullToRefreshController,
              initialSettings: InAppWebViewSettings(
                userAgent:
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.97 Safari/537.36',
                useHybridComposition: true,
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) async {
                webViewController = controller;
              },
              onLoadStart: (controller, url) async {
                setState(() {
                  _isLoading = true;
                });
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final Uri? uri = navigationAction.request.url;
                if (uri == null) {
                  return NavigationActionPolicy.CANCEL;
                }

                if (_isWaveHttpUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  return NavigationActionPolicy.CANCEL;
                }

                if (_isClientPaymentCallback(uri)) {
                  _redirect(
                    uri.toString(),
                    widget.contactNumber,
                    widget.restaurantId,
                    widget.packageId,
                  );
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
              },
              onLoadStop: (controller, url) async {
                pullToRefreshController?.endRefreshing();
                setState(() {
                  _isLoading = false;
                });
                _redirect(
                  url.toString(),
                  widget.contactNumber,
                  widget.restaurantId,
                  widget.packageId,
                );
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  pullToRefreshController?.endRefreshing();
                }
                // setState(() {
                //   _value = progress / 100;
                // });
              },
              onConsoleMessage: (controller, consoleMessage) {
                debugPrint(consoleMessage.message);
              },
            ),
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
    );
  }

  Future<bool?> _exitApp() async {
    ///ToDO: need implement for subscription-----
    if (_isOrderPaymentFlow() ||
        !Get.find<SplashController>()
            .configModel!
            .digitalPaymentInfo!
            .pluginPaymentGateways!) {
      return Get.dialog(
        PaymentFailedDialog(
          orderID: widget.orderModel.id.toString(),
          orderAmount: widget.orderModel.orderAmount,
          maxCodOrderAmount: _maximumCodOrderAmount,
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

  void _redirect(
    String url,
    String? contactNumber,
    int? restaurantId,
    int? packageId,
  ) {
    if (_canRedirect) {
      final PaymentRedirectResult result = _resolvePaymentStatus(
        url,
        forSubscription: _isSubscriptionFlow(),
      );
      if (result.status != PaymentResultStatus.none) {
        _canRedirect = false;
      }

      if (_isOrderPaymentFlow()) {
        if (result.status == PaymentResultStatus.success) {
          double total =
              ((widget.orderModel.orderAmount! / 100) *
              Get.find<SplashController>()
                  .configModel!
                  .loyaltyPointItemPurchasePoint!);
          Get.find<LoyaltyController>().saveEarningPoint(
            total.toStringAsFixed(0),
          );
          if (Get.isRegistered<OrderController>()) {
            Get.find<OrderController>().getRunningOrders(1, notify: false);
          }
          if (Get.isRegistered<CartController>()) {
            Get.find<CartController>().getCartDataOnline();
          }
          Get.offNamed(
            RouteHelper.getOrderSuccessRoute(
              widget.orderModel.id.toString(),
              'success',
              widget.orderModel.orderAmount,
              contactNumber,
              isDeliveryOrder: widget.orderModel.orderType == 'delivery',
            ),
          );
        } else if (result.status == PaymentResultStatus.fail ||
            result.status == PaymentResultStatus.cancel) {
          final String statusText = result.status == PaymentResultStatus.cancel
              ? 'cancel'
              : 'fail';
          if (Get.isRegistered<OrderController>()) {
            Get.find<OrderController>().getRunningOrders(1, notify: false);
          }
          Get.offNamed(
            RouteHelper.getOrderSuccessRoute(
              widget.orderModel.id.toString(),
              statusText,
              widget.orderModel.orderAmount,
              contactNumber,
              isDeliveryOrder: widget.orderModel.orderType == 'delivery',
            ),
          );
        }
      } else {
        if (result.status != PaymentResultStatus.none) {
          if (Get.currentRoute.contains(RouteHelper.payment)) {
            Get.back();
          }
          final String statusText = result.status == PaymentResultStatus.success
              ? 'success'
              : result.status == PaymentResultStatus.fail
              ? 'fail'
              : 'cancel';
          if (_isSubscriptionFlow()) {
            Get.find<DashboardController>()
                .saveRegistrationSuccessfulSharedPref(true);
            Get.find<DashboardController>()
                .saveIsRestaurantRegistrationSharedPref(true);
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
  }

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

    try {
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        return;
      }
    } catch (_) {}

    final String decoded = Uri.decodeFull(rawUrl);
    final int httpIndex = decoded.indexOf('http');
    if (httpIndex != -1) {
      final Uri? fallbackUri = Uri.tryParse(decoded.substring(httpIndex));
      if (fallbackUri != null) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } else {
      debugPrint('Cannot open external url scheme: $uri');
    }
  }

  bool _isClientPaymentCallback(Uri uri) =>
      uri.toString().startsWith(_callbackPrefix);
}

enum PaymentResultStatus { success, fail, cancel, none }

class PaymentRedirectResult {
  final PaymentResultStatus status;
  final String? token;
  const PaymentRedirectResult({required this.status, this.token});
}
