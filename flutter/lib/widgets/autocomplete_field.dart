import 'package:flutter_typeahead/flutter_typeahead.dart';
// If you see errors with TypeAheadFormField or TextFieldConfiguration, ensure flutter_typeahead is compatible with your Flutter/Dart SDK.
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:async' show Completer;

class AutocompleteField extends StatefulWidget {
  // Optional override for builder (for custom input handling, e.g. Enter key)
  final Widget Function(BuildContext, TextEditingController, FocusNode)?
  builderOverride;
  final ValueChanged<String>? onSelected;
  final String label;
  final String initialValue;
  final List<String> suggestions;
  final Future<List<String>> Function(String)? suggestionsFetcher;
  final Duration debounceDuration;
  final ValueChanged<String> onChanged;
  final bool forceSelect;
  final bool requiredField;
  final int maxLines;
  final TextInputType? keyboard;

  const AutocompleteField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.suggestions,
    required this.onChanged,
    this.requiredField = false,
    this.maxLines = 1,
    this.keyboard,
    this.forceSelect = false,
    this.builderOverride,
    this.onSelected,
    this.suggestionsFetcher,
    this.debounceDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AutocompleteField> createState() => _AutocompleteFieldState();
}

class _AutocompleteFieldState extends State<AutocompleteField> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  // no longer needed; per-call completers are used inside suggestionsCallback

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant AutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TypeAheadField(
          controller: _controller,
          suggestionsCallback: (pattern) async {
            if (widget.suggestionsFetcher != null) {
              // Debounce: wait debounceDuration before calling backend. If multiple
              // requests arrive, only the latest will execute.
              _debounceTimer?.cancel();
              final completer = Completer<List<String>>();
              _debounceTimer = Timer(widget.debounceDuration, () async {
                try {
                  final res = await widget.suggestionsFetcher!(pattern);
                  if (!completer.isCompleted) completer.complete(res);
                } catch (_) {
                  if (!completer.isCompleted) completer.complete(<String>[]);
                }
              });
              return completer.future;
            }
            return widget.suggestions
                .where(
                  (item) => item.toLowerCase().contains(pattern.toLowerCase()),
                )
                .toList();
          },
          itemBuilder: (context, suggestion) {
            return ListTile(title: Text(suggestion.toString()));
          },
          onSelected: (suggestion) {
            final value = suggestion.toString();
            _controller.text = value;
            if (widget.onSelected != null) {
              widget.onSelected!(value);
            } else {
              widget.onChanged(value);
            }
            // Don't clear the controller - keep the selected value displayed
          },
          builder:
              widget.builderOverride ??
              (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: widget.keyboard,
                  maxLines: widget.maxLines,
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFFFC107),
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }
}
