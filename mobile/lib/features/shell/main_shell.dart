import 'package:flutter/material.dart';

import '../../core/models/listing.dart';
import '../../core/state/app_scope.dart';
import '../../shared/ui.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../listings/listing_detail_screen.dart';
import '../listings/listing_editor_screen.dart';
import '../listings/listings_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _listingsRevision = 0;

  Future<void> _openListingEditor() async {
    final controller = AppScope.of(context);

    if (controller.currentUser == null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!mounted || controller.currentUser == null) return;
    }

    final user = controller.currentUser!;
    if (!user.isSellerApproved && user.role != 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'İlan verebilmek için admin tarafından satıcı onayı almalısınız.'),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<Listing>(
      MaterialPageRoute(builder: (_) => const ListingEditorScreen()),
    );
    if (!mounted || result == null) return;

    setState(() => _listingsRevision++);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(listingId: result.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    if (controller.isLoading) {
      return const Scaffold(
        body: LuxuryBackdrop(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final pages = <Widget>[
      const HomeScreen(),
      ListingsScreen(key: ValueKey(_listingsRevision)),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: LuxuryBackdrop(
        child: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: pages,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'İlan Ekle',
        onPressed: _openListingEditor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        color: const Color(0xFF0B1017),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                Expanded(
                  child: _BottomDestination(
                    icon: Icons.home_rounded,
                    label: 'Ana Sayfa',
                    selected: _index == 0,
                    onTap: () => setState(() => _index = 0),
                  ),
                ),
                Expanded(
                  child: _BottomDestination(
                    icon: Icons.apartment_rounded,
                    label: 'İlanlar',
                    selected: _index == 1,
                    onTap: () => setState(() => _index = 1),
                  ),
                ),
                const SizedBox(width: 72),
                Expanded(
                  child: _BottomDestination(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Mesajlar',
                    selected: _index == 2,
                    badgeCount: controller.unreadCount,
                    onTap: () => setState(() => _index = 2),
                  ),
                ),
                Expanded(
                  child: _BottomDestination(
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    selected: _index == 3,
                    onTap: () => setState(() => _index = 3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomDestination extends StatelessWidget {
  const _BottomDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFD6B367) : const Color(0xFFA9B3C8);
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text('$badgeCount'),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
