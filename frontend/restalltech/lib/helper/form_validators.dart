import 'package:flutter/material.dart';

class FormValidators {
  // Returns a validator that enforces non-empty only after submitted is true.
  static FormFieldValidator<String> requiredIfSubmitted(
      bool submitted, String errorMessage) {
    return (value) {
      if (!submitted) return null;
      if (value == null || value.isEmpty) return errorMessage;
      return null;
    };
  }

  // Number validator (decimal allowed) only after submitted
  static FormFieldValidator<String> numberIfSubmitted(
      bool submitted, String errorMessage) {
    return (value) {
      if (!submitted) return null;
      if (value == null || value.isEmpty) return errorMessage;
      final normalized = value.replaceAll(',', '.');
      if (double.tryParse(normalized) == null) return errorMessage;
      return null;
    };
  }
}
