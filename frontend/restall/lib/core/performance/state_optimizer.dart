import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

// -----------------------------------------------------------------------------
// --- OTTIMIZZAZIONE DELLO STATO CON SELECTOR ---
// -----------------------------------------------------------------------------
//
// OBIETTIVO: Ridurre i rebuild inutili dei widget.
//
// PROBLEMA:
// Un `Consumer` o `context.watch` ricostruisce il widget ogni volta che
// `notifyListeners()` viene chiamato sul provider, anche se la porzione di dati
// effettivamente utilizzata dal widget non è cambiata.
//
// Esempio: Un provider `UserProvider` gestisce `userName` e `userImage`.
// Un widget che mostra solo `userName` non dovrebbe essere ricostruito se
// cambia solo `userImage`.
//
// SOLUZIONE: Usare `Selector`.
//
// `Selector` è un widget del pacchetto `provider` che permette di ascoltare
// selettivamente solo una parte specifica dello stato di un provider.
//
// COME FUNZIONA:
// 1. Fornisci il tipo del Provider e il tipo del valore che vuoi "selezionare".
//    `Selector<MyProvider, String>`
//
// 2. Usi il parametro `selector` per specificare QUALE dato osservare.
//    `selector: (context, provider) => provider.userName`
//
// 3. Il `builder` viene chiamato SOLO se il valore restituito dal `selector`
//    è diverso dal suo valore precedente.
//
// ESEMPIO PRATICO:
//
// // Sbagliato (ricostruisce sempre)
// Consumer<UserProvider>(
//   builder: (context, userProvider, child) {
//     return Text(userProvider.userName);
//   }
// )
//
// // Corretto (ricostruisce solo se `userName` cambia)
// Selector<UserProvider, String>(
//   selector: (context, userProvider) => userProvider.userName,
//   builder: (context, userName, child) {
//     return Text(userName);
//   }
// )
//
// -----------------------------------------------------------------------------

/// Un widget wrapper per `Selector` per promuoverne l'uso e renderlo più verboso.
///
/// Ascolta selettivamente un valore [S] da un [ChangeNotifier] di tipo [T] e
/// ricostruisce il widget solo quando quel valore specifico cambia.
///
/// Utile per ottimizzare le performance evitando rebuild non necessari.
class OptimizedConsumer<T extends ChangeNotifier, S> extends StatelessWidget {
  /// La funzione che "seleziona" il valore [S] da osservare dal provider [T].
  ///
  /// Esempio: `(context, provider) => provider.cartItemCount`
  final S Function(BuildContext context, T provider) selector;

  /// Il builder che viene eseguito solo quando il valore selezionato [S] cambia.
  final Widget Function(BuildContext context, S value, Widget? child) builder;

  /// Un widget figlio opzionale che viene passato al builder e non viene
  /// ricostruito. Utile per ottimizzazioni ulteriori.
  final Widget? child;

  const OptimizedConsumer({
    Key? key,
    required this.selector,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Selector<T, S>(
      selector: selector,
      builder: builder,
      child: child,
    );
  }
}
