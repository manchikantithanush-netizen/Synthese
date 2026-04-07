import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupertino_native/cupertino_native.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';

import 'package:synthese/main.dart'; 
import 'package:synthese/ui/components/premium_button.dart'; 

class AccountPageModal extends StatefulWidget {
  const AccountPageModal({super.key});
  @override
  State<AccountPageModal> createState() => _AccountPageModalState();
}

class _AccountPageModalState extends State<AccountPageModal> {
  final PageController _pageController = PageController();
  bool _isSigningOut = false;
  bool _isDeletingAccount = false;
  String _fullName = "..."; 
  Map<String, dynamic>? _userData;
  Widget _currentDetailView = const SizedBox();

  @override
  void initState() {
    super.initState();
    _fetchUserData(); 
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _fullName = _userData?['fullName'] ?? "Athlete"; 
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fullName = "Athlete");
    }
  }

  void _slideForward(Widget detailScreen) {
    setState(() => _currentDetailView = detailScreen);
    _pageController.animateToPage(1, duration: const Duration(milliseconds: 350), curve: Curves.fastOutSlowIn);
  }

  void _slideBack() => _pageController.animateToPage(0, duration: const Duration(milliseconds: 350), curve: Curves.fastOutSlowIn);

  Future<bool> _showDeleteAccountConfirmation(BuildContext context) async {
    bool result = false;
    await AdaptiveAlertDialog.show(
      context: context,
      title: 'Delete Account',
      message: 'Are you sure you want to delete your account? This will permanently delete all your data and cannot be undone.',
      icon: 'trash.fill',
      actions: [
        AlertAction(
          title: 'Cancel',
          style: AlertActionStyle.cancel,
          onPressed: () {},
        ),
        AlertAction(
          title: 'Delete',
          style: AlertActionStyle.destructive,
          onPressed: () {
            HapticFeedback.lightImpact();
            result = true;
          },
        ),
      ],
    );
    return result;
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showDeleteAccountConfirmation(context);
    if (!confirmed) return;

    setState(() => _isDeletingAccount = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Delete user data from Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

      // Delete the Firebase Auth account
      await user.delete();

      // Navigate to root/onboarding
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MyApp()),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() => _isDeletingAccount = false);
      if (context.mounted) {
        // Show error dialog
        AdaptiveAlertDialog.show(
          context: context,
          title: 'Error',
          message: 'Failed to delete account. Please try again or contact support.',
          icon: 'exclamationmark.triangle.fill',
          actions: [
            AlertAction(
              title: 'OK',
              style: AlertActionStyle.cancel,
              onPressed: () {},
            ),
          ],
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF5F5F5);

    return FractionallySizedBox(
      heightFactor: 0.93,
      child: Container(
        decoration: BoxDecoration(color: bgColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(38))),
        clipBehavior: Clip.antiAlias,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [ _buildMainScreen(isDark), _currentDetailView ],
        ),
      ),
    );
  }

  // ================= MAIN SCREEN =================
  Widget _buildMainScreen(bool isDark) {
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final hlColor = isDark ? Colors.white12 : Colors.black12;
    final textColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0, left: 20.0, right: 20.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CNButton.icon(icon: const CNSymbol('xmark'), style: CNButtonStyle.glass, onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); }),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(CupertinoIcons.person_crop_circle_fill, size: 100, color: Color(0xFF9AA0A6)),
                    ),
                    const SizedBox(height: 20),
                    Text(_fullName, style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20)),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _InstantRow(title: "Account Details", isDark: isDark, hlColor: hlColor, onTap: () { if (_userData != null) _slideForward(_buildAccountDetails()); }),
                          Padding(padding: const EdgeInsets.only(left: 20.0), child: Container(height: 0.5, color: hlColor)),
                          _InstantRow(title: "Health Details", isDark: isDark, hlColor: hlColor, onTap: () { if (_userData != null) _slideForward(_buildHealthDetails()); }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: PremiumButton(
                      text: "Sign Out", isLoading: _isSigningOut,
                      onPressed: () async {
                        setState(() => _isSigningOut = true);
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MyApp()), (_) => false);
                      },
                    ),
                  ),
                  PremiumButton(
                    text: "Delete Account",
                    isLoading: _isDeletingAccount,
                    onPressed: _deleteAccount,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DETAIL VIEWS =================
  Widget _buildAccountDetails() {
    String formatDate(dynamic d) => (d is Timestamp) ? "${d.toDate().day}/${d.toDate().month}/${d.toDate().year}" : d?.toString() ?? "Not provided";
    return _DetailLayout(
      title: "Account Details", onBack: _slideBack,
      children: [
        _buildDataGroup({"Full Name": _userData?['fullName'], "Gender": _userData?['gender'], "Date of Birth": formatDate(_userData?['dob'])}),
        const SizedBox(height: 24),
        _buildDataGroup({"Country": _userData?['country'], "Timezone": _userData?['timeZone']}),
      ],
    );
  }

  Widget _buildHealthDetails() {
    Widget title(String t) => Padding(padding: const EdgeInsets.only(left: 12, bottom: 8), child: Text(t, style: const TextStyle(fontSize: 13, color: Colors.grey)));
    String formatSports(dynamic s) => (s is List && s.isNotEmpty) ? s.join(', ') : "None selected";
    final bool hasSupp = _userData?['hasSupplements'] == true;
    final bool hasDis = _userData?['hasDisabilities'] == true;

    return _DetailLayout(
      title: "Health Details", onBack: _slideBack,
      children: [
        title("PHYSICAL STATS"),
        _buildDataGroup({"Height": "${_userData?['height'] ?? '--'} cm", "Weight": "${_userData?['weight'] ?? '--'} kg", "Body Fat %": "${_userData?['bodyFatPercentage'] ?? '--'}%", "Waist": "${_userData?['waistCircumference'] ?? '--'} cm"}),
        const SizedBox(height: 24),
        title("MEDICAL"),
        _buildDataGroup({"Supplements": hasSupp ? (_userData?['supplementsDetails'] ?? "Yes") : "None", "Disabilities": hasDis ? (_userData?['disabilityDetails'] ?? "Yes") : "None", "Injury History": (_userData?['injuryHistory']?.toString().isEmpty ?? true) ? "None" : _userData?['injuryHistory']}),
        const SizedBox(height: 24),
        title("SPORTS"),
        _buildDataGroup({"Selected Sports": formatSports(_userData?['selectedSports'])}),
      ],
    );
  }

  // ================= REUSABLE BUILDERS =================
  Widget _buildDataGroup(Map<String, dynamic> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = items.entries.toList();
    return Container(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2E) : Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: List.generate(entries.length, (index) {
          final valText = (entries[index].value == null || entries[index].value.toString().isEmpty) ? "Not provided" : entries[index].value.toString();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entries[index].key, style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(valText, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              if (index < entries.length - 1) Padding(padding: const EdgeInsets.only(left: 16.0), child: Container(height: 0.5, color: isDark ? Colors.white12 : Colors.black12)),
            ],
          );
        }),
      ),
    );
  }
}

// ================= COMPACT UI WIDGETS =================
class _DetailLayout extends StatelessWidget {
  final String title; final VoidCallback onBack; final List<Widget> children;
  const _DetailLayout({required this.title, required this.onBack, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 20.0, right: 20.0, bottom: 12.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(alignment: Alignment.centerLeft, child: CNButton.icon(icon: const CNSymbol('chevron.left'), style: CNButtonStyle.glass, onPressed: () { HapticFeedback.lightImpact(); onBack(); })),
                Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
              ],
            ),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: children)),
        ],
      ),
    );
  }
}

class _InstantRow extends StatefulWidget {
  final String title; final bool isDark; final Color hlColor; final VoidCallback onTap;
  const _InstantRow({required this.title, required this.isDark, required this.hlColor, required this.onTap});
  @override State<_InstantRow> createState() => _InstantRowState();
}

class _InstantRowState extends State<_InstantRow> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) { setState(() => _pressed = false); HapticFeedback.selectionClick(); widget.onTap(); },
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: Container(
        color: _pressed ? widget.hlColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title, style: TextStyle(color: widget.isDark ? Colors.white : Colors.black, fontSize: 16)),
            Icon(CupertinoIcons.chevron_forward, color: widget.isDark ? Colors.white30 : Colors.black26, size: 20),
          ],
        ),
      ),
    );
  }
}