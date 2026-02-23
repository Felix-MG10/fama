
import 'package:get/get.dart';
import 'package:stackfood_multivendor/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor/features/favourite/controllers/favourite_controller.dart';
import 'package:stackfood_multivendor/features/location/controllers/location_controller.dart';
import 'package:stackfood_multivendor/features/notification/domain/models/notification_body_model.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/features/splash/domain/models/deep_link_body.dart';
import 'package:stackfood_multivendor/features/address/domain/models/address_model.dart';
import 'package:stackfood_multivendor/helper/address_helper.dart';
import 'package:stackfood_multivendor/helper/maintance_helper.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:stackfood_multivendor/util/app_constants.dart';

void route({required NotificationBodyModel? notificationBody, required DeepLinkBody? linkBody, String? paymentOrderId, String? paymentStatus}) {
  double? minimumVersion = _getMinimumVersion();
  bool needsUpdate = AppConstants.appVersion < minimumVersion;

  bool isInMaintenance = MaintenanceHelper.isMaintenanceEnable();
  if (needsUpdate || isInMaintenance) {
    Get.offNamed(RouteHelper.getUpdateRoute(needsUpdate));
  } else if(!GetPlatform.isWeb){
    _handleNavigation(notificationBody, linkBody, paymentOrderId, paymentStatus);
  } else if (GetPlatform.isWeb && Get.currentRoute.contains(RouteHelper.update) && !isInMaintenance) {
    Get.offNamed(RouteHelper.getInitialRoute());
  }
}

double _getMinimumVersion() {
  if (GetPlatform.isAndroid) {
    return Get.find<SplashController>().configModel!.appMinimumVersionAndroid!;
  } else if (GetPlatform.isIOS) {
    return Get.find<SplashController>().configModel!.appMinimumVersionIos!;
  } else {
    return 0;
  }
}

void _handleNavigation(NotificationBodyModel? notificationBody, DeepLinkBody? linkBody, [String? paymentOrderId, String? paymentStatus]) async {
  if (paymentOrderId != null && paymentOrderId.isNotEmpty) {
    final status = (paymentStatus?.toLowerCase() == 'success') ? 'success' : 'fail';
    Get.offNamed(RouteHelper.getOrderSuccessRoute(paymentOrderId, status, null, null, isDeliveryOrder: false));
  } else if (notificationBody != null && linkBody == null) {
    _forNotificationRouteProcess(notificationBody);
  } else if (Get.find<AuthController>().isLoggedIn()) {
    await _forLoggedInUserRouteProcess();
  } else if (Get.find<SplashController>().showIntro()!) {
    _newlyRegisteredRouteProcess();
  } else if (Get.find<AuthController>().isGuestLoggedIn()) {
    await _forGuestUserRouteProcess();
  } else {
    await Get.find<AuthController>().guestLogin();
    await _forGuestUserRouteProcess();
  }
}

void _forNotificationRouteProcess(NotificationBodyModel? notificationBody) {
  if(notificationBody!.notificationType == NotificationType.order) {
    Get.toNamed(RouteHelper.getOrderDetailsRoute(notificationBody.orderId, fromNotification: true));
  }else if(notificationBody.notificationType == NotificationType.message) {
    Get.toNamed(RouteHelper.getChatRoute(notificationBody: notificationBody, conversationID: notificationBody.conversationId, fromNotification: true));
  }else if(notificationBody.notificationType == NotificationType.block || notificationBody.notificationType == NotificationType.unblock){
    Get.toNamed(RouteHelper.getSignInRoute(RouteHelper.notification));
  }else if(notificationBody.notificationType == NotificationType.add_fund || notificationBody.notificationType == NotificationType.referral_earn || notificationBody.notificationType == NotificationType.CashBack){
    Get.toNamed(RouteHelper.getWalletRoute(fromNotification: true));
  }else{
    Get.toNamed(RouteHelper.getNotificationRoute(fromNotification: true));
  }
}

Future<void> _forLoggedInUserRouteProcess() async {
  Get.find<AuthController>().updateToken();
  await Get.find<FavouriteController>().getFavouriteList();
  if (AddressHelper.getAddressFromSharedPref() != null) {
    // Mettre à jour les zoneIds si l'adresse existe mais n'a pas de zoneIds
    AddressModel? address = AddressHelper.getAddressFromSharedPref();
    if (address != null && (address.zoneIds == null || address.zoneIds!.isEmpty)) {
      await Get.find<LocationController>().getZone(
        address.latitude,
        address.longitude,
        false,
        updateInAddress: true,
      );
    }
    Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true ));
  } else {
    Get.offNamed(RouteHelper.getAccessLocationRoute('splash'));
  }
}

void _newlyRegisteredRouteProcess() {
  if(AppConstants.languages.length > 1) {
    Get.offNamed(RouteHelper.getLanguageRoute('splash'));
  }else {
    Get.offNamed(RouteHelper.getOnBoardingRoute());
  }
}

Future<void> _forGuestUserRouteProcess() async {
  if (AddressHelper.getAddressFromSharedPref() != null) {
    // Mettre à jour les zoneIds si l'adresse existe mais n'a pas de zoneIds
    AddressModel? address = AddressHelper.getAddressFromSharedPref();
    if (address != null && (address.zoneIds == null || address.zoneIds!.isEmpty)) {
      await Get.find<LocationController>().getZone(
        address.latitude,
        address.longitude,
        false,
        updateInAddress: true,
      );
    }
    Get.offNamed(RouteHelper.getInitialRoute(fromSplash: true));
  } else {
    Get.find<SplashController>().navigateToLocationScreen('splash', offNamed: true);
  }
}