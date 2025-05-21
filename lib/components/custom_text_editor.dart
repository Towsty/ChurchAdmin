import 'package:flutter/material.dart';
import '../models/formatted_text.dart';

class CustomTextEditor extends StatefulWidget {
  final List<FormattedText> initialContent;
  final Function(List<FormattedText>) onChanged;
  final bool readOnly;

  const CustomTextEditor({
    super.key,
    required this.initialContent,
    required this.onChanged,
    this.readOnly = false,
  });

  @override
  State<CustomTextEditor> createState() => _CustomTextEditorState();
}

class _CustomTextEditorState extends State<CustomTextEditor> {
  late TextEditingController _controller;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialContent.map((e) => e.text).join('\n'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateContent() {
    final text = _controller.text;
    final formattedText = FormattedText(
      text: text,
      isBold: _isBold,
      isItalic: _isItalic,
      isUnderline: _isUnderline,
      fontSize: _fontSize.toInt(),
    );
    widget.onChanged([formattedText]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            widget.initialContent.map((text) {
              final style = TextStyle(
                fontWeight: text.isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: text.isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: text.isUnderline ? TextDecoration.underline : null,
                fontSize: text.fontSize?.toDouble(),
                color:
                    text.color != null ? Color(int.parse(text.color!)) : null,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(text.text, style: style),
              );
            }).toList(),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.format_bold,
                  color: _isBold ? Theme.of(context).primaryColor : null,
                ),
                onPressed: () {
                  setState(() {
                    _isBold = !_isBold;
                    _updateContent();
                  });
                },
                tooltip: 'Bold',
              ),
              IconButton(
                icon: Icon(
                  Icons.format_italic,
                  color: _isItalic ? Theme.of(context).primaryColor : null,
                ),
                onPressed: () {
                  setState(() {
                    _isItalic = !_isItalic;
                    _updateContent();
                  });
                },
                tooltip: 'Italic',
              ),
              IconButton(
                icon: Icon(
                  Icons.format_underline,
                  color: _isUnderline ? Theme.of(context).primaryColor : null,
                ),
                onPressed: () {
                  setState(() {
                    _isUnderline = !_isUnderline;
                    _updateContent();
                  });
                },
                tooltip: 'Underline',
              ),
              const VerticalDivider(),
              IconButton(
                icon: const Icon(Icons.text_decrease),
                onPressed: () {
                  setState(() {
                    _fontSize = (_fontSize - 2).clamp(12.0, 32.0);
                    _updateContent();
                  });
                },
                tooltip: 'Decrease font size',
              ),
              Text(_fontSize.toInt().toString()),
              IconButton(
                icon: const Icon(Icons.text_increase),
                onPressed: () {
                  setState(() {
                    _fontSize = (_fontSize + 2).clamp(12.0, 32.0);
                    _updateContent();
                  });
                },
                tooltip: 'Increase font size',
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
            ),
            child: TextField(
              controller: _controller,
              maxLines: null,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
                hintText: 'Enter your content here...',
              ),
              style: TextStyle(
                fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: _isUnderline ? TextDecoration.underline : null,
                fontSize: _fontSize,
              ),
              onChanged: (_) => _updateContent(),
            ),
          ),
        ),
      ],
    );
  }
}
