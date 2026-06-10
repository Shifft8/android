import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String text;
  final String? intercomCode;
  final List<String>? notesList;
  final DateTime? createdAt;

  AddressModel({
    required this.id,
    required this.text,
    this.intercomCode,
    this.notesList,
    this.createdAt,
  });

  // ✅ Конструктор из Firestore документа
  factory AddressModel.fromFirestore(String id, Map<String, dynamic> data) {
    final rawNotes = data['notes'];

    List<String> parsedNotes;
    if (rawNotes is List) {
      parsedNotes = List<String>.from(rawNotes);
    } else if (rawNotes is String) {
      parsedNotes = [rawNotes];
    } else {
      parsedNotes = [];
    }

    return AddressModel(
      id: id,
      text: data['text'] ?? '',
      intercomCode: data['intercomCode'],
      notesList: parsedNotes,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }


  // ✅ Преобразование обратно в Map (для сохранения в Firestore)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'intercomCode': intercomCode,
      'notes': notesList ?? [],
      'createdAt': createdAt,
    };
  }

  // ✅ Создание копии с изменёнными данными
  AddressModel copyWith({
    String? text,
    String? intercomCode,
    List<String>? notesList,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id,
      text: text ?? this.text,
      intercomCode: intercomCode ?? this.intercomCode,
      notesList: notesList ?? this.notesList,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

