import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:stackfood_multivendor/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_drop_down_button.dart';
import 'package:stackfood_multivendor/common/widgets/custom_text_field_widget.dart';
import 'package:stackfood_multivendor/common/widgets/footer_view_widget.dart';
import 'package:stackfood_multivendor/common/widgets/validate_check.dart';
import 'package:stackfood_multivendor/common/widgets/web_screen_title_widget.dart';
import 'package:stackfood_multivendor/features/auth/widgets/trams_conditions_check_box_widget.dart';
import 'package:stackfood_multivendor/features/language/controllers/localization_controller.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/features/auth/controllers/deliveryman_registration_controller.dart';
import 'package:stackfood_multivendor/features/auth/widgets/deliveryman_additional_data_section_widget.dart';
import 'package:stackfood_multivendor/features/auth/widgets/pass_view_widget.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class DeliverymanRegistrationWebScreen extends StatefulWidget {
  final ScrollController scrollController;
  final TextEditingController fNameController;
  final TextEditingController lNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController identityNumberController;
  final FocusNode fNameNode;
  final FocusNode lNameNode;
  final FocusNode emailNode;
  final FocusNode phoneNode;
  final FocusNode passwordNode;
  final FocusNode confirmPasswordNode;
  final FocusNode identityNumberNode;
  final String? countryDialCode;
  final Widget buttonView;
  const DeliverymanRegistrationWebScreen({
    super.key, required this.scrollController, required this.fNameController, required this.lNameController, required this.emailController,
    required this.phoneController, required this.passwordController, required this.confirmPasswordController,
    required this.identityNumberController, required this.fNameNode, required this.lNameNode, required this.emailNode,
    required this.phoneNode, required this.passwordNode, required this.confirmPasswordNode, required this.identityNumberNode,
    this.countryDialCode, required this.buttonView,
  });

  @override
  State<DeliverymanRegistrationWebScreen> createState() => _DeliverymanRegistrationWebScreenState();
}

class _DeliverymanRegistrationWebScreenState extends State<DeliverymanRegistrationWebScreen> {
  String? _countryDialCode;
  @override
  void initState() {
    super.initState();
    _countryDialCode = _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DeliverymanRegistrationController>(builder: (deliverymanController) {
      return SingleChildScrollView(
        controller: widget.scrollController,
        child: FooterViewWidget(
          child: Center(
            child: Column(
              children: [
      
                WebScreenTitleWidget( title: 'join_as_a_delivery_man'.tr),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
      
                SizedBox(
                  width: Dimensions.webMaxWidth,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    const SizedBox(height: Dimensions.paddingSizeSmall),
      
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 1))],
                      ),
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge, bottom: Dimensions.paddingSizeExtraOverLarge),
                      child: Column(children: [
                        Text('delivery_man_registration'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
      
                        Text(
                          'complete_registration_process_to_serve_as_delivery_man_in_this_platform'.tr,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
      
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          child: Row(children: [
                            const Icon(Icons.person),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Text('delivery_man_information'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          ]),
                        ),
                        const Divider(),
      
                        Padding(
                          padding: const EdgeInsets.only(left: Dimensions.paddingSizeLarge, right: Dimensions.paddingSizeLarge, top: Dimensions.paddingSizeLarge),
                          child: Column(children: [
      
                            Row(children: [
      
                              Expanded(
                                child: Column(children: [
      
                                  Row(children: [
                                    Expanded(child: CustomTextFieldWidget(
                                      hintText: 'write_first_name'.tr,
                                      controller: widget.fNameController,
                                      capitalization: TextCapitalization.words,
                                      inputType: TextInputType.name,
                                      focusNode: widget.fNameNode,
                                      nextFocus: widget.lNameNode,
                                      prefixIcon: CupertinoIcons.person_alt_circle_fill,
                                      labelText: 'first_name'.tr,
                                      required: true,
                                      validator: (value) => ValidateCheck.validateEmptyText(value, "first_name_field_is_required".tr),
                                    )),
                                    const SizedBox(width: Dimensions.paddingSizeExtraOverLarge),
      
                                    Expanded(child: CustomTextFieldWidget(
                                      hintText: 'write_last_name'.tr,
                                      controller: widget.lNameController,
                                      capitalization: TextCapitalization.words,
                                      inputType: TextInputType.name,
                                      focusNode: widget.lNameNode,
                                      nextFocus: widget.phoneNode,
                                      prefixIcon: CupertinoIcons.person_alt_circle_fill,
                                      labelText: 'last_name'.tr,
                                      required: true,
                                      validator: (value) => ValidateCheck.validateEmptyText(value, "last_name_field_is_required".tr),
                                    )),
                                  ]),
                                  const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),
      
                                  Row(children: [
                                    Expanded(
                                      child: CustomTextFieldWidget(
                                        hintText: 'phone'.tr,
                                        controller: widget.phoneController,
                                        focusNode: widget.phoneNode,
                                        nextFocus: widget.emailNode,
                                        inputType: TextInputType.phone,
                                        isPhone: true,
                                        onCountryChanged: (CountryCode countryCode) {
                                          _countryDialCode = countryCode.dialCode;
                                        },
                                        countryDialCode: _countryDialCode != null ? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code
                                            : Get.find<LocalizationController>().locale.countryCode,
                                        labelText: 'phone'.tr,
                                        required: true,
                                        validator: (value) => ValidateCheck.validatePhone(value, null),
                                      ),
                                    ),
                                    const SizedBox(width: Dimensions.paddingSizeExtraOverLarge),
      
                                    Expanded(child:CustomTextFieldWidget(
                                      hintText: 'write_email'.tr,
                                      controller: widget.emailController,
                                      focusNode: widget.emailNode,
                                      nextFocus: widget.passwordNode,
                                      inputType: TextInputType.emailAddress,
                                      prefixIcon: CupertinoIcons.mail_solid,
                                      labelText: 'email'.tr,
                                      required: true,
                                      validator: (value) => ValidateCheck.validateEmail(value),
                                    )),
                                  ]),
                                  const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),
      
                                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Expanded(child: Column(children: [
                                      CustomTextFieldWidget(
                                        hintText: '8+characters'.tr,
                                        controller: widget.passwordController,
                                        focusNode: widget.passwordNode,
                                        nextFocus: widget.confirmPasswordNode,
                                        inputType: TextInputType.visiblePassword,
                                        isPassword: true,
                                        prefixIcon: Icons.lock,
                                        onChanged: (value){
                                          if(value != null && value.isNotEmpty){
                                            if(!deliverymanController.showPassView){
                                              deliverymanController.showHidePassView();
                                            }
                                            deliverymanController.validPassCheck(value);
                                          }else{
                                            if(deliverymanController.showPassView){
                                              deliverymanController.showHidePassView();
                                            }
                                          }
                                        },
                                        labelText: 'password'.tr,
                                        required: true,
                                        validator: (value) => ValidateCheck.validateEmptyText(value, "enter_password_for_delivery_man".tr),
                                      ),
      
                                      deliverymanController.showPassView ? const PassViewWidget() : const SizedBox(),
                                    ])),
                                    const SizedBox(width: Dimensions.paddingSizeExtraOverLarge),
      
                                    Expanded(child: CustomTextFieldWidget(
                                      hintText: '8+characters'.tr,
                                      controller: widget.confirmPasswordController,
                                      focusNode: widget.confirmPasswordNode,
                                      inputAction: TextInputAction.done,
                                      inputType: TextInputType.visiblePassword,
                                      prefixIcon: Icons.lock,
                                      isPassword: true,
                                      labelText: 'confirm_password'.tr,
                                      required: true,
                                      validator: (value) => ValidateCheck.validateConfirmPassword(value, widget.passwordController.text),
                                    ))
                                  ]),
      
                                ]),
                              ),
                              const SizedBox(width: 100),
      
                              Column(children: [
                                Text('identity_image'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),
                                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      
                                Align(alignment: Alignment.center, child: Stack(children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                    child: deliverymanController.pickedImage != null ? GetPlatform.isWeb ? Image.network(
                                      deliverymanController.pickedImage!.path, width: 180, height: 180, fit: BoxFit.cover,
                                    ) : Image.file(
                                      File(deliverymanController.pickedImage!.path), width: 180, height: 180, fit: BoxFit.cover,
                                    ) : SizedBox(
                                      width: 180, height: 180,
                                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      
                                        Icon(CupertinoIcons.camera_fill, size: 38, color: Theme.of(context).disabledColor.withValues(alpha: 0.7)),
                                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeOverLarge),
                                          child: Text(
                                            'upload_profile_picture'.tr,
                                            style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeExtraSmall), textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      
                                        Text(
                                          'upload_jpg_png_gif_maximum_2_mb'.tr,
                                          style: robotoRegular.copyWith(color: Theme.of(context).disabledColor.withValues(alpha: 0.6), fontSize: 10),
                                          textAlign: TextAlign.center,
                                        ),
      
                                      ]),
                                    ),
                                  ),
      
                                  Positioned(
                                    bottom: 0, right: 0, top: 0, left: 0,
                                    child: InkWell(
                                      onTap: () => deliverymanController.pickDmImage(true, false),
                                      child: DottedBorder(
                                        options: RoundedRectDottedBorderOptions(
                                          color: Theme.of(context).primaryColor,
                                          strokeWidth: 1,
                                          strokeCap: StrokeCap.butt,
                                          dashPattern: const [5, 5],
                                          padding: const EdgeInsets.all(0),
                                          radius: const Radius.circular(Dimensions.radiusDefault),
                                        ),
                                        child: Visibility(
                                          visible: deliverymanController.pickedImage != null,
                                          child: Center(
                                            child: Container(
                                              margin: const EdgeInsets.all(25),
                                              decoration: BoxDecoration(border: Border.all(width: 2, color: Colors.white), shape: BoxShape.circle,),
                                              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                                              child: const Icon(Icons.camera_alt, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ])),
                              ]),
                              const SizedBox(width: 80),
      
                            ]),
                          ]),
                        ),
      
                      ]),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
      
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 1))],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                      child: Column(children: [
      
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          child: Row(children: [
                            const Icon(Icons.person),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Text('required_info'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          ]),
                        ),
                        const Divider(),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
      
      
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          child: Column(children: [
      
                            Row(children: [
                              Expanded(child: Stack(clipBehavior: Clip.none, children: [
                                CustomDropdownButton(
                                  hintText: 'select_delivery_type'.tr,
                                  items: deliverymanController.dmTypeList,
                                  selectedValue: deliverymanController.selectedDmType,
                                  onChanged: (value) {
                                    deliverymanController.setSelectedDmType(value);
                                  },
                                ),
      
                                Positioned(
                                  left: 10, top: -10,
                                  child: Container(
                                    color: Theme.of(context).cardColor,
                                    padding: const EdgeInsets.all(2),
                                    child: Row(children: [
                                      Text('select_delivery_type'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                                      Text(' *', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error)),
                                    ]),
                                  ),
                                ),
                              ])),
                              const SizedBox(width: Dimensions.paddingSizeExtraOverLarge),
      
                              Expanded(child: deliverymanController.zoneList != null ? deliverymanController.zoneList!.isNotEmpty ? Stack(clipBehavior: Clip.none, children: [
                                CustomDropdownButton(
                                  hintText: 'select_delivery_zone'.tr,
                                  dropdownMenuItems: deliverymanController.zoneList!.map((zone) => DropdownMenuItem<String>(
                                    value: zone.id.toString(),
                                    child: Text(zone.name ?? '', style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeDefault)),
                                  )).toList(),
                                  selectedValue: deliverymanController.selectedDeliveryZoneId,
                                  onChanged: (value) {
                                    deliverymanController.setSelectedDeliveryZone(zoneId: value);
                                  },
                                ),

                                Positioned(
                                  left: 10, top: -10,
                                  child: Container(
                                    color: Theme.of(context).cardColor,
                                    padding: const EdgeInsets.all(2),
                                    child: Row(children: [
                                      Text('select_delivery_zone'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                                      Text(' *', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error)),
                                    ]),
                                  ),
                                ),
                              ]) : ClipRRect(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                child: Shimmer(
                                  child: Container(height: 50, color: Theme.of(context).shadowColor),
                                ),
                              ) : Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).shadowColor,
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                ),
                                height: 50,
                                child: Center(
                                  child: Text('no_zone_available'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
                                ),
                              )),
                              const SizedBox(width: Dimensions.paddingSizeExtraOverLarge),
      
                              Expanded(
                                child: deliverymanController.vehicles != null ? deliverymanController.vehicles!.isNotEmpty ? Stack(clipBehavior: Clip.none, children: [
                                  CustomDropdownButton(
                                    hintText: 'select_vehicle_type'.tr,
                                    dropdownMenuItems: deliverymanController.vehicles!.map((vehicle) => DropdownMenuItem<String>(
                                      value: vehicle.id.toString(),
                                      child: Text(vehicle.type ?? '', style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: Dimensions.fontSizeDefault)),
                                    )).toList(),
                                    selectedValue: deliverymanController.selectedVehicleId,
                                    onChanged: (value) {
                                      deliverymanController.setSelectedVehicleType(vehicleId: value);
                                    },
                                  ),

                                  Positioned(
                                    left: 10, top: -10,
                                    child: Container(
                                      color: Theme.of(context).cardColor,
                                      padding: const EdgeInsets.all(2),
                                      child: Row(children: [
                                        Text('select_vehicle_type'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                                        Text(' *', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error)),
                                      ]),
                                    ),
                                  ),
                                ]) : ClipRRect(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  child: Shimmer(
                                    child: Container(height: 50, color: Theme.of(context).shadowColor),
                                  ),
                                ) : Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).shadowColor,
                                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  ),
                                  height: 50,
                                  child: Center(
                                    child: Text('no_vehicle_available'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).hintColor)),
                                  ),
                                ),
                              ),
      
                            ]),
                            const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),
      
                            Row(children: [
      
                              Expanded(
                                child: Stack(clipBehavior: Clip.none, children: [
                                  CustomDropdownButton(
                                    hintText: 'select_identity_type'.tr,
                                    items: deliverymanController.identityTypeList,
                                    selectedValue: deliverymanController.selectedIdentityType,
                                    onChanged: (value) {
                                      deliverymanController.setSelectedIdentityType(value);
                                    },
                                  ),

                                  Positioned(
                                    left: 10, top: -10,
                                    child: Container(
                                      color: Theme.of(context).cardColor,
                                      padding: const EdgeInsets.all(2),
                                      child: Row(children: [
                                        Text('select_identity_type'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
                                        Text(' *', style: robotoRegular.copyWith(color: Theme.of(context).colorScheme.error)),
                                      ]),
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeExtraOverLarge),
      
                              Expanded(
                                child: CustomTextFieldWidget(
                                  hintText: 'Ex: XXXXX-XXXXXXX-X',
                                  controller: widget.identityNumberController,
                                  focusNode: widget.identityNumberNode,
                                  inputAction: TextInputAction.done,
                                  labelText: 'identity_number'.tr,
                                  required: true,
                                  isEnabled: deliverymanController.selectedIdentityType != null,
                                  validator: (value) => ValidateCheck.validateEmptyText(value, "identity_number_field_is_required".tr),
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeExtraOverLarge),
      
                              const Expanded(child: SizedBox()),
      
                            ]),
                            const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),
      
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: deliverymanController.pickedIdentities.length+1,
                                itemBuilder: (context, index) {
                                  XFile? file = index == deliverymanController.pickedIdentities.length ? null : deliverymanController.pickedIdentities[index];
                                  if(index == deliverymanController.pickedIdentities.length) {
                                    return InkWell(
                                      onTap: () => deliverymanController.pickDmImage(false, false),
                                      child: DottedBorder(
                                        options: RoundedRectDottedBorderOptions(
                                          color: Theme.of(context).primaryColor,
                                          strokeWidth: 1,
                                          strokeCap: StrokeCap.butt,
                                          dashPattern: const [5, 5],
                                          padding: const EdgeInsets.all(5),
                                          radius: const Radius.circular(Dimensions.radiusDefault),
                                        ),
                                        child: Container(
                                          height: 120, width: 300, alignment: Alignment.center,
                                          child: Column(children: [
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      
                                            Icon(CupertinoIcons.camera_fill, color: Theme.of(context).disabledColor.withValues(alpha: 0.8), size: 38),
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      
                                            Text('upload_identity_image'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeExtraSmall)),
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
      
                                            Text(
                                              'upload_jpg_png_gif_maximum_2_mb'.tr,
                                              style: robotoRegular.copyWith(color: Theme.of(context).disabledColor.withValues(alpha: 0.6), fontSize: 10),
                                              textAlign: TextAlign.center,
                                            ),
                                          ]),
                                        ),
                                      ),
                                    );
                                  }
                                  return Container(
                                    margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                    ),
                                    child: Stack(children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        child: GetPlatform.isWeb ? Image.network(
                                          file!.path, width: 300, height: 120, fit: BoxFit.cover,
                                        ) : Image.file(
                                          File(file!.path), width: 300, height: 120, fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        right: 10, top: 10,
                                        child: InkWell(
                                          onTap: () => deliverymanController.removeIdentityImage(index),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).cardColor,
                                              border: Border.all(color: Theme.of(context).primaryColor),
                                              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                            ),
                                            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                            child: const Icon(Icons.delete_forever_sharp, color: Colors.red, size: 20),
                                          ),
                                        ),
                                      ),
                                    ]),
                                  );
                                },
                              ),
                            ),
                          ]),
                        ),
      
                      ]),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
      
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, 1))],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge),
                      child: Column(children: [
      
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                          child: Row(children: [
                            const Icon(Icons.person),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Text('additional_information'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          ]),
                        ),
                        const Divider(),
                        //const SizedBox(height: Dimensions.paddingSizeLarge),
      
                        DeliverymanAdditionalDataSectionWidget(deliverymanController: deliverymanController, scrollController: widget.scrollController),
      
                        Padding(
                          padding: const EdgeInsets.only(left: Dimensions.paddingSizeLarge),
                          child: TramsConditionsCheckBoxWidget(deliverymanRegistrationController: deliverymanController, fromDmRegistration: true),
                        ),
      
                        Padding(
                          padding: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                border: Border.all(color: Theme.of(context).hintColor),
                              ),
                              width: 165,
                              child: CustomButtonWidget(
                                transparent: true,
                                textColor: Theme.of(context).hintColor,
                                radius: Dimensions.radiusSmall,
                                onPressed: () {
                                  widget.phoneController.text = '';
                                  widget.emailController.text = '';
                                  widget.fNameController.text = '';
                                  widget.lNameController.text = '';
                                  widget.lNameController.text = '';
                                  widget.passwordController.text = '';
                                  widget.confirmPasswordController.text = '';
                                  widget.identityNumberController.text = '';
                                  deliverymanController.resetDmRegistrationData();
                                  deliverymanController.setDeliverymanAdditionalJoinUsPageData(isUpdate: true);
                                },
                                buttonText: 'reset'.tr,
                                isBold: false,
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
      
                            const SizedBox( width: Dimensions.paddingSizeLarge),
                            SizedBox(width: 165, child: widget.buttonView),
                          ]),
                        ),
      
                      ]),
                    ),
      
                  ]),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
