import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'edit_address_screen.dart';

class AddressDetailScreen extends StatefulWidget {
  final Map<String, String> addressItem;

  const AddressDetailScreen({super.key, required this.addressItem});

  @override
  State<AddressDetailScreen> createState() => _AddressDetailScreenState();
}

class _AddressDetailScreenState extends State<AddressDetailScreen> {
  // Локальный список заметок для демонстрации
  final List<String> _notes = [
    'Звонить в звонок два раза, код на воротах может не срабатывать с первого раза.',
    'Оставить материалы возле гаража под навесом.',
  ];

  // Функция для шаринга данных через share_plus
  void _shareAddress({required bool includeNotes}) {
    String textToSend = '📍 Адрес: ${widget.addressItem['title']}\n🔑 Код: ${widget.addressItem['code']}';

    if (includeNotes && _notes.isNotEmpty) {
      textToSend += '\n\n📝 Заметки:';
      for (int i = 0; i < _notes.length; i++) {
        textToSend += '\n${i + 1}. ${_notes[i]}';
      }
    }

    Share.share(textToSend);
  }

  // Окно выбора: как именно поделиться адресом
  void _showShareOptions() {
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
                onTap: () { // ✅ ИСПРАВЛЕНО: вместо onPressed теперь onTap
                  Navigator.pop(context);
                  _shareAddress(includeNotes: false);
                },
              ),
              if (_notes.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.amber),
                  title: const Text('Адрес вместе с заметками'),
                  onTap: () { // ✅ ИСПРАВЛЕНО: вместо onPressed теперь onTap
                    Navigator.pop(context);
                    _shareAddress(includeNotes: true);
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
  void _showNoteDialog({int? index}) {
    final isEditing = index != null;
    final controller = TextEditingController(
      text: isEditing ? _notes[index] : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEditing ? 'Редактировать заметку' : 'Новая заметка'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Введите text заметки...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  if (isEditing) {
                    _notes[index] = controller.text.trim();
                  } else {
                    _notes.add(controller.text.trim());
                  }
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Сохранить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _showShareOptions,
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
                          widget.addressItem['title'] ?? '',
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
                        'Код: ${widget.addressItem['code'] ?? ''}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[800], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditAddressScreen(
                                docId: 'test_id',
                                initialStreet: widget.addressItem['title']!,
                                initialCode: widget.addressItem['code']!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Редактировать'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showShareOptions,
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
                if (_notes.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.blue, size: 28),
                    onPressed: () => _showNoteDialog(),
                  ),
              ],
            ),
          ),

          // ─── СПИСОК ЗАМЕТОК ───
          Expanded(
            child: _notes.isEmpty
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
              itemCount: _notes.length,
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
                    title: Text(_notes[index], style: const TextStyle(fontSize: 15, height: 1.3)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                          onPressed: () => _showNoteDialog(index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            setState(() {
                              _notes.removeAt(index);
                            });
                          },
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
  }
}