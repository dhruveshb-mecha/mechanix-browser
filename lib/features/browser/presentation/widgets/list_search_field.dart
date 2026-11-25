import 'package:flutter/material.dart';
import 'package:mechanix_browser/core/utils/app_theme.dart';

/// Search box above the history and bookmarks lists. Reports every change
/// through [onChanged]; the clear button resets the query to ''.
class ListSearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;

  const ListSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  @override
  State<ListSearchField> createState() => _ListSearchFieldState();
}

class _ListSearchFieldState extends State<ListSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    return TextField(
      controller: _controller,
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {}); // show or hide the clear button
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: colors.searchBarHint),
        prefixIcon: Icon(Icons.search, color: colors.searchBarHint),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(Icons.close, color: colors.searchBarHint),
                onPressed: _clear,
              ),
        filled: true,
        fillColor: colors.panelBackground,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
