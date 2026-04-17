import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:restall/constants.dart';
import 'package:restall/providers/Profile/profile_provider.dart';

class StripeOnboardingWebView extends StatefulWidget {
  static const String routeName = '/stripe-onboarding';

  final String onboardingUrl;
  final String returnUrl;
  final String title;

  const StripeOnboardingWebView({
    super.key,
    required this.onboardingUrl,
    this.returnUrl = 'restall://stripe-return',
    this.title = 'Verifica Venditore',
  });

  @override
  State<StripeOnboardingWebView> createState() =>
      _StripeOnboardingWebViewState();
}

class _StripeOnboardingWebViewState extends State<StripeOnboardingWebView> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                secondaryColor.withValues(alpha: 0.9),
                secondaryColor.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri(widget.onboardingUrl),
            ),
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              useOnLoadResource: true,
              javaScriptEnabled: true,
              domStorageEnabled: true,
              thirdPartyCookiesEnabled: true,
              supportZoom: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() => _isLoading = true);

              // Intercetta il return URL
              if (url != null && url.toString().contains(widget.returnUrl)) {
                _handleOnboardingComplete();
              }
            },
            onLoadStop: (controller, url) {
              setState(() => _isLoading = false);
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _progress = progress / 100;
              });
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url;

              if (url != null && url.toString().contains(widget.returnUrl)) {
                _handleOnboardingComplete();
                return NavigationActionPolicy.CANCEL;
              }

              return NavigationActionPolicy.ALLOW;
            },
            onReceivedError: (controller, request, error) {
              _showErrorDialog(
                'Errore di Caricamento',
                'Si è verificato un errore durante il caricamento della pagina: ${error.description}',
              );
            },
          ),
          if (_isLoading && _progress == 0)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: kPrimaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Caricamento...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleOnboardingComplete() async {
    final profileProvider =
        Provider.of<ProfileProvider>(context, listen: false);

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      ),
    );

    // Verifica stato con backend
    final isVerified = await profileProvider.checkStripeAccountStatus();

    // Chiudi loading
    if (mounted) Navigator.pop(context);

    if (isVerified) {
      // Mostra success
      _showSuccessDialog();
    } else {
      // Mostra pending/incomplete
      _showPendingDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Verifica Completata!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Il tuo account venditore è stato verificato con successo.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Ora puoi iniziare a vendere i tuoi prodotti su RestAll!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Chiudi dialog
              Navigator.pop(context); // Chiudi webview e torna al profilo
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pending_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Verifica Incompleta'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La verifica del tuo account venditore non è ancora stata completata.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'Potrebbe richiedere alcuni giorni per la revisione. Ti invieremo una notifica quando sarà completata.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Chiudi dialog
              Navigator.pop(context); // Chiudi webview
            },
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Chiudi dialog solo
              // Rimani nella webview per continuare
            },
            child: const Text('Continua Verifica'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _webViewController?.reload();
            },
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }
}
