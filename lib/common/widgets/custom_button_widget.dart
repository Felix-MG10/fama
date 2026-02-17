import 'package:stackfood_multivendor/util/dimensions.dart';
import 'package:stackfood_multivendor/util/styles.dart';
import 'package:stackfood_multivendor/helper/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomButtonWidget extends StatelessWidget {
  final Function? onPressed;
  final String buttonText;
  final bool transparent;
  final EdgeInsets? margin;
  final double? height;
  final double? width;
  final double? fontSize;
  final double radius;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final bool isLoading;
  final bool isBold;
  const CustomButtonWidget({super.key, this.onPressed, required this.buttonText, this.transparent = false, this.margin, this.width, this.height,
    this.fontSize, this.radius = 10, this.icon, this.color, this.textColor, this.isLoading = false, this.isBold = true});

  @override
  Widget build(BuildContext context) {
    bool isTablet = ResponsiveHelper.isTablet(context);
    
    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      backgroundColor: onPressed == null ? Theme.of(context).disabledColor.withValues(alpha: 0.6) : transparent
          ? Colors.transparent : color ?? Theme.of(context).primaryColor,
      minimumSize: Size(width != null ? width! : Dimensions.webMaxWidth, height != null ? height! : (isTablet ? 56 : 50)),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall,
        vertical: isTablet ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeExtraSmall,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    );

    return Center(child: SizedBox(width: width ?? Dimensions.webMaxWidth, child: Padding(
      padding: margin == null ? const EdgeInsets.all(0) : margin!,
      child: TextButton(
        onPressed: isLoading ? null : onPressed as void Function()?,
        style: flatButtonStyle,
        child: isLoading ? Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const SizedBox(
            height: 15, width: 15,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Text('loading'.tr, style: robotoMedium.copyWith(color: Colors.white)),
        ]),
        ) : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          icon != null ? Padding(
            padding: EdgeInsets.only(right: isTablet ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeExtraSmall),
            child: Icon(icon, color: transparent ? Theme.of(context).primaryColor : Theme.of(context).cardColor),
          ) : const SizedBox(),
          Flexible(
            child: Text(
              buttonText, 
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: isBold ? robotoBold.copyWith(
                color: textColor ?? (transparent ? Theme.of(context).primaryColor : Colors.white),
                fontSize: fontSize ?? (isTablet ? Dimensions.fontSizeSmall : Dimensions.fontSizeLarge),
              ) : robotoRegular.copyWith(
                color: textColor ?? (transparent ? Theme.of(context).primaryColor : Colors.white),
                fontSize: fontSize ?? (isTablet ? Dimensions.fontSizeSmall : Dimensions.fontSizeLarge),
              )
            ),
          ),
        ]),
      ),
    )));
  }
}
