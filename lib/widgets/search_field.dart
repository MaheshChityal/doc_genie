import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/utils/debouncer.dart';
import 'package:flutter/material.dart';

/// A styled search box with a clear button that debounces its callback.
///
/// Emits the trimmed query via [onChanged] after [debounce]. Clearing fires
/// an immediate empty query.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.onChanged,
    this.hint = 'Search…',
    this.debounce = const Duration(milliseconds: 300),
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final Duration debounce;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _controller = TextEditingController();
  late final Debouncer _debouncer = Debouncer(delay: widget.debounce);
  bool _hasText = false;

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final has = value.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
    _debouncer(() => widget.onChanged(value.trim()));
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
    _debouncer.cancel();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hint,
        isDense: true,
        filled: true,
        fillColor: ColorConstants.surface,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: _clear,
                tooltip: 'Clear',
              )
            : null,
      ),
    );
  }
}
