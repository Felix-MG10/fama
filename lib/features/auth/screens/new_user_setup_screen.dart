import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackfood_multivendor/common/widgets/custom_button_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_image_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_snackbar_widget.dart';
import 'package:stackfood_multivendor/common/widgets/custom_text_field_widget.dart';
import 'package:stackfood_multivendor/common/widgets/validate_check.dart';
import 'package:stackfood_multivendor/features/auth/controllers/auth_controller.dart';
import 'package:stackfood_multivendor/features/auth/domain/centralize_login_enum.dart';
import 'package:stackfood_multivendor/features/language/controllers/localization_controller.dart';
import 'package:stackfood_multivendor/features/splash/controllers/splash_controller.dart';
import 'package:stackfood_multivendor/helper/custom_validator.dart';
import 'package:stackfood_multivendor/helper/responsive_helper.dart';
import 'package:stackfood_multivendor/helper/route_helper.dart';
import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/images.dart';
import 'package:stackfood_multivendor/util/styles.dart';

class NewUserSetupScreen extends StatefulWidget {
  final String name;
  final String loginType;
  final String? phone;
  final String? email;
  const NewUserSetupScreen({super.key, required this.name, required this.loginType, required this.phone, required this.email});

  @override
  State<NewUserSetupScreen> createState() => _NewUserSetupScreenState();
}

class _NewUserSetupScreenState extends State<NewUserSetupScreen> {
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _referCodeFocus = FocusNode();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _referCodeController = TextEditingController();
  String? _countryDialCode;
  GlobalKey<FormState>? _formKeyInfo;

  bool _isSocial = false;

  @override
  void initState() {
    super.initState();


    _isSocial = widget.loginType == CentralizeLoginType.social.name;
    _formKeyInfo = GlobalKey<FormState>();
    _countryDialCode = CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;
    
    // Pré-remplir le nom si fourni (par exemple depuis Sign in with Apple)
    if (widget.name.isNotEmpty) {
      _nameController.text = widget.name;
    }
    
    // Pré-remplir l'email si fourni (par exemple depuis Sign in with Apple)
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResponsiveHelper.isDesktop(context) ? Colors.transparent : Theme.of(context).cardColor,
      appBar: ResponsiveHelper.isDesktop(context) ? null : AppBar(leading: IconButton(
        onPressed: () => Get.back(),
        icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).textTheme.bodyLarge!.color),
      ), elevation: 0, backgroundColor: Theme.of(context).cardColor),
      body: SafeArea(child: Align(
        alignment: ResponsiveHelper.isDesktop(context) ? Alignment.center : Alignment.topCenter,
        child: Container(
          width: context.width > 700 ? 500 : context.width,
          padding: context.width > 700 ? const EdgeInsets.all(50) : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge),
          margin: context.width > 700 ? const EdgeInsets.all(50) : EdgeInsets.zero,
          decoration: context.width > 700 ? BoxDecoration(
            color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            boxShadow: ResponsiveHelper.isDesktop(context) ? null : [BoxShadow(color: Colors.grey[Get.isDarkMode ? 700 : 300]!, blurRadius: 5, spreadRadius: 1)],
          ) : null,
          child: SingleChildScrollView(
            child: Form(
              key: _formKeyInfo,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                ResponsiveHelper.isDesktop(context) ? Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.clear),
                  ),
                ) : const SizedBox(),

                CustomImageWidget(
                  image: Get.find<SplashController>().configModel?.logoFullUrl ?? '',
                  height: 50, width: 200, fit: BoxFit.contain,
                ),
                const SizedBox(height: Dimensions.paddingSizeLarge),

                Text('just_one_step_away'.tr, style: robotoMedium.copyWith(color: Theme.of(context).disabledColor), textAlign: TextAlign.center),
                const SizedBox(height: Dimensions.paddingSizeOverLarge),

                CustomTextFieldWidget(
                  hintText: 'ex_jhon'.tr,
                  labelText: 'user_name'.tr,
                  showLabelText: true,
                  // Le nom n'est pas requis si déjà fourni par Sign in with Apple
                  required: widget.name.isEmpty,
                  controller: _nameController,
                  focusNode: _nameFocus,
                  nextFocus: _isSocial ? _phoneFocus : _emailFocus,
                  inputType: TextInputType.name,
                  capitalization: TextCapitalization.words,
                  prefixIcon: CupertinoIcons.person_alt_circle_fill,
                  levelTextSize: Dimensions.fontSizeDefault,
                  // Si le nom est déjà fourni (par Apple), ne pas le valider comme requis
                  validator: widget.name.isNotEmpty 
                    ? null 
                    : (value) => ValidateCheck.validateEmptyText(value, "please_enter_your_name".tr),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                _isSocial ? CustomTextFieldWidget(
                  hintText: 'xxx-xxx-xxxxx'.tr,
                  labelText: 'phone'.tr,
                  showLabelText: true,
                  required: false,
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  nextFocus: _referCodeFocus,
                  inputType: TextInputType.phone,
                  isPhone: true,
                  onCountryChanged: (CountryCode countryCode) {
                    _countryDialCode = countryCode.dialCode;
                  },
                  countryDialCode: _countryDialCode != null ? CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).code
                      : Get.find<LocalizationController>().locale.countryCode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return null; // Phone is optional
                    }
                    return ValidateCheck.validateEmptyText(value, "please_enter_phone_number".tr);
                  },
                ) : CustomTextFieldWidget(
                  hintText: 'enter_email'.tr,
                  labelText: 'email'.tr,
                  showLabelText: true,
                  // L'email n'est pas requis si déjà fourni par Sign in with Apple
                  required: widget.email == null || widget.email!.isEmpty,
                  controller: _emailController,
                  focusNode: _emailFocus,
                  nextFocus: _referCodeFocus,
                  inputType: TextInputType.emailAddress,
                  prefixIcon: CupertinoIcons.mail_solid,
                  // Si l'email est déjà fourni (par Apple), ne pas le valider comme requis
                  validator: (widget.email != null && widget.email!.isNotEmpty)
                    ? null
                    : (value) => ValidateCheck.validateEmail(value),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),

                (Get.find<SplashController>().configModel!.refEarningStatus!) ? CustomTextFieldWidget(
                  hintText: 'refer_code'.tr,
                  labelText: 'refer_code'.tr,
                  showLabelText: true,
                  controller: _referCodeController,
                  focusNode: _referCodeFocus,
                  inputAction: TextInputAction.done,
                  inputType: TextInputType.text,
                  capitalization: TextCapitalization.words,
                  prefixImage : Images.referCode,
                  divider: false,
                  prefixSize: 14,
                ) : const SizedBox(),
                const SizedBox(height: Dimensions.paddingSizeExtraOverLarge),

                GetBuilder<AuthController>(builder: (authController) {
                  return CustomButtonWidget(
                    height: ResponsiveHelper.isDesktop(context) ? 50 : null,
                    width:  ResponsiveHelper.isDesktop(context) ? 250 : null,
                    radius: ResponsiveHelper.isDesktop(context) ? Dimensions.radiusSmall : Dimensions.radiusDefault,
                    isBold: !ResponsiveHelper.isDesktop(context),
                    fontSize: ResponsiveHelper.isDesktop(context) ? Dimensions.fontSizeSmall : null,
                    buttonText: 'done'.tr,
                    isLoading: authController.isLoading,
                    onPressed: () async {
                      String name = _nameController.text.trim();
                      String referCode = _referCodeController.text.trim();
                      String number = _phoneController.text.trim();

                      String? countryCode = _countryDialCode;
                      // Valeur brute envoyée à l'API (préfixe + numéro saisi) — ne pas l'écraser par phoneValid.phone qui peut être vide si le format est jugé invalide
                      String? rawPhoneForApi;
                      PhoneValid phoneValid = PhoneValid(isValid: true, countryCode: countryCode ?? '', phone: '');
                      if (number.isNotEmpty && countryCode != null) {
                        rawPhoneForApi = countryCode + number;
                        phoneValid = await CustomValidator.isPhoneValid(rawPhoneForApi);
                      }

                      if (_isSocial && number.isNotEmpty && !phoneValid.isValid && !_formKeyInfo!.currentState!.validate()) {
                        showCustomSnackBar('invalid_phone_number'.tr);
                      } else if(referCode.isNotEmpty && referCode.length != 10){
                        showCustomSnackBar('invalid_refer_code'.tr);
                      } else if(_formKeyInfo!.currentState!.validate()) {
                        String? phoneValue;
                        if (widget.phone != null && widget.phone!.isNotEmpty) {
                          phoneValue = widget.phone;
                        } else if (number.isNotEmpty && rawPhoneForApi != null && rawPhoneForApi.isNotEmpty) {
                          // Toujours envoyer le numéro saisi (avec indicatif) pour éviter "phone field is required" côté backend
                          phoneValue = phoneValid.isValid ? phoneValid.phone : rawPhoneForApi;
                        }
                        authController.updatePersonalInfo(
                          name: name.isNotEmpty ? name : widget.name, phone: phoneValue,
                          loginType: widget.loginType, email: widget.email ?? _emailController.text.trim(),
                          referCode: _referCodeController.text.trim(),
                        ).then((response) {
                          if(response.isSuccess) {
                            Get.offAllNamed(RouteHelper.getAccessLocationRoute('sign-in'));
                          } else {

                            if(response.code == 'email'){
                              FocusScope.of(Get.context!).requestFocus(_emailFocus);
                            }else if(response.code == 'phone'){
                              FocusScope.of(Get.context!).requestFocus(_phoneFocus);
                            }else if(response.code == 'ref_code'){
                              FocusScope.of(Get.context!).requestFocus(_referCodeFocus);
                            }

                            showCustomSnackBar(response.message);
                          }
                        });
                      }

                    },
                  );
                }),

              ]),
            ),
          ),

        ),
      )),
    );
  }
}
