// We use name route
// All our routes will be available here
import 'package:flutter/material.dart';
import 'package:restall/Screens/AddCompany/add_company_screen.dart';
import 'package:restall/Screens/ForgotPassword/forgot_password.dart';
import 'package:restall/Screens/Login/login_screen.dart';
import 'package:restall/Screens/OpenTicket/ticket_screen.dart';
import 'package:restall/Screens/SideBar/sidebar.dart';
import 'package:restall/Screens/Signup/signup_screen.dart';
import 'package:restall/Screens/Welcome/welcome_screen.dart';
import 'package:restall/Screens/cart/cart_screen.dart';
import 'package:restall/Screens/complete_profile/complete_profile_screen.dart';
import 'package:restall/Screens/details_product/details_product_screen.dart';
import 'package:restall/Screens/init_screen.dart';
import 'package:restall/Screens/products/products_screen.dart';
import 'package:restall/Screens/profile/profile_screen.dart';
import 'package:restall/Screens/shop/shop_screen.dart';
import 'package:restall/Screens/ticket_success/ticket_success_screen.dart';
import 'package:restall/Screens/refund_requests/refund_requests_screen.dart';
import 'package:restall/Screens/refund_requests/create_refund_request_screen.dart';
import 'package:restall/Screens/refund_requests/refund_request_detail_screen.dart';
import 'package:restall/Screens/sell_product/sell_product_screen.dart';
import 'package:restall/Screens/stripe_onboarding/stripe_onboarding_webview.dart';
import 'package:restall/models/Product.dart';

final Map<String, WidgetBuilder> routes = {
  // INIT/AUTH SCREEN - SEMPRE PRIMA
  InitScreen.routeName: (context) => const InitScreen(),

  // AUTH SCREENS
  WelcomeScreen.routeName: (context) => const WelcomeScreen(),
  LoginScreen.routeName: (context) => LoginScreen(),
  ForgotPasswordScreen.routeName: (context) => ForgotPasswordScreen(),
  SignUpScreen.routeName: (context) => const SignUpScreen(),
  CompleteProfileScreen.routeName: (context) => const CompleteProfileScreen(),

  // MAIN APP SCREENS
  SideBar.routeName: (context) => const SideBar(),

  // FUNCTIONAL SCREENS
  TicketScreen.routeName: (context) => const TicketScreen(),
  ProfileScreen.routeName: (context) => const ProfileScreen(),
  TicketSuccessScreen.routeName: (context) => TicketSuccessScreen(),
  AddCompanyScreen.routeName: (context) => const AddCompanyScreen(),

  // REFUND REQUEST SCREENS
  RefundRequestsScreen.routeName: (context) => RefundRequestsScreen(),
  CreateRefundRequestScreen.routeName: (context) => const CreateRefundRequestScreen(),
  RefundRequestDetailScreen.routeName: (context) => RefundRequestDetailScreen(),

  // SELL PRODUCT SCREEN
  SellProductScreen.routeName: (context) => const SellProductScreen(),

  // STRIPE ONBOARDING SCREEN
  StripeOnboardingWebView.routeName: (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return StripeOnboardingWebView(
      onboardingUrl: args['onboardingUrl'] as String,
      returnUrl: args['returnUrl'] as String? ?? 'restall://stripe-return',
    );
  },

  DetailsProductScreen.routeName: (context) {
    final product = ModalRoute.of(context)!.settings.arguments
        as Product; // ✅ Direttamente Product
    return DetailsProductScreen(productId: product.id);
  },
};
