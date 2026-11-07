import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'add_address_screen.dart';

class AddressDetailScreen extends StatefulWidget {
  final Map<String, String> addressItem;

  const AddressDetailScreen({super.key, required this.addressItem});

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  late final Map<String, String> _address = Map.of(widget.addressItem);

  Future<void> _editAddress() async {
    final docId = _address['docId'];
    if (docId == null || docId.isEmpty) {
      _showError(AppLocalizations.of(context)!.error);
      return;
    }
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => AddressFormScreen(
        docId: docId,
        initialStreet: _address['street'],
        initialHouseNumber: _address['houseNumber'],
        initialCode: _address['code'],
      )),
    );
    if (!mounted || result == null) return;
    setState(() {
      _address.addAll(result);
      _address['title'] = '${result['street']} ${result['houseNumber']}'.trim();
    });
  }
  late final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late final String? _addressId = widget.addressItem['docId'];
  late final Stream<QuerySnapshot<Map<String, dynamic>>>? _notesStream =
      _uid == null || _addressId == null || _addressId!.isEmpty
          ? null
          : FirebaseFirestore.instance
              .collection('notes')
              .where('userId', isEqualTo: _uid)
              .where('addressId', isEqualTo: _addressId)
              .snapshots();

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${AppLocalizations.of(context)!.error}: $error'),
    ));
  }

  Future<void> _deleteNote(
      QueryDocumentSnapshot<Map<String, dynamic>> note) async {
    try {
      await note.reference.delete();
    } catch (error) {
      _showError(error);
    }
  }

  // Функция для шаринга данных через share_plus
  Future<void> _shareAddress(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> notes,
      {required bool includeNotes}) async {
    String textToSend =
        '📍 Адрес: ${_address['title']}\n🔑 Код: ${_address['code']}';

    if (includeNotes && notes.isNotEmpty) {
      textToSend += '\n\n📝 Заметки:';
      for (int i = 0; i < notes.length; i++) {
        textToSend += '\n${i + 1}. ${notes[i].data()['content'] ?? ''}';
      }
    }

    try {
      await Share.share(textToSend);
    } catch (error) {
      _showError(error);
    }
  }

  // Окно выбора: как именно поделиться адресом
  void _showShareOptions(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> notes) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Поделиться адресом',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.blue),
                title: const Text('Только адрес и код'),
                onTap: () {
                  // ✅ ИСПРАВЛЕНО: вместо onPressed теперь onTap
                  Navigator.pop(context);
                  _shareAddress(notes, includeNotes: false);
                },
              ),
              if (notes.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.amber),
                  title: const Text('Адрес вместе с заметками'),
                  onTap: () {
                    // ✅ ИСПРАВЛЕНО: вместо onPressed теперь onTap
                    Navigator.pop(context);
                    _shareAddress(notes, includeNotes: true);
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // Диалоговое окно для создания или редактирования заметки
  Future<void> _showNoteDialog(
      {QueryDocumentSnapshot<Map<String, dynamic>>? note}) async {
    if (_notesStream == null) return;
    final isEditing = note != null;
    String noteText = note?.data()['content'] as String? ?? '';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => PopScope(
              canPop: !saving,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title:
                    Text(isEditing ? 'Редактировать заметку' : 'Новая заметка'),
                content: TextFormField(
                  initialValue: noteText,
                  onChanged: (value) => noteText = value,
                  maxLines: 4,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Введите text заметки...',
                    border: OutlineInputBorder(),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed:
                        saving ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Отмена',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final content = noteText.trim();
                            if (content.isEmpty) return;
                            setDialogState(() => saving = true);
                            try {
                              if (note != null) {
                                await note.reference
                                    .update({'content': content});
                              } else {
                                await FirebaseFirestore.instance
                                    .collection('notes')
                                    .add({
                                  'userId': _uid,
                                  'addressId': _addressId,
                                  'addressTitle':
                                      _address['title'] ?? '',
                                  'title': content.split('\n').first,
                                  'content': content,
                                  'category': 'general',
                                  'timestamp': FieldValue.serverTimestamp(),
                                });
                              }
                              if (dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            } catch (error) {
                              _showError(error);
                            } finally {
                              if (context.mounted) {
                                setDialogState(() => saving = false);
                              }
                            }
                          },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text('Сохранить',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notesStream,
      builder: (context, snapshot) {
        final notes = snapshot.data?.docs ?? [];
        final loc = AppLocalizations.of(context)!;
        final notesReady =
            _notesStream != null && snapshot.hasData && !snapshot.hasError;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Детали адреса',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () => _showShareOptions(notesReady ? notes : []),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── КАРТОЧКА АДРЕСА ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _address['title'] ?? '',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Icon(Icons.vpn_key_outlined, color: Colors.amber, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Код: ${_address['code'] ?? ''}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _editAddress,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Редактировать'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showShareOptions(notesReady ? notes : []),
                        icon: const Icon(Icons.share, size: 18, color: Colors.white),
                        label: const Text('Поделиться', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── ЗАГОЛОВОК БЛОКА ЗАМЕТОК ───
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 16.0, top: 20.0, bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Заметки к объекту',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87), // ✅ ИСПРАВЛЕНО: Colors.black87 вместо black80
                ),
                if (notesReady && notes.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                    onPressed: () => _showNoteDialog(),
                  ),
              ],
            ),
          ),

          // ─── СПИСОК ЗАМЕТОК ───
          Expanded(
            child: _notesStream == null
                ? Center(child: Text(_uid == null ? loc.errorNoAuth : loc.error))
                : snapshot.hasError
                ? Center(child: Text('${loc.error}: ${snapshot.error}'))
                : !snapshot.hasData
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text('Заметок пока нет', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showNoteDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Добавить первую заметку', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: notes.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10), // ✅ ИСПРАВЛЕНО: EdgeInsets.only(bottom: 10) вместо EdgeInsets.bottom
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: ListTile(
                    title: Text(notes[index].data()['content'] as String? ?? '', style: const TextStyle(fontSize: 15, height: 1.3)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                          onPressed: () => _showNoteDialog(note: notes[index]),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteNote(notes[index]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}
