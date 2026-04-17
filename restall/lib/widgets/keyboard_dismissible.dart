import 'package:flutter/material.dart';

/// Widget che chiude automaticamente la tastiera quando si fa tap fuori dai campi
/// Supporta anche lo swipe per chiudere la tastiera (nativo di Flutter)
class KeyboardDismissible extends StatelessWidget {
  final Widget child;

  const KeyboardDismissible({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Rimuove il focus da qualsiasi campo di testo, chiudendo la tastiera
        FocusScope.of(context).unfocus();
      },
      child: child,
    );
  }
}
