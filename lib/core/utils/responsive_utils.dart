import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    double screenWidth = getScreenWidth(context);
    if (screenWidth < 600) {
      return baseSize * 0.8;
    } else if (screenWidth < 1200) {
      return baseSize * 0.9;
    }
    return baseSize;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;

    if (orientation == Orientation.landscape) {
      return EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      );
    }

    if (screenWidth > 600) {
      return const EdgeInsets.all(24.0);
    } else if (screenWidth > 400) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(8.0);
    }
  }

  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 16.0;
    }
    return 24.0;
  }

  static int getResponsiveGridCount(BuildContext context) {
    double width = getScreenWidth(context);
    if (width < 600) {
      return 2; // Mobile: 2 itens por linha
    } else if (width < 1200) {
      return 4; // Tablet: 4 itens por linha
    }
    return 6; // Desktop: 6 itens por linha
  }

  static double getResponsiveImageSize(BuildContext context) {
    double screenWidth = getScreenWidth(context);
    if (screenWidth < 600) {
      return screenWidth * 0.4; // 40% da largura da tela em mobile
    } else if (screenWidth < 1200) {
      return screenWidth * 0.25; // 25% da largura da tela em tablet
    }
    return screenWidth * 0.15; // 15% da largura da tela em desktop
  }

  static Widget responsiveWrapper({
    required BuildContext context,
    required Widget mobile,
    required Widget tablet,
    required Widget desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    }
    return desktop;
  }

  static double getResponsiveMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return getScreenWidth(context) * 0.95;
    } else if (isTablet(context)) {
      return getScreenWidth(context) * 0.85;
    }
    return getScreenWidth(context) * 0.75;
  }

  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
    return const EdgeInsets.symmetric(horizontal: 64.0);
  }
}
