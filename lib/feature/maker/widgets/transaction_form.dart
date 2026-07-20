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
    this.belowFields,
    this.maxColumns = 2,
    this.showActions = true,
  });

  final TransactionType type;
  final Map<String, String> initialValues;
  final void Function(Map<String, String> fields, String isEdited) onSubmit;
  final bool readOnly;
  final bool isSubmitting;

  /// Maximum number of columns the field grid expands to on wide layouts.
  final int maxColumns;

  /// Optional widget rendered between the field grid and the Submit button
  /// (e.g. a remark entry). Shown whenever non-null, regardless of [readOnly].
  final Widget? belowFields;

  /// When false, the form renders only the field grid — no remark slot and no
  /// Submit button. The caller then triggers submission externally via a
  /// [GlobalKey]&lt;[TransactionFormState]&gt; and `state.submit()`.
  final bool showActions;

  @override
  TransactionFormState createState() => TransactionFormState();
}

class TransactionFormState extends State<TransactionForm> {
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

  void submit() {
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
    final sections = sectionsForType(widget.type);

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final columns = (w >= 960 ? widget.maxColumns : (w >= 480 ? 2 : 1))
              .clamp(1, widget.maxColumns);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var s = 0; s < sections.length; s++) ...[
                if (s > 0) const SizedBox(height: 12),
                _SectionHeader(title: sections[s].title),
                const SizedBox(height: 8),
                _grid(sections[s].fields, columns),
              ],
              if (widget.belowFields != null && widget.showActions) ...[
                const SizedBox(height: 4),
                widget.belowFields!,
              ],
              if (!widget.readOnly && widget.showActions) ...[
                const SizedBox(height: 12),
                AppButton(
                  label: 'Submit',
                  onPressed: submit,
                  isLoading: widget.isSubmitting,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _grid(List<(String, String, bool)> fields, int columns) {
    if (columns == 1) {
      return Column(
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            _FieldTile(
              f: fields[i],
              type: widget.type,
              controllers: _controllers,
              readOnly: widget.readOnly,
            ),
            if (i < fields.length - 1) const SizedBox(height: 8),
          ],
        ],
      );
    }
    final rows = <List<(String, String, bool)>>[];
    for (var i = 0; i < fields.length; i += columns) {
      final end = (i + columns) > fields.length ? fields.length : i + columns;
      rows.add(fields.sublist(i, end));
    }
    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var c = 0; c < columns; c++) ...[
                Expanded(
                  child: c < rows[r].length
                      ? _FieldTile(
                          f: rows[r][c],
                          type: widget.type,
                          controllers: _controllers,
                          readOnly: widget.readOnly,
                        )
                      : const SizedBox.shrink(),
                ),
                if (c < columns - 1) const SizedBox(width: 12),
              ],
            ],
          ),
          if (r < rows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 14,
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title.toUpperCase(),
            style: AppTextStyles.eyebrow.copyWith(
              color: ColorConstants.primaryColor,
              fontSize: 11.5,
            ),
          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: ColorConstants.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Optional',
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controllers[key],
          readOnly: readOnly,
          enabled: !readOnly,
          validator:
              readOnly ? null : validatorFor(key, optional, type, controllers),
          decoration: InputDecoration(
            hintText: optional ? 'Optional' : 'Enter $label',
            filled: true,
            fillColor:
                readOnly ? ColorConstants.disabledFill : ColorConstants.surface,
            disabledBorder: readOnly
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: ColorConstants.disabledBorder,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
