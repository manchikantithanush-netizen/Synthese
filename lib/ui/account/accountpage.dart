import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cupertino_native/cupertino_native.dart';

import 'package:synthese/main.dart';
import 'package:synthese/ui/components/universalbutton.dart';
import 'package:synthese/ui/components/universalbackbutton.dart';
import 'package:synthese/ui/components/universalclosebutton.dart';
import 'package:synthese/services/accent_color_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'about_app_page.dart';
import 'package:synthese/ui/components/app_toast.dart';
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
  String? _photoUrl;
  Widget _currentDetailView = const SizedBox();
  Widget _currentDetailView2 = const SizedBox();

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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _userData = doc.data();
          _fullName = _userData?['fullName'] ?? "Athlete";
          _photoUrl = _userData?['photoURL'] ?? FirebaseAuth.instance.currentUser?.photoURL;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fullName = "Athlete");
    }
  }

  void _slideForward(Widget detailScreen) {
    setState(() => _currentDetailView = detailScreen);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _slideBack() => _pageController.animateToPage(
    0,
    duration: const Duration(milliseconds: 350),
    curve: Curves.fastOutSlowIn,
  );

  void _slideForward2(Widget detailScreen) {
    setState(() => _currentDetailView2 = detailScreen);
    _pageController.animateToPage(
      2,
      duration: const Duration(milliseconds: 350),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _slideBack2() => _pageController.animateToPage(
    1,
    duration: const Duration(milliseconds: 350),
    curve: Curves.fastOutSlowIn,
  );

  Future<bool> _showDeleteAccountConfirmation(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF252528) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final mutedText = isDark ? Colors.white70 : Colors.black54;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Account', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to delete your account? This will permanently delete all your data and cannot be undone.',
          style: TextStyle(color: mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context, true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showDeleteAccountConfirmation(context);
    if (!confirmed) return;

    setState(() => _isDeletingAccount = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isDeletingAccount = false);
        return;
      }

      // Delete all app data from Firestore first (root fields + subcollections).
      await _deleteAllUserFirestoreData(user.uid);

      // Delete the Firebase Auth account
      try {
        await user.delete();
      } catch (authError) {
        // If auth delete fails (e.g., needs reauthentication), 
        // user data is already deleted, proceed to logout
        await FirebaseAuth.instance.signOut();
      }

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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xFF252528) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        final mutedText = isDark ? Colors.white70 : Colors.black54;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Error', style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
            content: Text(
              'Failed to delete account. Please try again or contact support.',
              style: TextStyle(color: mutedText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK', style: TextStyle(color: textColor)),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _deleteCollectionDocs({
    required CollectionReference<Map<String, dynamic>> collection,
    int batchSize = 400,
  }) async {
    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) {
        break;
      }
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteAllUserFirestoreData(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    // Delete nested debt payments first.
    final debtSnap = await userRef.collection('finance_debts').get();
    for (final debtDoc in debtSnap.docs) {
      await _deleteCollectionDocs(
        collection: debtDoc.reference.collection('payments'),
      );
    }

    // Delete all known user subcollections used by the app.
    await _deleteCollectionDocs(collection: userRef.collection('foodLogs'));
    await _deleteCollectionDocs(collection: userRef.collection('waterDaily'));
    await _deleteCollectionDocs(collection: userRef.collection('workout_sessions'));
    await _deleteCollectionDocs(collection: userRef.collection('mood_logs'));
    await _deleteCollectionDocs(
      collection: userRef.collection('morning_readiness'),
    );
    await _deleteCollectionDocs(collection: userRef.collection('cycles'));
    await _deleteCollectionDocs(collection: userRef.collection('dashboardDaily'));
    await _deleteCollectionDocs(collection: userRef.collection('finance_accounts'));
    await _deleteCollectionDocs(
      collection: userRef.collection('finance_categories'),
    );
    await _deleteCollectionDocs(
      collection: userRef.collection('finance_transactions'),
    );
    await _deleteCollectionDocs(collection: userRef.collection('finance_debts'));

    // Finally delete the root user document.
    await userRef.delete();
  }

  bool _canEditPhoto() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final providers = user.providerData.map((p) => p.providerId).toList();
    // Allow edit if signed in with password (email) or if google is not present
    return providers.contains('password') || !providers.contains('google.com');
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      final file = File(picked.path);
      final ref = FirebaseStorage.instance.ref().child('user_profile_photos').child('${user.uid}.jpg');
      final uploadSnapshot = await ref.putFile(file);
      final url = await uploadSnapshot.ref.getDownloadURL();
      // Update auth profile and Firestore record
      try { await user.updatePhotoURL(url); } catch (_) {}
      try { await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'photoURL': url}); } catch (_) {}
      if (mounted) setState(() => _photoUrl = url);
      if (context.mounted) {
        AppToast.success(context, 'Profile photo updated');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, 'Failed to upload photo');
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
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(38)),
        ),
        clipBehavior: Clip.antiAlias,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildMainScreen(isDark), _currentDetailView, _currentDetailView2],
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
              child: UniversalCloseButton(
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      alignment: Alignment.center,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) as ImageProvider : null,
                        child: _photoUrl == null
                            ? const Icon(
                                CupertinoIcons.person_crop_circle_fill,
                                size: 60,
                                color: Color(0xFF9AA0A6),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _fullName,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          _InstantRow(
                            title: "Account Details",
                            isDark: isDark,
                            hlColor: hlColor,
                            onTap: () {
                              if (_userData != null)
                                _slideForward(_buildAccountDetails());
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0),
                            child: Container(height: 0.5, color: hlColor),
                          ),
                          _InstantRow(
                            title: "Health Details",
                            isDark: isDark,
                            hlColor: hlColor,
                            onTap: () {
                              if (_userData != null)
                                _slideForward(_buildHealthDetails());
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Settings card
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _InstantRow(
                        title: "Settings",
                        isDark: isDark,
                        hlColor: hlColor,
                        onTap: () => _slideForward(_SettingsPage(onBack: _slideBack, onNavigate: _slideForward2, onNavigateBack: _slideBack2)),
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
                      text: "Sign Out",
                      isLoading: _isSigningOut,
                      onPressed: () async {
                        setState(() => _isSigningOut = true);
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted)
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MyApp()),
                            (_) => false,
                          );
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
    String formatDate(dynamic d) => (d is Timestamp)
        ? "${d.toDate().day}/${d.toDate().month}/${d.toDate().year}"
        : d?.toString() ?? "Not provided";
    return _DetailLayout(
      title: "Account Details",
      onBack: _slideBack,
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) as ImageProvider : null,
                child: _photoUrl == null
                    ? const Icon(
                        CupertinoIcons.person_crop_circle_fill,
                        size: 60,
                        color: Color(0xFF9AA0A6),
                      )
                    : null,
              ),
              if (_canEditPhoto())
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: InkWell(
                    onTap: _pickAndUploadImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        CupertinoIcons.pencil,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildDataGroup({
          "Full Name": _userData?['fullName'],
          "Gender": _userData?['gender'],
          "Date of Birth": formatDate(_userData?['dob']),
        }),
        const SizedBox(height: 24),
        _buildDataGroup({
          "Country": _userData?['country'],
          "Timezone": _userData?['timeZone'],
        }),
      ],
    );
  }

  Widget _buildHealthDetails() {
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(t, style: const TextStyle(fontSize: 13, color: Colors.grey)),
    );
    String formatSports(dynamic s) =>
        (s is List && s.isNotEmpty) ? s.join(', ') : "None selected";
    final bool hasSupp = _userData?['hasSupplements'] == true;
    final bool hasDis = _userData?['hasDisabilities'] == true;

    return _DetailLayout(
      title: "Health Details",
      onBack: _slideBack,
      children: [
        title("PHYSICAL STATS"),
        _buildDataGroup({
          "Height": "${_userData?['height'] ?? '--'} cm",
          "Weight": "${_userData?['weight'] ?? '--'} kg",
          "Body Fat %": "${_userData?['bodyFatPercentage'] ?? '--'}%",
          "Waist": "${_userData?['waistCircumference'] ?? '--'} cm",
        }),
        const SizedBox(height: 24),
        title("MEDICAL"),
        _buildDataGroup({
          "Supplements": hasSupp
              ? (_userData?['supplementsDetails'] ?? "Yes")
              : "None",
          "Disabilities": hasDis
              ? (_userData?['disabilityDetails'] ?? "Yes")
              : "None",
          "Injury History":
              (_userData?['injuryHistory']?.toString().isEmpty ?? true)
              ? "None"
              : _userData?['injuryHistory'],
        }),
        const SizedBox(height: 24),
        title("SPORTS"),
        _buildDataGroup({
          "Selected Sports": formatSports(_userData?['selectedSports']),
        }),
      ],
    );
  }

  // ================= REUSABLE BUILDERS =================
  Widget _buildDataGroup(Map<String, dynamic> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = items.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(entries.length, (index) {
          final valText =
              (entries[index].value == null ||
                  entries[index].value.toString().isEmpty)
              ? "Not provided"
              : entries[index].value.toString();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entries[index].key,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        valText,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < entries.length - 1)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ================= COMPACT UI WIDGETS =================
class _DetailLayout extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final List<Widget> children;
  const _DetailLayout({
    required this.title,
    required this.onBack,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 24.0,
              left: 20.0,
              right: 20.0,
              bottom: 12.0,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: UniversalBackButton(onPressed: onBack),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstantRow extends StatefulWidget {
  final String title;
  final bool isDark;
  final Color hlColor;
  final VoidCallback onTap;
  const _InstantRow({
    required this.title,
    required this.isDark,
    required this.hlColor,
    required this.onTap,
  });
  @override
  State<_InstantRow> createState() => _InstantRowState();
}

class _InstantRowState extends State<_InstantRow> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: Container(
        color: _pressed ? widget.hlColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              color: widget.isDark ? Colors.white30 : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SETTINGS PAGE — list of settings options
// ============================================================================

class _SettingsPage extends StatelessWidget {
  final VoidCallback onBack;
  final void Function(Widget) onNavigate;
  final VoidCallback onNavigateBack;
  const _SettingsPage({required this.onBack, required this.onNavigate, required this.onNavigateBack});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final hlColor = isDark ? Colors.white12 : Colors.black12;

    return _DetailLayout(
      title: 'Settings',
      onBack: onBack,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _InstantRow(
                title: "Change Theme",
                isDark: isDark,
                hlColor: hlColor,
                onTap: () => onNavigate(_ChangeThemePage(onBack: onNavigateBack)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Container(height: 0.5, color: hlColor),
              ),
              _InstantRow(
                title: "About App",
                isDark: isDark,
                hlColor: hlColor,
                onTap: () => onNavigate(AboutAppPage(onBack: onNavigateBack)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// CHANGE THEME PAGE — color picker
// ============================================================================

class _ChangeThemePage extends StatefulWidget {
  final VoidCallback onBack;
  const _ChangeThemePage({required this.onBack});

  @override
  State<_ChangeThemePage> createState() => _ChangeThemePageState();
}

class _ChangeThemePageState extends State<_ChangeThemePage> {
  late Color _selected;
  final TextEditingController _rCtrl = TextEditingController();
  final TextEditingController _gCtrl = TextEditingController();
  final TextEditingController _bCtrl = TextEditingController();
  bool _rgbError = false;

  @override
  void initState() {
    super.initState();
    _selected = AccentColor.notifier.value;
    _syncRgbFields(_selected);
  }

  @override
  void dispose() {
    _rCtrl.dispose();
    _gCtrl.dispose();
    _bCtrl.dispose();
    super.dispose();
  }

  void _syncRgbFields(Color c) {
    _rCtrl.text = c.red.toString();
    _gCtrl.text = c.green.toString();
    _bCtrl.text = c.blue.toString();
  }

  void _applyRgb() {
    final r = int.tryParse(_rCtrl.text);
    final g = int.tryParse(_gCtrl.text);
    final b = int.tryParse(_bCtrl.text);
    if (r == null || g == null || b == null ||
        r < 0 || r > 255 || g < 0 || g > 255 || b < 0 || b > 255) {
      setState(() => _rgbError = true);
      return;
    }
    setState(() {
      _rgbError = false;
      _selected = Color.fromARGB(255, r, g, b);
    });
    AccentColor.set(_selected);
    if (context.mounted) AppToast.success(context, 'Theme colour updated', icon: Icons.palette_rounded);
  }

  void _pick(Color c) {
    setState(() {
      _selected = c;
      _rgbError = false;
    });
    _syncRgbFields(c);
    AccentColor.set(c);
    if (context.mounted) AppToast.success(context, 'Theme colour updated', icon: Icons.palette_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subColor = isDark ? Colors.white54 : Colors.black45;
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final bgField = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7);

    return _DetailLayout(
      title: 'Change Theme',
      onBack: widget.onBack,
      children: [
        // ── Appearance mode toggle ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('APPEARANCE',
              style: TextStyle(
                  color: subColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        ),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: AccentColor.themeNotifier,
          builder: (context, currentMode, _) {
            return Container(
              decoration: BoxDecoration(
                  color: cardColor, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _ThemeModeRow(
                  icon: Icons.brightness_auto_rounded,
                  label: 'System Default',
                  selected: currentMode == ThemeMode.system,
                  textColor: textColor,
                  subColor: subColor,
                  isDark: isDark,
                  isLast: false,
                  onTap: () {
                    AccentColor.setThemeMode(ThemeMode.system);
                    if (context.mounted) AppToast.info(context, 'Following system theme', icon: Icons.brightness_auto_rounded);
                  },
                ),
                _ThemeModeRow(
                  icon: Icons.light_mode_rounded,
                  label: 'Light Mode',
                  selected: currentMode == ThemeMode.light,
                  textColor: textColor,
                  subColor: subColor,
                  isDark: isDark,
                  isLast: false,
                  onTap: () {
                    AccentColor.setThemeMode(ThemeMode.light);
                    if (context.mounted) AppToast.success(context, 'Light mode on', icon: Icons.light_mode_rounded);
                  },
                ),
                _ThemeModeRow(
                  icon: Icons.dark_mode_rounded,
                  label: 'Dark Mode',
                  selected: currentMode == ThemeMode.dark,
                  textColor: textColor,
                  subColor: subColor,
                  isDark: isDark,
                  isLast: true,
                  onTap: () {
                    AccentColor.setThemeMode(ThemeMode.dark);
                    if (context.mounted) AppToast.success(context, 'Dark mode on', icon: Icons.dark_mode_rounded);
                  },
                ),
              ]),
            );
          },
        ),
        const SizedBox(height: 24),

        // Preview
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _selected,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '#${_selected.value.toRadixString(16).substring(2).toUpperCase()}',
            style: TextStyle(
                color: subColor, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 24),

        // Presets
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('PRESETS',
              style: TextStyle(
                  color: subColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        ),
        Container(
          decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: AccentColor.presets.map((p) {
              final isActive = _selected.value == p.color.value;
              return GestureDetector(
                onTap: () => _pick(p.color),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: p.color,
                        shape: BoxShape.circle,
                        border: isActive
                            ? Border.all(
                                color: textColor, width: 2.5)
                            : null,
                        boxShadow: isActive
                            ? [BoxShadow(color: p.color.withOpacity(0.4), blurRadius: 8)]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(p.label,
                        style: TextStyle(
                            color: isActive ? textColor : subColor,
                            fontSize: 9,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w400)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Custom RGB
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text('CUSTOM RGB',
              style: TextStyle(
                  color: subColor, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        ),
        Container(
          decoration: BoxDecoration(
              color: cardColor, borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _RgbField(label: 'R', ctrl: _rCtrl, bg: bgField, textColor: textColor),
                  const SizedBox(width: 10),
                  _RgbField(label: 'G', ctrl: _gCtrl, bg: bgField, textColor: textColor),
                  const SizedBox(width: 10),
                  _RgbField(label: 'B', ctrl: _bCtrl, bg: bgField, textColor: textColor),
                ],
              ),
              if (_rgbError) ...[
                const SizedBox(height: 8),
                Text('Enter values 0–255 for each channel',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12)),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  color: _selected,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _applyRgb,
                  child: const Text('Apply',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _RgbField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final Color bg, textColor;

  const _RgbField({
    required this.label,
    required this.ctrl,
    required this.bg,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: textColor.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme mode selection row ──────────────────────────────────────────────────
class _ThemeModeRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color textColor, subColor;
  final bool isDark, isLast;
  final VoidCallback onTap;

  const _ThemeModeRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.textColor,
    required this.subColor,
    required this.isDark,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_ThemeModeRow> createState() => _ThemeModeRowState();
}

class _ThemeModeRowState extends State<_ThemeModeRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hlColor = widget.isDark ? Colors.white12 : Colors.black12;
    return Column(children: [
      Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) {
          setState(() => _pressed = false);
          HapticFeedback.selectionClick();
          widget.onTap();
        },
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: Container(
          color: _pressed ? hlColor : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(children: [
            Icon(widget.icon, color: widget.selected ? const Color(0xFF4CD964) : widget.subColor, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(widget.label,
                  style: TextStyle(
                      color: widget.textColor,
                      fontSize: 16,
                      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w400)),
            ),
            if (widget.selected)
              const Icon(Icons.check_rounded, color: Color(0xFF4CD964), size: 20),
          ]),
        ),
      ),
      if (!widget.isLast)
        Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Container(height: 0.5, color: widget.isDark ? Colors.white12 : Colors.black12),
        ),
    ]);
  }
}
