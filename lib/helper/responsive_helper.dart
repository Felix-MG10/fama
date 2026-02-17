import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveHelper {

  static bool isMobilePhone() {
    if (!kIsWeb) {
      return true;
    }else {
      return false;
    }
  }

  static bool isWeb() {
    return kIsWeb;
  }

  static bool isMobile(BuildContext? context) {
    final size = MediaQuery.of(context!).size.width;
    if (size < 650 || !kIsWeb) {
      return true;
    } else {
      return false;
    }
  }

  static bool isTab(BuildContext? context) {
    final size = MediaQuery.of(context!).size.width;
    if (size < 1300 && size >= 650) {
      return true;
    } else {
      return false;
    }
  }

  static bool isDesktop(BuildContext? context) {
    final size = MediaQuery.of(context!).size.width;
    if (size >= 1300) {
      return true;
    } else {
      return false;
    }
  }

  /// Détecte si l'appareil est une tablette (iPad ou tablette Android)
  /// iPad a généralement une largeur minimale de 768 points
  static bool isTablet(BuildContext? context) {
    if (kIsWeb) return false; // Pas de tablette web iOS
    
    if (context == null) return false;
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    // iPad iOS a généralement une largeur minimale de 768 points
    // ou un ratio largeur/hauteur différent
    if (Platform.isIOS) {
      return width >= 768 || (width > height && width >= 600);
    }
    
    // Pour Android, utiliser la même logique
    if (Platform.isAndroid) {
      return width >= 600;
    }
    
    return false;
  }
}