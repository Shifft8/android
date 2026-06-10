import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import 'package:address_manager/l10n/app_localizations.dart';

class AddressDetailScreenIOS extends StatefulWidget {
  final String addressId;
  final Map<String, dynamic> addressData;

  const AddressDetailScreenIOS({
    super.key,
    required this.addressId,
    required this.addressData,
  });

  @override
  State<AddressDetailScreenIOS> createState() => _AddressDetailScreenIOSState();
}

class _AddressDetailScreenIOSState extends State<AddressDetailScreenIOS> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  LatLng? _coords;
  String? _city;
  String? _country;

  @override
  void initState() {
    super.initState();
    if (widget.addressData.containsKey('latitude') &&
        widget.addressData.containsKey('longitude')) {
      final lat = widget.addressData['latitude'];
      final lng = widget.addressData['longitude'];
      _coords = LatLng(lat, lng);
      _loadPlacemark(lat, lng);
    } else {
      _resolveAddressToCoords();
    }
  }

  Future<void> _resolveAddressToCoords() async {
    final street = widget.addressData['street'] ?? '';
    final house = widget.addressData['house'] ?? '';
    final city = widget.addressData['city'] ?? '';
    final country = widget.addressData['country'] ?? '';
    final fullAddress = "$street $house, $city, $country";
    try {
      final locations = await locationFromAddress(fullAddress);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _coords = LatLng(loc.latitude, loc.longitude);
        });
        _loadPlacemark(loc.latitude, loc.longitude);
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('addresses')
            .doc(widget.addressId)
            .set({
          'latitude': loc.latitude,
          'longitude': loc.longitude,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Ошибка геокодирования: $e");
    }
  }

  Future<void> _loadPlacemark(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      final place = placemarks.first;
      setState(() {
        _city = place.locality;
        _country = place.country;
      });
    } catch (e) {
      debugPrint("Ошибка обратного геокодинга: $e");
    }
  }

  Future<void> _launchMaps({required bool car}) async {
    final lat = _coords?.latitude;
    final lng = _coords?.longitude;
    if (lat == null || lng == null) return;
    Uri uri;
    if (Platform.isAndroid) {
      uri = Uri.parse("geo:$lat,$lng?q=$lat,$lng");
    } else {
      uri = Uri.parse("maps://?daddr=$lat,$lng&dirflg=${car ? 'd' : 'r'}");
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final web = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=${car ? 'driving' : 'transit'}",
      );
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareAddressWithSelection(List<QueryDocumentSnapshot> notes) async {
    final selected = <QueryDocumentSnapshot>[];
    final loc = AppLocalizations.of(context)!;
    await showCupertinoDialog<List<QueryDocumentSnapshot>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return CupertinoAlertDialog(
              title: Text(loc.selectNotesForSharing),
              content: Column(
                children: notes.map((note) {
                  final data = note.data() as Map<String, dynamic>;
                  final text = data['text'] ?? '';
                  final isSelected = selected.contains(note);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selected.remove(note);
                        } else {
                          selected.add(note);
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                          color: isSelected
                              ? CupertinoColors.activeBlue
                              : CupertinoColors.systemGrey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(text)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text(loc.cancel),
                  onPressed: () => Navigator.pop(ctx, null),
                ),
                CupertinoDialogAction(
                  child: Text(loc.share),
                  onPressed: () => Navigator.pop(ctx, selected),
                ),
              ],
            );
          },
        );
      },
    );
    final street = widget.addressData['street'] ?? '';
    final house = widget.addressData['house'] ?? '';
    final code = widget.addressData['code'] ?? '';
    String shareText = "${loc.address}: $street $house, ${loc.code}: $code";
    if (_city != null) shareText += ", ${loc.city}: $_city";
    if (_country != null) shareText += ", ${loc.country}: $_country";
    if (selected.isNotEmpty) {
      shareText += "\n\n${loc.notes}:";
      for (var note in selected) {
        final data = note.data() as Map<String, dynamic>;
        shareText += "\n- ${data['text']}";
      }
    }
    await Share.share(shareText);
  }

  Future<void> _addNoteDialog() async {
    final controller = TextEditingController();
    final loc = AppLocalizations.of(context)!;
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(loc.newNote),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              placeholder: loc.enterNoteText,
              minLines: 3,
              maxLines: 6,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(loc.cancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: Text(loc.add),
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('addresses')
                    .doc(widget.addressId)
                    .collection('notes')
                    .add({
                  'text': controller.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editNoteDialog(DocumentReference ref, String oldText) async {
    final controller = TextEditingController(text: oldText);
    final loc = AppLocalizations.of(context)!;
    await showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(loc.editNote),
        content: Column(
          children: [
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: controller,
              minLines: 3,
              maxLines: 6,
              placeholder: loc.changeNoteText,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(loc.cancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            child: Text(loc.save),
            onPressed: () async {
              await ref.update({'text': controller.text.trim()});
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(DocumentReference ref) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(loc.deleteNoteQuestion),
        content: Text(loc.deleteNoteWarning),
        actions: [
          CupertinoDialogAction(
            child: Text(loc.cancel),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text(loc.delete),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final street = widget.addressData['street'] ?? '';
    final house = widget.addressData['house'] ?? '';
    final code = widget.addressData['code'] ?? '';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(loc.addressDetails),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.share,
            size: 26,
            color: CupertinoColors.activeBlue,
          ),
          onPressed: () async {
            final notes = await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('addresses')
                .doc(widget.addressId)
                .collection('notes')
                .get();
            _shareAddressWithSelection(notes.docs);
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 📄 адрес + город/страна
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(street,
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Text(house,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text("${loc.code}: $code",
                      style: const TextStyle(
                          fontSize: 18, color: CupertinoColors.systemGrey)),
                  const SizedBox(height: 12),
                  if (_city != null)
                    Row(children: [
                      const Text("🏙️ ", style: TextStyle(fontSize: 18)),
                      Text(_city!,
                          style: const TextStyle(
                              fontSize: 18, color: CupertinoColors.systemGrey)),
                    ]),
                  if (_country != null)
                    Row(children: [
                      const Text("🌍 ", style: TextStyle(fontSize: 18)),
                      Text(_country!,
                          style: const TextStyle(
                              fontSize: 18, color: CupertinoColors.systemGrey)),
                    ]),
                ],
              ),
            ),

            Container(height: 1, color: CupertinoColors.systemGrey4),

            // 🗺️ карта
            SizedBox(
              height: 200,
              child: _coords == null
                  ? const Center(child: CupertinoActivityIndicator())
                  : FlutterMap(
                options: MapOptions(
                  initialCenter: _coords!,
                  initialZoom: 17,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                    "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.address_manager',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _coords!,
                        child: const Icon(
                          CupertinoIcons.location_solid,
                          color: CupertinoColors.systemRed,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🚗 кнопки навигации
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CupertinoButton.filled(
                    child: Text(loc.navigationCar),
                    onPressed: () => _launchMaps(car: true),
                  ),
                  CupertinoButton.filled(
                    child: Text(loc.navigationTransit),
                    onPressed: () => _launchMaps(car: false),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: CupertinoColors.systemGrey4),

            // 📝 заголовок заметок
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.square_pencil,
                      size: 22, color: CupertinoColors.activeBlue),
                  const SizedBox(width: 8),
                  Text(
                    loc.notes,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),

            // 📝 список заметок
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(_auth.currentUser!.uid)
                    .collection('addresses')
                    .doc(widget.addressId)
                    .collection('notes')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  final notes = snapshot.data!.docs;
                  if (notes.isEmpty) {
                    return Center(
                      child: Text(
                        loc.noNotes,
                        style: const TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      final data = note.data() as Map<String, dynamic>;
                      final text = data['text'] ?? '';
                      final timestamp = data['createdAt'] as Timestamp?;
                      final date = timestamp != null
                          ? DateTime.fromMillisecondsSinceEpoch(
                          timestamp.millisecondsSinceEpoch)
                          : null;
                      final formattedDate = date != null
                          ? "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}"
                          : "";

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formattedDate.isNotEmpty
                                      ? "${loc.added}: $formattedDate"
                                      : "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                Row(
                                  children: [
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: const Icon(CupertinoIcons.pencil),
                                      onPressed: () =>
                                          _editNoteDialog(note.reference, text),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: const Icon(CupertinoIcons.delete),
                                      onPressed: () =>
                                          _deleteNote(note.reference),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // ➕ кнопка добавления заметки
            Padding(
              padding: const EdgeInsets.all(12),
              child: CupertinoButton.filled(
                child: Text(loc.addNote),
                onPressed: _addNoteDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
