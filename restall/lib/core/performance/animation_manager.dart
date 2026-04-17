import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Gestisce le impostazioni globali per le animazioni nell'app.
///
/// Fornisce un controllo centralizzato per abilitare o disabilitare le animazioni,
/// permettendo di creare modalità a performance elevate o a ridotto consumo energetico.
class AnimationManager with ChangeNotifier {
  bool _areAnimationsEnabled = true;

  /// Restituisce `true` se le animazioni sono abilitate globalmente.
  bool get areAnimationsEnabled => _areAnimationsEnabled;

  /// Abilita o disabilita tutte le animazioni gestite da questo manager.
  void setAnimationsEnabled(bool enabled) {
    if (_areAnimationsEnabled != enabled) {
      _areAnimationsEnabled = enabled;
      notifyListeners();
    }
  }
}

/// Un widget di transizione che rispetta le impostazioni dell'AnimationManager.
///
/// Utilizzare questo widget al posto di `FadeTransition` per animazioni
/// che possono essere disabilitate globalmente.
class ManagedFadeTransition extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const ManagedFadeTransition({
    Key? key,
    required this.animation,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final animationManager = context.watch<AnimationManager>();

    if (animationManager.areAnimationsEnabled) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    }

    // Se le animazioni sono disabilitate, mostra il widget figlio direttamente
    // quando l'animazione è completata per evitare stati intermedi.
    return ValueListenableBuilder<double>(
      valueListenable: animation,
      builder: (context, value, child) {
        return value == 1.0 ? child! : const SizedBox.shrink();
      },
      child: child,
    );
  }
}
