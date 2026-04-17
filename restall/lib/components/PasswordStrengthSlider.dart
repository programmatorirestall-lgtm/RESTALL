import 'package:flutter/material.dart';
import 'package:restall/constants.dart';

class PasswordStrengthSlider extends StatelessWidget {
  final String password;
  final bool showLabel;

  const PasswordStrengthSlider({
    super.key,
    required this.password,
    this.showLabel = true,
  });

  // Verifica se la password soddisfa completamente la regex del progetto
  bool _isPasswordValid(String password) {
    return passwordValidatorRegExp.hasMatch(password);
  }

  // Restituisce i requisiti mancanti per la password
  List<String> _getMissingRequirements(String password) {
    List<String> missing = [];

    if (password.length < 8) {
      missing.add('almeno 8 caratteri');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      missing.add('una lettera minuscola');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      missing.add('una lettera maiuscola');
    }
    if (!password.contains(RegExp(r'\d'))) {
      missing.add('un numero');
    }
    if (!password.contains(RegExp(r'[@$!%*?&]'))) {
      missing.add('un carattere speciale');
    }

    return missing;
  }

  // Genera un messaggio di errore specifico (metodo pubblico)
  String? getValidationError() {
    if (password.isEmpty) return null;

    final missing = _getMissingRequirements(password);
    if (missing.isEmpty) return null;

    if (missing.length == 1) {
      return 'Manca: ${missing.first}';
    } else if (missing.length == 2) {
      return 'Mancano: ${missing.join(' e ')}';
    } else {
      return 'Mancano: ${missing.sublist(0, missing.length - 1).join(', ')} e ${missing.last}';
    }
  }

  // Calcola la forza della password (0-5) basato sulla regex del progetto
  int _calculatePasswordStrength(String password) {
    int strength = 0;

    if (password.isEmpty) return 0;

    // Lunghezza minima 8 caratteri
    if (password.length >= 8) strength++;

    // Contiene almeno una lettera minuscola
    if (password.contains(RegExp(r'[a-z]'))) strength++;

    // Contiene almeno una lettera maiuscola
    if (password.contains(RegExp(r'[A-Z]'))) strength++;

    // Contiene almeno un numero
    if (password.contains(RegExp(r'\d'))) strength++;

    // Contiene caratteri speciali esatti dalla regex del progetto
    if (password.contains(RegExp(r'[@$!%*?&]'))) strength++;

    return strength;
  }

  // Ottiene il colore in base alla forza e validità della password
  Color _getStrengthColor(int strength) {
    // Se la password è valida secondo la regex, usa verde
    if (strength == 5 && _isPasswordValid(password)) {
      return Colors.green;
    }

    switch (strength) {
      case 0:
        return Colors.transparent;
      case 1:
        return Colors.red;
      case 2:
        return Colors.deepOrange;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.amber;
      case 5:
        return Colors.lightGreen; // Verde più tenue se non completamente valida
      default:
        return Colors.transparent;
    }
  }

  // Ottiene il testo descrittivo allineato al messaggio di errore del progetto
  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
        return '';
      case 1:
        return 'Troppo debole';
      case 2:
        return 'Debole';
      case 3:
        return 'Accettabile';
      case 4:
        return 'Buona';
      case 5:
        return 'Forte';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int strength = _calculatePasswordStrength(password);
    final Color strengthColor = _getStrengthColor(strength);
    final String strengthText = _getStrengthText(strength);
    final List<String> missing = _getMissingRequirements(password);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra di forza visiva più alta
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey[200],
            ),
            child: Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < 4 ? 3 : 0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color:
                          index < strength ? strengthColor : Colors.transparent,
                    ),
                  ),
                );
              }),
            ),
          ),

          // Etichetta di testo principale
          if (showLabel && strengthText.isNotEmpty) ...[
            const SizedBox(height: defaultPadding / 2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: strengthColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: strengthColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    strength >= 5 ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: strengthColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Forza password: $strengthText',
                      style: TextStyle(
                        fontSize: 13,
                        color: strengthColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Mostra i requisiti mancanti se presenti
          if (showLabel && missing.isNotEmpty) ...[
            const SizedBox(height: defaultPadding / 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Requisiti mancanti:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...missing
                      .map((requirement) => Padding(
                            padding: const EdgeInsets.only(left: 20, top: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.orange[600],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    requirement,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange[700],
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),

                  // Aggiungi suggerimento per caratteri speciali se necessario
                  if (missing
                      .any((req) => req.contains('carattere speciale'))) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  height: 1.2,
                                ),
                                children: [
                                  const TextSpan(text: 'Caratteri validi: '),
                                  TextSpan(
                                    text: '@ \$ ! % * ? &',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
