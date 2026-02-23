import 'dart:async';
import 'package:stackfood_multivendor/features/checkout/widgets/payment_failed_dialog.dart';
import 'package:stackfood_multivendor/features/order/controllers/order_controller.dart';
import 'package:stackfood_multivendor/features/dashboard/controllers/dashboard_controller.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/features/order/domain/models/order_model.dart';
import 'package:stackfood_multivendor/features/location/domain/models/zone_response_model.dart';
import 'package:stackfood_multivendor/features/loyalty/controllers/loyalty_controller.dart';
import 'package:stackfood_multivendor/features/wallet/widgets/fund_payment_dialog_widget.dart';
import 'package:stackfood_multivendor/helper/address_helper.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:stackfood_multivendor/util/app_constants.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/common/widgets/custom_app_bar_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor/common/widgets/menu_drawer_widget.dart';
import 'package:stackfood_multivendor/api/api_client.dart';
import 'package:stackfood_multivendor/helper/auth_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
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
  const PaymentScreen({super.key, required this.orderModel, required this.paymentMethod, this.addFundUrl, this.subscriptionUrl,
    required this.guestId, required this.contactNumber, this.restaurantId, this.packageId});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  late String selectedUrl;
  double value = 0.0;
  final bool _isLoading = true;
  PullToRefreshController? pullToRefreshController;
  late MyInAppBrowser browser;
  double? maxCodOrderAmount;

  /// Flux Wave / Orange Money : API puis WebView pour intercepter Fama:// après paiement
  bool _paymentApiLoading = true;
  bool _checkingOrderStatus = false;

  bool get _isOrderPayment => (widget.addFundUrl == null || widget.addFundUrl!.isEmpty) && (widget.subscriptionUrl == '' || widget.subscriptionUrl!.isEmpty);
  bool get _isWaveMethod => widget.paymentMethod.toLowerCase() == 'wave';
  bool get _isOrangeMoneyMethod => widget.paymentMethod.toLowerCase().replaceAll('-', '_') == 'orange_money';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if(_isOrderPayment) {
      final callbackUrl = Uri.encodeComponent('${AppConstants.baseUrl}/payment-success');
      selectedUrl = '${AppConstants.baseUrl}/payment-mobile?customer_id=${widget.orderModel.userId == 0 ? widget.guestId : widget.orderModel.userId}&order_id=${widget.orderModel.id}&payment_method=${widget.paymentMethod}&payment_platform=app&callback=$callbackUrl';
    } else if(widget.subscriptionUrl != '' && widget.subscriptionUrl!.isNotEmpty){
      selectedUrl = widget.subscriptionUrl!;
    } else {
      selectedUrl = widget.addFundUrl!;
    }
    _initData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_checkingOrderStatus &&
        _isOrderPayment && (_isWaveMethod || _isOrangeMoneyMethod)) {
      _checkingOrderStatus = true;
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (!mounted) {
          _checkingOrderStatus = false;
          return;
        }
        await _checkPaymentStatusAndRedirect();
        if (mounted) _checkingOrderStatus = false;
      });
    }
  }

  /// Fallback : quand l'utilisateur revient de Wave/Orange sans deep link, vérifier si la commande est payée.
  Future<void> _checkPaymentStatusAndRedirect() async {
    if (!mounted) return;
    try {
      final orderId = widget.orderModel.id.toString();
      await Get.find<OrderController>().trackOrder(orderId, null, false, contactNumber: widget.contactNumber);
      final trackModel = Get.find<OrderController>().trackModel;
      if (mounted && trackModel != null && trackModel.paymentStatus == 'paid') {
        final total = (widget.orderModel.orderAmount ?? 0) / 100 * (Get.find<SplashController>().configModel?.loyaltyPointItemPurchasePoint ?? 0);
        Get.find<LoyaltyController>().saveEarningPoint(total.toStringAsFixed(0));
        Get.offNamed(RouteHelper.getOrderSuccessRoute(orderId, 'success', widget.orderModel.orderAmount, widget.contactNumber, isDeliveryOrder: widget.orderModel.orderType == 'delivery'));
      }
    } catch (_) {}
  }

  Future<void> _initData() async {

    if(widget.addFundUrl == null || widget.addFundUrl!.isEmpty){
      ZoneData? zoneData;
      try {
        zoneData = AddressHelper.getAddressFromSharedPref()?.zoneData?.firstWhere((data) => data.id == widget.orderModel.restaurant!.zoneId);
      } catch (_) {}
      maxCodOrderAmount = zoneData?.maxCodOrderAmount;
    }

    browser = MyInAppBrowser(orderID: widget.orderModel.id.toString(), orderAmount: widget.orderModel.orderAmount, maxCodOrderAmount: maxCodOrderAmount, addFundUrl: widget.addFundUrl,
        subscriptionUrl: widget.subscriptionUrl, contactNumber: widget.contactNumber, restaurantId: widget.restaurantId, packageId: widget.packageId, isDeliveryOrder: widget.orderModel.orderType == 'delivery', isOrangeMoney: _isOrangeMoneyMethod);

    if (_isOrderPayment && (_isWaveMethod || _isOrangeMoneyMethod)) {
      final apiClient = Get.find<ApiClient>();
      final headers = Map<String, String>.from(apiClient.getHeader())..['Accept'] = 'application/json';
      try {
        if (_isOrangeMoneyMethod) {
          // Orange Money : POST /test-orange. callback_url = page backend vers laquelle Orange redirige après paiement.
          // Le backend doit rediriger vers fama://... ou vers /payment-success pour que l'app affiche OrderSuccessfulScreen.
          final amount = (widget.orderModel.orderAmount ?? 0).toInt();
          final callbackUrl = '${AppConstants.baseUrl}/payment-success?order_id=${widget.orderModel.id}';
          final body = {
            'order_id': widget.orderModel.id,
            'amount': amount,
            'callback_url': callbackUrl,
          };
          final response = await apiClient.postData(AppConstants.testOrangeBackendUri, body, headers: headers);
          final respBody = response.body;
          if (response.statusCode == 200 && respBody != null) {
            final isSuccess = respBody['status'] == 'success' || respBody['success'] == true;
            if (isSuccess) {
              // Réponse /test-orange : payment_url ou short_link à la racine OU dans orange_response
              String? paymentUrl = respBody['payment_url'] as String? ?? respBody['short_link'] as String?;
              if (paymentUrl == null || paymentUrl.isEmpty) {
                final orangeResp = respBody['orange_response'];
                paymentUrl = orangeResp?['payment_url'] as String? ?? orangeResp?['short_link'] as String?;
              }
              if (paymentUrl != null && paymentUrl.isNotEmpty) {
                if (mounted) setState(() => _paymentApiLoading = false);
                selectedUrl = paymentUrl;
              } else {
                if (mounted) setState(() => _paymentApiLoading = false);
              }
            } else {
              final msg = respBody['message'] as String? ?? 'orange_money_temporarily_unavailable'.tr;
              if (mounted) {
                setState(() => _paymentApiLoading = false);
                showCustomSnackBar((msg != null && msg.isNotEmpty) ? msg : 'orange_money_temporarily_unavailable'.tr);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Get.back();
                });
              }
              return;
            }
          } else {
            final msg = respBody?['message'] as String?;
            if (mounted) {
              setState(() => _paymentApiLoading = false);
              showCustomSnackBar((msg != null && msg.isNotEmpty) ? msg : 'orange_money_temporarily_unavailable'.tr);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Get.back();
              });
            }
            return;
          }
        } else {
          // Wave : flux en 2 étapes (payment-mobile puis wave/pay)
          final customerId = widget.orderModel.userId == 0 ? AuthHelper.getGuestId() : widget.orderModel.userId.toString();
          final callbackUrl = Uri.encodeComponent('${AppConstants.baseUrl}/payment-success');
          final step1Uri = '${AppConstants.paymentMobileUri}?order_id=${widget.orderModel.id}&customer_id=$customerId&payment_method=${widget.paymentMethod}&payment_platform=app&callback=$callbackUrl';
          final step1Response = await apiClient.getData(step1Uri, headers: headers, showToaster: false);
          String? paymentId;
          if (step1Response.statusCode == 200 && step1Response.body != null) {
            final body = step1Response.body;
            paymentId = body['data']?['payment_id'] ?? body['payment_id'];
          }
          if (paymentId == null || paymentId.isEmpty) {
            if (mounted) setState(() => _paymentApiLoading = false);
          } else {
            final step2Uri = '${AppConstants.wavePayUri}?payment_id=${Uri.encodeComponent(paymentId)}&payment_platform=app';
            final step2Response = await apiClient.getData(step2Uri, headers: headers, showToaster: false);
            final step2Body = step2Response.body;
            if (step2Response.statusCode == 200 && step2Body != null && step2Body['status'] == 'success') {
              final data = step2Body['data'];
              final checkoutUrl = data?['checkout_url'] as String? ?? data?['payment_url'] as String?;
              if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
                if (mounted) setState(() => _paymentApiLoading = false);
                selectedUrl = checkoutUrl;
              } else {
                if (mounted) setState(() => _paymentApiLoading = false);
              }
            } else if (step2Body != null && step2Body['status'] == 'error') {
              final msg = step2Body['message'] as String? ?? '';
              if (mounted) {
                setState(() => _paymentApiLoading = false);
                showCustomSnackBar((msg != null && msg.isNotEmpty) ? msg : 'orange_money_temporarily_unavailable'.tr);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Get.back();
                });
              }
              return;
            } else {
              if (mounted) setState(() => _paymentApiLoading = false);
            }
          }
        }
      } catch (_) {
        if (mounted) setState(() => _paymentApiLoading = false);
      }
    }

    if(!GetPlatform.isIOS) {
        await InAppWebViewController.setWebContentsDebuggingEnabled(true);
        bool swAvailable = await WebViewFeature.isFeatureSupported(WebViewFeature.SERVICE_WORKER_BASIC_USAGE);
        bool swInterceptAvailable = await WebViewFeature.isFeatureSupported(WebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);
        if (swAvailable && swInterceptAvailable) {
          ServiceWorkerController serviceWorkerController = ServiceWorkerController.instance();
          await serviceWorkerController.setServiceWorkerClient(ServiceWorkerClient(
            shouldInterceptRequest: (request) async => null,
          ));
        }
      }
      await browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri(selectedUrl)),
        settings: InAppBrowserClassSettings(
          webViewSettings: InAppWebViewSettings(useShouldOverrideUrlLoading: true, useOnLoadResource: true),
          browserSettings: InAppBrowserSettings(hideUrlBar: true, hideToolbarTop: GetPlatform.isAndroid),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (didPop, result) async{
        _exitApp().then((value) => value!);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: CustomAppBarWidget(title: 'payment'.tr, onBackPressed: () => _exitApp()),
        endDrawer: const MenuDrawerWidget(), endDrawerEnableOpenDragGesture: false,
        body: Center(
          child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: _paymentApiLoading && _isOrderPayment && (_isWaveMethod || _isOrangeMoneyMethod)
                ? Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
                  )
                : _isLoading
                    ? Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
                      )
                    : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Future<bool?> _exitApp() async {
    if (kDebugMode) {
      print('---------- : ${widget.orderModel.orderStatus} / ${widget.orderModel.paymentMethod}/ ${widget.orderModel.id}');
      print('---check------- : ${widget.addFundUrl == null} && ${widget.addFundUrl!.isEmpty} && ${widget.subscriptionUrl == ''} && ${widget.subscriptionUrl!.isEmpty}');
    }
    if((widget.addFundUrl == null || widget.addFundUrl!.isEmpty) && widget.subscriptionUrl == '' && widget.subscriptionUrl!.isEmpty){
      return Get.dialog(PaymentFailedDialog(orderID: widget.orderModel.id.toString(), orderAmount: widget.orderModel.orderAmount, maxCodOrderAmount: maxCodOrderAmount, contactPersonNumber: widget.contactNumber));
    } else {
      return Get.dialog(FundPaymentDialogWidget(isSubscription: widget.subscriptionUrl != null && widget.subscriptionUrl!.isNotEmpty));
    }
  }

}

class MyInAppBrowser extends InAppBrowser {
  final String orderID;
  final double? orderAmount;
  final double? maxCodOrderAmount;
  final String? addFundUrl;
  final String? subscriptionUrl;
  final String? contactNumber;
  final int? restaurantId;
  final int? packageId;
  final bool isDeliveryOrder;
  final bool isOrangeMoney;
  MyInAppBrowser({required this.orderID, required this.orderAmount, required this.maxCodOrderAmount, this.contactNumber, super.windowId,
    super.initialUserScripts, this.addFundUrl, this.subscriptionUrl, this.restaurantId, this.packageId, this.isDeliveryOrder = false, this.isOrangeMoney = false});

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
    _redirect(url.toString(), contactNumber, restaurantId, packageId);
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
    if(_canRedirect) {
      // Get.dialog(PaymentFailedDialog(orderID: orderID, orderAmount: orderAmount, maxCodOrderAmount: maxCodOrderAmount));
      if((addFundUrl == null || addFundUrl!.isEmpty) && subscriptionUrl == '' && subscriptionUrl!.isEmpty){
        Get.dialog(PaymentFailedDialog(orderID: orderID, orderAmount: orderAmount, maxCodOrderAmount: maxCodOrderAmount, contactPersonNumber: contactNumber,));
      } else {
        Get.dialog(FundPaymentDialogWidget(isSubscription: subscriptionUrl != null && subscriptionUrl!.isNotEmpty));
      }
    }
    if (kDebugMode) {
      print("\n\nBrowser closed!\n\n");
    }
  }

  @override
  Future<NavigationActionPolicy> shouldOverrideUrlLoading(navigationAction) async {
    final url = navigationAction.request.url?.toString() ?? '';
    if (kDebugMode) {
      print("\n\nOverride $url\n\n");
    }
    // Intercepter le deep link Fama:// après redirection backend (Wave paie → backend → Fama://)
    if (url.toLowerCase().contains('fama://') && url.contains('payment-callback')) {
      _handleFamaPaymentCallback(url);
      return NavigationActionPolicy.CANCEL;
    }
    // Ouvrir l'app Wave ou le navigateur pour finaliser le paiement.
    // Le retour se fait via Fama:// capté par app_links (main.dart) quand l'app revient au premier plan.
    if (url.contains('wave://')) {
      final waveUri = Uri.tryParse(url);
      String? fallbackHttps;
      if (url.contains('wave://capture/https://') || url.contains('wave://capture/http://')) {
        final match = RegExp(r'wave://capture/(https?://[^\s]+)').firstMatch(url);
        if (match != null) fallbackHttps = match.group(1)!.trim();
      }
      bool launched = false;
      if (waveUri != null) {
        try {
          launched = await launchUrl(waveUri, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
      if (!launched && fallbackHttps != null) {
        try {
          final httpsUri = Uri.tryParse(fallbackHttps);
          if (httpsUri != null) {
            launched = await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }
      if (launched) {
        _canRedirect = false;
        close();
      }
      return NavigationActionPolicy.CANCEL;
    }
    // Orange Money : ouvrir l'app Orange Money en externe SANS fermer la WebView.
    // sameaosnapp:/mp/xxx peut afficher "page introuvable" → essayer d'abord l'URL HTTPS complète.
    if (isOrangeMoney && _isOrangeMoneyUrl(url)) {
      final pathMatch = RegExp(r'sameaosnapp:/+(mp/[a-zA-Z0-9_-]+)', caseSensitive: false).firstMatch(url);
      final httpsUrl = pathMatch != null
          ? 'https://sugu.orange-sonatel.com/${pathMatch.group(1)}'
          : null;
      bool launched = false;
      if (httpsUrl != null) {
        try {
          launched = await launchUrl(Uri.parse(httpsUrl), mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
      if (!launched) {
        final normalizedUrl = _normalizeOrangeMoneyUrl(url);
        final omUri = Uri.tryParse(normalizedUrl);
        if (omUri != null) {
          try {
            await launchUrl(omUri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }
      }
      return NavigationActionPolicy.CANCEL;
    }
    // Orange Money : intercepter payment-success/fail/cancel pour rediriger vers OrderSuccessfulScreen.
    // (Wave géré par le bloc suivant)
    if (isOrangeMoney && (url.contains('payment-success') || url.contains('payment-cancel') || url.contains('payment-fail'))) {
      _redirect(url, contactNumber, restaurantId, packageId);
      return NavigationActionPolicy.CANCEL;
    }
    // Autres paiements : intercepter les callbacks
    if (url.contains('payment-success') || url.contains('payment-fail') || url.contains('payment.wave.callback')) {
      _redirect(url, contactNumber, restaurantId, packageId);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  void _handleFamaPaymentCallback(String url) {
    if (!_canRedirect) return;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      final parsedOrderId = uri.queryParameters['order_id'];
      final status = uri.queryParameters['status']?.toLowerCase();
      if (parsedOrderId == null || parsedOrderId.isEmpty || status == null || status.isEmpty) return;
      _canRedirect = false;
      close();
      if ((addFundUrl == null || addFundUrl!.isEmpty) && (subscriptionUrl == null || subscriptionUrl!.isEmpty)) {
        final isSuccess = status == 'success';
        final isFailed = status == 'fail' || status == 'failed';
        final isCancel = status == 'cancel' || status == 'cancelled';
        _orderPaymentDoneDecision(isSuccess, isFailed, isCancel, orderIdFromUrl: parsedOrderId);
      }
    } catch (_) {}
  }

  /// Domaines autorisés pour les paiements (SSL) : backend + Orange Money (om.orange.sn), Wave, etc.
  static const List<String> _paymentAllowedHosts = [
    'aliceblue-herring-852976.hostingersite.com',
    'om.orange.sn', 'orange.com', 'api.orange.com', 'api.orange-sonatel.com', 'sugu.orange-sonatel.com', 'orange.sn',
    'wave.com', 'api.wave.com',
  ];

  static bool _isPaymentAllowedHost(String host) {
    if (host.isEmpty) return false;
    final mainHost = Uri.tryParse(AppConstants.webHostedUrl)?.host ?? '';
    if (host == mainHost) return true;
    return _paymentAllowedHosts.any((h) => host == h || host.endsWith('.$h'));
  }

  /// Contournement temporaire : certificat SSL du serveur (Hostinger) non reconnu par Android.
  /// Autorise aussi les domaines de paiement (Orange Money, Wave) pour les redirections.
  @override
  Future<ServerTrustAuthResponse?>? onReceivedServerTrustAuthRequest(URLAuthenticationChallenge challenge) async {
    final host = challenge.protectionSpace.host;
    if (_isPaymentAllowedHost(host)) {
      return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
    }
    return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.CANCEL);
  }

  @override
  void onLoadResource(resource) {
    if (kDebugMode) {
      print("Started at: ${resource.startTime}ms ---> duration: ${resource.duration}ms ${resource.url ?? ''}");
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

  /// Détecte les URLs qui ouvrent l'app Orange Money / Maxit (schémas courants).
  /// Orange peut renvoyer sameaosnapp:/mp/xxx (un seul slash) ou sameaosnapp://mp/xxx.
  static bool _isOrangeMoneyUrl(String url) {
    final lower = url.toLowerCase();
    return lower.startsWith('orange-money:') ||
        lower.startsWith('orange_money:') ||
        lower.startsWith('orangemoney:') ||
        lower.startsWith('om:') ||
        lower.startsWith('sameaosnapp:');
  }

  /// Normalise une URL Orange Money (ex. sameaosnapp:/mp/xxx → sameaosnapp://mp/xxx) pour url_launcher.
  static String _normalizeOrangeMoneyUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.startsWith('sameaosnapp:/') && !lower.startsWith('sameaosnapp://')) {
      return url.replaceFirst('sameaosnapp:/', 'sameaosnapp://');
    }
    if (lower.startsWith('om:/') && !lower.startsWith('om://')) {
      return url.replaceFirst(RegExp(r'om:/', caseSensitive: false), 'om://');
    }
    return url;
  }

  static bool _isWaveCallbackSuccess(String url) {
    if (!url.contains('payment.wave.callback')) return false;
    final status = Uri.tryParse(url)?.queryParameters['status'];
    return status?.toLowerCase() == 'success';
  }

  static bool _isWaveCallbackFail(String url) {
    if (!url.contains('payment.wave.callback')) return false;
    final status = Uri.tryParse(url)?.queryParameters['status'];
    return status?.toLowerCase() == 'fail' || status?.toLowerCase() == 'failed';
  }

  void _redirect(String url, String? contactNumber, int? restaurantId, int? packageId) {
    bool forSubscription = (subscriptionUrl != null && subscriptionUrl!.isNotEmpty && addFundUrl == '' && addFundUrl!.isEmpty);

    if(_canRedirect) {
      bool isSuccess = forSubscription ? url.startsWith('${AppConstants.baseUrl}/subscription-success')
          : url.startsWith('${AppConstants.baseUrl}/payment-success') || url.contains('payment-success') || _isWaveCallbackSuccess(url);
      bool isFailed = forSubscription ? url.startsWith('${AppConstants.baseUrl}/subscription-fail')
          : url.startsWith('${AppConstants.baseUrl}/payment-fail') || url.contains('payment-fail') || _isWaveCallbackFail(url);
      bool isCancel = forSubscription ? url.startsWith('${AppConstants.baseUrl}/subscription-cancel')
          : url.startsWith('${AppConstants.baseUrl}/payment-cancel') || url.contains('payment-cancel');
      if (isSuccess || isFailed || isCancel) {
        _canRedirect = false;
        close();
      }

      if((addFundUrl == '' && addFundUrl!.isEmpty && subscriptionUrl == '' && subscriptionUrl!.isEmpty)){
        _orderPaymentDoneDecision(isSuccess, isFailed, isCancel);
      } else{
        _decideSubscriptionOrWallet(isSuccess, isFailed, isCancel, restaurantId, packageId);
      }
    }
  }

  void _orderPaymentDoneDecision(bool isSuccess, bool isFailed, bool isCancel, {String? orderIdFromUrl}) {
    final oid = orderIdFromUrl ?? orderID;
    if (isSuccess) {
      double total = ((orderAmount! / 100) * Get.find<SplashController>().configModel!.loyaltyPointItemPurchasePoint!);
      Get.find<LoyaltyController>().saveEarningPoint(total.toStringAsFixed(0));
      Get.offNamed(RouteHelper.getOrderSuccessRoute(oid, 'success', orderAmount, contactNumber, isDeliveryOrder: isDeliveryOrder));
    } else if (isFailed || isCancel) {
      Get.offNamed(RouteHelper.getOrderSuccessRoute(oid, 'fail', orderAmount, contactNumber, isDeliveryOrder: isDeliveryOrder));
    }
  }

  void _decideSubscriptionOrWallet(bool isSuccess, bool isFailed, bool isCancel, int? restaurantId, int? packageId) {
    if(isSuccess || isFailed || isCancel) {
      if(Get.currentRoute.contains(RouteHelper.payment)) {
        Get.back();
      }
      if(subscriptionUrl != null && subscriptionUrl!.isNotEmpty && addFundUrl == '' && addFundUrl!.isEmpty) {
        Get.find<DashboardController>().saveRegistrationSuccessfulSharedPref(true);
        Get.find<DashboardController>().saveIsRestaurantRegistrationSharedPref(true);
        Get.offAllNamed(RouteHelper.getSubscriptionSuccessRoute(
          status: isSuccess ? 'success' : isFailed ? 'fail' : 'cancel',
          fromSubscription: true, restaurantId: restaurantId, packageId: packageId,
        ));
      } else {
        Get.back();
        Get.offAllNamed(RouteHelper.getWalletRoute(fundStatus: isSuccess ? 'success' : isFailed ? 'fail' : 'cancel', /*token: UniqueKey().toString()*/));
      }
    }
  }

}