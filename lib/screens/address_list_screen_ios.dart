import 'package:flutter/cupertino.dart';
import 'package:address_manager/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AddressListScreenIOS extends StatelessWidget {
  const AddressListScreenIOS({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final loc = AppLocalizations.of(context)!;

    if (uid == null) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text(loc.addressList)),
        child: Center(child: Text(loc.noAuth)),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(loc.myAddresses)),
      child: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('addresses')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text(loc.noAddressesYet));
            }

            final addresses = snapshot.data!.docs;

            return ListView.builder(
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final data = addresses[index].data() as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${loc.street}: ${data['street'] ?? ''}",
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(
                        "${loc.house}: ${data['house'] ?? ''}, ${loc.code}: ${data['code'] ?? ''}",
                        style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
