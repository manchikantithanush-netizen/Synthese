import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MorePage extends StatefulWidget {
  final bool isFemale;
  final ValueChanged<int> onSelectTab;

  const MorePage({
    super.key,
    required this.isFemale,
    required this.onSelectTab,
  });

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar({
    required Color cardColor,
    required Color textColor,
    required Color subTextColor,
    required bool isDark,
  }) {
    final searchBg = isDark ? cardColor : const Color(0xFFF4F4F6);
    return Container(
      decoration: BoxDecoration(
        color: searchBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: TextStyle(color: textColor, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Search sections...',
          hintStyle: TextStyle(color: subTextColor, fontSize: 16),
          prefixIcon: Icon(
            CupertinoIcons.search,
            color: subTextColor,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: subTextColor,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF5F5F5);
    final hlColor = isDark ? Colors.white12 : Colors.black12;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = textColor.withValues(alpha: 0.5);
    final safePadding = MediaQuery.of(context).padding;
    final query = _searchQuery.trim().toLowerCase();
    final items =
        <_MoreEntry>[
          _MoreEntry(title: 'Mindfulness', tabIndex: 4),
          _MoreEntry(title: 'Finance', tabIndex: 5),
          if (widget.isFemale) _MoreEntry(title: 'Cycles', tabIndex: 6),
        ].where((item) {
          if (query.isEmpty) return true;
          return item.title.toLowerCase().contains(query);
        }).toList();

    return SingleChildScrollView(
      key: const ValueKey('more_tab'),
      padding: EdgeInsets.only(
        top: safePadding.top + 24.0,
        bottom: safePadding.bottom + 120.0,
        left: 24.0,
        right: 24.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More',
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchBar(
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: items.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 20.0,
                        ),
                        child: Text(
                          'No results',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ]
                  : List.generate(items.length, (index) {
                      final item = items[index];
                      return Column(
                        children: [
                          _MoreMenuItem(
                            title: item.title,
                            isDark: isDark,
                            hlColor: hlColor,
                            onTap: () {
                              widget.onSelectTab(item.tabIndex);
                            },
                          ),
                          if (index < items.length - 1)
                            _MenuDivider(isDark: isDark),
                        ],
                      );
                    }),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color hlColor;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.title,
    required this.isDark,
    required this.hlColor,
    required this.onTap,
  });

  IconData _getIconForTitle(String title) {
    switch (title) {
      case 'Mindfulness':
        return CupertinoIcons.heart;
      case 'Finance':
        return CupertinoIcons.money_dollar_circle;
      case 'Cycles':
        return CupertinoIcons.calendar;
      default:
        return CupertinoIcons.info_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InstantRow(
      title: title,
      isDark: isDark,
      hlColor: hlColor,
      onTap: onTap,
      icon: _getIconForTitle(title),
    );
  }
}

class _InstantRow extends StatefulWidget {
  final String title;
  final bool isDark;
  final Color hlColor;
  final VoidCallback onTap;
  final IconData icon;

  const _InstantRow({
    required this.title,
    required this.isDark,
    required this.hlColor,
    required this.onTap,
    required this.icon,
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
            Row(
              children: [
                Icon(
                  widget.icon,
                  color: widget.isDark ? Colors.white70 : Colors.black54,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
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

class _MenuDivider extends StatelessWidget {
  final bool isDark;

  const _MenuDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: isDark ? const Color(0x40FFFFFF) : const Color(0x26000000),
    );
  }
}

class _MoreEntry {
  final String title;
  final int tabIndex;

  const _MoreEntry({required this.title, required this.tabIndex});
}
