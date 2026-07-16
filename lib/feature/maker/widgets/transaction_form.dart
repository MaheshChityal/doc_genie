import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/maker/model/field_validators.dart';
import 'package:doc_genie/feature/maker/model/scan_models.dart';
import 'package:doc_genie/widgets/app_button.dart';
import 'package:flutter/material.dart';

class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    required this.type,
    required this.initialValues,
    required this.onSubmit,
    this.readOnly = false,
    this.isSubmitting = false,
  });

  final TransactionType type;
  final Map<String, String> initialValues;
  final void Function(Map<String, String> fields, String isEdited) onSubmit;
  final bool readOnly;
  final bool isSubmitting;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(TransactionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type ||
        oldWidget.initialValues != widget.initialValues) {
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      _initControllers();
    }
  }

  void _initControllers() {
    for (final (key, _, _) in fieldsForType(widget.type)) {
      _controllers[key] = TextEditingController(
        text: widget.initialValues[key] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    final fields = <String, String>{};
    var edited = false;
    for (final entry in _controllers.entries) {
      final val = entry.value.text.trim();
      fields[entry.key] = val;
      if (val != (widget.initialValues[entry.key] ?? '').trim()) {
        edited = true;
      }
    }
    widget.onSubmit(fields, edited ? 'Y' : 'N');
  }

  @override
  Widget build(BuildContext context) {
    final fields = fieldsForType(widget.type);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TypeBadge(type: widget.type),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumn = constraints.maxWidth >= 640;
              if (twoColumn) {
                final rows = <List<(String, String, bool)>>[];
                for (var i = 0; i < fields.length; i += 2) {
                  rows.add([
                    fields[i],
                    if (i + 1 < fields.length) fields[i + 1],
                  ]);
                }
                return Column(
                  children: [
                    for (final row in rows) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final f in row) ...[
                            Expanded(
                              child: _FieldTile(
                                f: f,
                                type: widget.type,
                                controllers: _controllers,
                                readOnly: widget.readOnly,
                              ),
                            ),
                            if (row.indexOf(f) < row.length - 1)
                              const SizedBox(width: 16),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  for (final f in fields) ...[
                    _FieldTile(
                      f: f,
                      type: widget.type,
                      controllers: _controllers,
                      readOnly: widget.readOnly,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            },
          ),
          if (!widget.readOnly) ...[
            const SizedBox(height: 8),
            AppButton(
              label: 'Submit',
              onPressed: _submit,
              isLoading: widget.isSubmitting,
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  const _FieldTile({
    required this.f,
    required this.type,
    required this.controllers,
    required this.readOnly,
  });

  final (String, String, bool) f;
  final TransactionType type;
  final Map<String, TextEditingController> controllers;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final (key, label, optional) = f;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: ColorConstants.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (optional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ColorConstants.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Optional',
                  style: AppTextStyles.caption.copyWith(fontSize: 10.5),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controllers[key],
          readOnly: readOnly,
          enabled: !readOnly,
          validator: readOnly
              ? null
              : validatorFor(key, optional, type, controllers),
          decoration: InputDecoration(
            hintText: optional ? 'Optional' : 'Enter $label',
            filled: true,
            fillColor: readOnly
                ? ColorConstants.surfaceAlt
                : ColorConstants.surface,
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final color = _color(type);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: AppTextStyles.subtitle.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${fieldsForType(type).length} fields',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  static Color _color(TransactionType type) {
    switch (type) {
      case TransactionType.rtgs:
        return ColorConstants.infoColor;
      case TransactionType.neft:
        return ColorConstants.secondaryColor;
      case TransactionType.fundTransfer:
        return ColorConstants.accentColor;
    }
  }
}
