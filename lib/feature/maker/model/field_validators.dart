import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:flutter/material.dart';

/// Returns the validator for a given field key, or null if no validation needed.
FormFieldValidator<String>? validatorFor(
  String key,
  bool optional,
  TransactionType type,
  Map<String, TextEditingController> controllers,
) {
  switch (key) {
    // ── 14-digit numeric account number (RTGS + NEFT) ──────────────────────
    case 'remitterAccountNumber':
      return (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Remitter Account Number is required';
        }
        if (!RegExp(r'^\d{14}$').hasMatch(v.trim())) {
          return 'Must be exactly 14 digits';
        }
        return null;
      };

    // ── IFSC: 11-char, format XXXX0XXXXXX ─────────────────────────────────
    case 'ifscCode':
    case 'beneIfscCode':
      return (v) {
        if (v == null || v.trim().isEmpty) return 'IFSC Code is required';
        if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v.trim().toUpperCase())) {
          return 'Invalid IFSC — must be 11 chars (e.g. HDFC0001234)';
        }
        return null;
      };

    // ── Amount: positive number (all types) ────────────────────────────────
    case 'amount':
      return (v) {
        if (v == null || v.trim().isEmpty) return 'Amount is required';
        final amount = double.tryParse(v.trim().replaceAll(',', ''));
        if (amount == null || amount <= 0) return 'Enter a valid positive amount';
        return null;
      };

    // ── LEI Code: required when amount ≥ ₹50 Cr (RTGS only) ───────────────
    case 'leiCode':
      if (type != TransactionType.rtgs) return null;
      return (v) {
        final raw = controllers['amount']?.text.trim().replaceAll(',', '') ?? '';
        final amount = double.tryParse(raw) ?? 0;
        if (amount >= 500000000 && (v == null || v.trim().isEmpty)) {
          return 'LEI Code is required when amount ≥ ₹50 Cr';
        }
        return null;
      };

    // ── Cheque fields: required only when "With Cheque" (Fund Transfer) ────
    case 'chequeNumber':
      if (type != TransactionType.fundTransfer) {
        return optional ? null : _required('Cheque Number');
      }
      return (v) {
        if (_isCheque(controllers) && (v == null || v.trim().isEmpty)) {
          return 'Cheque Number is required for cheque-based transactions';
        }
        return null;
      };

    case 'chequeDate':
      if (type != TransactionType.fundTransfer) {
        return optional ? null : _required('Cheque Date');
      }
      return (v) {
        if (_isCheque(controllers) && (v == null || v.trim().isEmpty)) {
          return 'Cheque Date is required for cheque-based transactions';
        }
        return null;
      };

    // ── Default: required check for non-optional fields ────────────────────
    default:
      return optional ? null : _required(key);
  }
}

FormFieldValidator<String> _required(String fieldName) =>
    (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null;

bool _isCheque(Map<String, TextEditingController> controllers) =>
    controllers['chequeBasedTransaction']?.text.trim() == 'With Cheque';
