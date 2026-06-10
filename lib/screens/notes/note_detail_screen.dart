import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoteDetailScreen extends StatelessWidget {
  final String noteId;
  final Map<String, dynamic> noteData;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
    required this.noteData,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final noteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notes')
        .doc(noteId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _editNoteDialog(
                  context, noteRef, noteData['text'], noteData['title']);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await noteRef.delete();

              if (!context.mounted) return; // ✅ проверка
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noteData['title'] ?? 'Без названия',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(noteData['text'] ?? ''),
                const SizedBox(height: 10),
                if (noteData['createdAt'] != null)
                  Text("Создана: ${noteData['createdAt'].toDate()}"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editNoteDialog(BuildContext context, DocumentReference noteRef,
      String? oldText, String? oldTitle) {
    final titleController = TextEditingController(text: oldTitle ?? '');
    final textController = TextEditingController(text: oldText ?? '');
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Редактировать заметку"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Заголовок"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(labelText: "Текст"),
                  maxLines: 4,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("Отмена")),
              ElevatedButton(
                onPressed: () async {
                  await noteRef.update({
                    'title': titleController.text.trim(),
                    'text': textController.text.trim(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (!context.mounted) return; // ✅ проверка
                  Navigator.pop(context);
                },
                child: const Text("Сохранить"),
              ),
            ],
          ),
    );
  }
}
