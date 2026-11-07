import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedCategory = 'general'; // general, access, parking
  String? _selectedAddressId;
  String? _selectedAddressTitle;

  List<Map<String, dynamic>> _userAddresses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserAddresses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAddresses() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('addresses')
          .where('userId', isEqualTo: uid)
          .get();

      final addresses = snapshot.docs.map((doc) {
        final data = doc.data();
        final street = data['street'] ?? '';
        final house = data['houseNumber'] ?? '';
        return {
          'id': doc.id,
          'display': '$street $house'.trim(),
        };
      }).toList();

      setState(() {
        _userAddresses = addresses;
      });
    } catch (e) {
      print('Error loading addresses for notes: $e');
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('notes').add({
        'userId': uid,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'addressId': _selectedAddressId,
        'addressTitle': _selectedAddressTitle,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.added)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final String currentLang = Localizations.localeOf(context).languageCode;

    String titleLabel = 'Название';
    String categoryLabel = 'Категория';
    String hintText = 'Введите текст заметки...';
    String noteLabel = 'Заметка';
    String accessLabel = 'Код / Вход';
    String parkingLabel = 'Парковка';
    String noAddressLabel = 'Без адреса';
    String noAddressHint = 'Не привязывать к адресу';

    if (currentLang == 'pl') {
      titleLabel = 'Tytuł';
      categoryLabel = 'Kategoria';
      hintText = 'Wpisz treść notatki...';
      noteLabel = 'Notatka';
      accessLabel = 'Kod / Wejście';
      parkingLabel = 'Parking';
      noAddressLabel = 'Bez adresu';
      noAddressHint = 'Nie przypisuj do adresu';
    } else if (currentLang == 'en') {
      titleLabel = 'Title';
      categoryLabel = 'Category';
      hintText = 'Enter note content...';
      noteLabel = 'Note';
      accessLabel = 'Code / Access';
      parkingLabel = 'Parking';
      noAddressLabel = 'No address';
      noAddressHint = 'Do not link to address';
    } else if (currentLang == 'uk') {
      titleLabel = 'Назва';
      categoryLabel = 'Категорія';
      hintText = 'Введіть текст нотатки...';
      noteLabel = 'Нотатка';
      accessLabel = 'Код / Вхід';
      parkingLabel = 'Парковка';
      noAddressLabel = 'Без адреси';
      noAddressHint = 'Не прив\'язувати до адреси';
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          loc.newNote,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCardWrapper(
                child: TextFormField(
                  controller: _titleController,
                  validator: (value) => value == null || value.trim().isEmpty ? loc.error : null,
                  decoration: InputDecoration(
                    labelText: titleLabel,
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.title, color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(categoryLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryButton('general', Icons.description, noteLabel),
                  _buildCategoryButton('access', Icons.vpn_key, accessLabel),
                  _buildCategoryButton('parking', Icons.local_parking, parkingLabel),
                ],
              ),
              const SizedBox(height: 20),

              Text(loc.selectNotesForSharing, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildCardWrapper(
                child: DropdownButtonFormField<String>(
                  value: _selectedAddressId,
                  hint: Text(noAddressHint, style: const TextStyle(color: Colors.black38)),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                    border: InputBorder.none,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text(noAddressLabel),
                    ),
                    ..._userAddresses.map((addr) {
                      return DropdownMenuItem<String>(
                        value: addr['id'],
                        child: Text(addr['display']),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedAddressId = value;
                      if (value == null) {
                        _selectedAddressTitle = null;
                      } else {
                        _selectedAddressTitle = _userAddresses.firstWhere((a) => a['id'] == value)['display'];
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              _buildCardWrapper(
                child: TextFormField(
                  controller: _contentController,
                  maxLines: 6,
                  validator: (value) => value == null || value.trim().isEmpty ? loc.error : null,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _saveNote,
                icon: const Icon(Icons.save, color: Colors.white),
                label: Text(
                  loc.save,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCategoryButton(String category, IconData icon, String label) {
    final isSelected = _selectedCategory == category;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.blue),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}