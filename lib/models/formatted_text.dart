class FormattedText {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final int? fontSize;
  final String? color;

  FormattedText({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.fontSize,
    this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isBold': isBold,
      'isItalic': isItalic,
      'isUnderline': isUnderline,
      if (fontSize != null) 'fontSize': fontSize,
      if (color != null) 'color': color,
    };
  }

  factory FormattedText.fromJson(Map<String, dynamic> json) {
    return FormattedText(
      text: json['text'] as String,
      isBold: json['isBold'] as bool? ?? false,
      isItalic: json['isItalic'] as bool? ?? false,
      isUnderline: json['isUnderline'] as bool? ?? false,
      fontSize: json['fontSize'] as int?,
      color: json['color'] as String?,
    );
  }
}
