import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Profile/profile_provider.dart';
import 'package:restall/Screens/stripe_onboarding/stripe_onboarding_webview.dart';

/// Mostra un dialog per richiedere la verifica del venditore
/// Gestisce diversi stati: non-venditore, pending, verificato
void showSellerVerificationDialog(BuildContext context) {
  final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
  final userProfile = profileProvider.userProfile;

  print('🔍 DEBUG Dialog: Chiamato showSellerVerificationDialog');
  print('👤 DEBUG Dialog: userProfile = ${userProfile?.toJson()}');
  print('🏪 DEBUG Dialog: isSeller = ${userProfile?.isSeller}');
  print('📊 DEBUG Dialog: sellerStatus = ${userProfile?.sellerStatus}');
  print(
      '✅ DEBUG Dialog: isSellerVerified = ${profileProvider.isSellerVerified}');

  String title;
  String message;
  IconData icon;
  Color iconColor;
  List<Widget> actions;

  if (userProfile?.isSeller != true) {
    print(
        '❌ DEBUG Dialog: Percorso 1 - Utente NON è seller (isSeller != true)');
    // Caso 1: Utente NON è venditore
    title = 'Diventa Venditore';
    message =
        'Per vendere prodotti su RestAll devi prima attivare il tuo account venditore e completare la verifica tramite Stripe Connect.';
    icon = Icons.storefront_rounded;
    iconColor = kPrimaryColor;

    actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      ElevatedButton(
        onPressed: () async {
          Navigator.pop(context); // Chiudi dialog

          // Mostra loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );

          // Attiva account venditore
          final success = await profileProvider.requestSellerVerification();

          if (!success) {
            // Chiudi loading
            if (context.mounted) Navigator.pop(context);

            // Mostra errore
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profileProvider.errorMessage ??
                              'Errore durante l\'attivazione',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          // Attivazione OK, ora crea account Stripe e ottieni URL onboarding
          final onboardingUrl =
              await profileProvider.initiateStripeOnboarding();

          // Chiudi loading
          if (context.mounted) Navigator.pop(context);

          if (onboardingUrl != null && onboardingUrl.isNotEmpty) {
            // Apri WebView con URL Stripe
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StripeOnboardingWebView(
                    onboardingUrl: onboardingUrl,
                  ),
                ),
              );
            }
          } else {
            // Errore: impossibile ottenere URL onboarding
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profileProvider.errorMessage ??
                              'Impossibile avviare la verifica Stripe',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
        child: const Text('Attiva Account Venditore'),
      ),
    ];
  } else if (userProfile?.sellerStatus == 'pending') {
    print(
        '⚠️ DEBUG Dialog: Percorso 2 - Venditore PENDING (sellerStatus == pending)');
    // Caso 2: Venditore PENDING (in attesa di verifica Stripe)
    title = 'Verifica in Corso';
    message =
        'Il tuo account venditore è in fase di verifica tramite Stripe Connect.\n\nCompleta il processo di verifica per iniziare a vendere.';
    icon = Icons.pending_rounded;
    iconColor = Colors.orange;

    actions = [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      ElevatedButton(
        onPressed: () async {
          Navigator.pop(context); // Chiudi dialog

          // Mostra loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );

          // Ottieni URL onboarding da backend
          final onboardingUrl =
              await profileProvider.initiateStripeOnboarding();

          // Chiudi loading
          if (context.mounted) Navigator.pop(context);

          if (onboardingUrl != null && onboardingUrl.isNotEmpty) {
            // Apri WebView con URL Stripe
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StripeOnboardingWebView(
                    onboardingUrl: onboardingUrl,
                  ),
                ),
              );
            }
          } else {
            // Errore: impossibile ottenere URL onboarding
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          profileProvider.errorMessage ??
                              'Impossibile avviare la verifica Stripe',
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red[700],
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          }
        },
        child: const Text('Continua Verifica'),
      ),
    ];
  } else {
    // Caso 3: Venditore VERIFIED (non dovrebbe mai accadere)
    // Se questo dialog viene chiamato quando l'utente è già verificato,
    // c'è un bug nella logica di verifica
    print('✅ DEBUG Dialog: Percorso 3 - Venditore VERIFIED, non mostro dialog');
    return;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La verifica Stripe è necessaria per ricevere pagamenti',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
    ),
  );
}
