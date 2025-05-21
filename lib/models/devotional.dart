import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/formatted_text.dart';
import '../components/custom_text_editor.dart';

class Devotional {
  final String id;
  final DateTime date;
  final String title;
  final List<FormattedText> content;
  final String scriptureFocus;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Devotional({
    required this.id,
    required this.date,
    required this.title,
    required this.content,
    required this.scriptureFocus,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'title': title,
      'content': content.map((item) => item.toJson()).toList(),
      'scriptureFocus': scriptureFocus,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'] ?? '',
      date: DateTime.parse(json['date']),
      title: json['title'] ?? '',
      content:
          (json['content'] as List<dynamic>?)
              ?.map((item) => FormattedText.fromJson(item))
              .toList() ??
          [],
      scriptureFocus: json['scriptureFocus'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  factory Devotional.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Devotional(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'] ?? '',
      content:
          (data['content'] as List<dynamic>?)
              ?.map((item) => FormattedText.fromJson(item))
              .toList() ??
          [],
      scriptureFocus: data['scriptureFocus'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'title': title,
      'content': content.map((item) => item.toJson()).toList(),
      'scriptureFocus': scriptureFocus,
      'tags': tags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Devotional copyWith({
    String? id,
    DateTime? date,
    String? title,
    List<FormattedText>? content,
    String? scriptureFocus,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Devotional(
      id: id ?? this.id,
      date: date ?? this.date,
      title: title ?? this.title,
      content: content ?? this.content,
      scriptureFocus: scriptureFocus ?? this.scriptureFocus,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
