import 'dart:convert';

import 'package:doc_genie/common/app_client.dart';
import 'package:doc_genie/constants/color_const.dart';
import 'package:doc_genie/constants/text_styles.dart';
import 'package:doc_genie/feature/auth/model/login_model.dart';
import 'package:doc_genie/feature/checker/screen/checker_screen.dart';
import 'package:doc_genie/feature/home/screen/home_screen.dart';
import 'package:doc_genie/feature/maker/screen/maker_screen.dart';
import 'package:doc_genie/services/secure_helper.dart';
import 'package:doc_genie/widgets/app_card.dart';
import 'package:flutter/material.dart';

class _Section {
  const _Section({
    required this.label,
    required this.icon,
    required this.subtitle,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final String subtitle;
  final Color accent;
}

const _makerSections = <_Section>[
  _Section(
    label: 'Home',
    icon: Icons.dashboard_customize_outlined,
    subtitle: 'Document processing overview and recent activity',
    accent: ColorConstants.primaryColor,
  ),
  _Section(
    label: 'Maker',
    icon: Icons.document_scanner_outlined,
    subtitle: 'Upload, scan, and submit banking documents',
    accent: ColorConstants.accentColor,
  ),
];

const _checkerSections = <_Section>[
  _Section(
    label: 'Home',
    icon: Icons.dashboard_customize_outlined,
    subtitle: 'Document processing overview and recent activity',
    accent: ColorConstants.primaryColor,
  ),
  _Section(
    label: 'Checker',
    icon: Icons.fact_check_outlined,
    subtitle: 'Review and authorise submitted documents',
    accent: ColorConstants.secondaryColor,
  ),
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  List<_Section> _sections = _makerSections;
  bool _isChecker = false;
  String _userName = '';
  String _empCode = '';
  // Side rail starts collapsed (closed); the user can expand it.
  bool _railExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final role = await SecureHelper.instance.getRole();
    final userJson = await SecureHelper.instance.getUser();
    UserModel? user;
    if (userJson != null && userJson.isNotEmpty) {
      try {
        user = UserModel.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _isChecker = role == 'checker';
      _sections = _isChecker ? _checkerSections : _makerSections;
      _userName = user?.name ?? '';
      _empCode = user?.employeeCode ?? '';
    });
  }

  void _select(int index) => setState(() => _index = index);

  Future<void> _logout() async {
    // Cancels the session, clears tokens, and returns to login (silently).
    await AppClient.instance.logout();
  }

  List<Widget> get _pages {
    if (_isChecker) {
      return [const HomeScreen(), const CheckerScreen()];
    }
    return [const HomeScreen(), const MakerScreen()];
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 860;
    final currentSection = _sections[_index];
    final showUserText = width >= 600 && _userName.isNotEmpty;
    final avatarLetter = _userName.isNotEmpty
        ? _userName[0].toUpperCase()
        : (_isChecker ? 'C' : 'M');

    return Scaffold(
      backgroundColor: ColorConstants.background,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: ColorConstants.surfaceDark,
              child: SafeArea(
                child: _SideNav(
                  index: _index,
                  sections: _sections,
                  onSelect: (index) {
                    _select(index);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isDesktop ? 74 : 66),
        child: AppBar(
          toolbarHeight: isDesktop ? 74 : 66,
          leading: isDesktop
              ? null
              : Builder(
                  builder: (context) => IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ),
          titleSpacing: isDesktop ? 24 : 8,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: ColorConstants.shellGradient,
              border: Border(bottom: BorderSide(color: ColorConstants.border)),
            ),
          ),
          title: const _ShellHeadline(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: PopupMenuButton<String>(
                tooltip: 'Account',
                onSelected: (value) {
                  if (value == 'logout') _logout();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Text(
                      _isChecker ? 'Checker Role' : 'Maker Role',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _isChecker
                            ? ColorConstants.secondaryColor
                            : ColorConstants.accentColor,
                      ),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: _AccountItem(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                    ),
                  ),
                ],
                child: Container(
                  padding: EdgeInsets.fromLTRB(showUserText ? 6 : 8, 6, 10, 6),
                  decoration: BoxDecoration(
                    color: ColorConstants.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: ColorConstants.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: ColorConstants.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: ColorConstants.primaryColor
                                  .withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          avatarLetter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (showUserText) ...[
                        const SizedBox(width: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 13.5,
                                  height: 1.1,
                                  color: ColorConstants.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_empCode.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (_isChecker
                                            ? ColorConstants.secondaryColor
                                            : ColorConstants.accentColor)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _empCode,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      letterSpacing: 0.3,
                                      fontWeight: FontWeight.w800,
                                      color: _isChecker
                                          ? ColorConstants.secondaryColor
                                          : ColorConstants.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ColorConstants.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: ColorConstants.shellGradient),
        child: Row(
          children: [
            if (isDesktop)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: _railExpanded ? 292 : 76,
                child: SafeArea(
                  child: _SideNav(
                    index: _index,
                    sections: _sections,
                    onSelect: _select,
                    collapsed: !_railExpanded,
                    onToggle: () =>
                        setState(() => _railExpanded = !_railExpanded),
                  ),
                ),
              ),
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    children: [
                      if (!isDesktop)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CompactSectionBanner(
                            section: currentSection,
                          ),
                        ),
                      Expanded(
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: SelectionArea(
                            child: IndexedStack(
                              index: _index,
                              children: _pages,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellHeadline extends StatelessWidget {
  const _ShellHeadline();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: ColorConstants.heroGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26183B5B),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.document_scanner_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text('DocGenie', style: AppTextStyles.title),
      ],
    );
  }
}

class _AccountItem extends StatelessWidget {
  const _AccountItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ColorConstants.textSecondary),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.index,
    required this.sections,
    required this.onSelect,
    this.collapsed = false,
    this.onToggle,
  });

  final int index;
  final List<_Section> sections;
  final ValueChanged<int> onSelect;
  final bool collapsed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorConstants.surfaceDark,
      child: ListView(
        padding: EdgeInsets.all(collapsed ? 10 : 18),
        children: [
          if (onToggle != null) ...[
            Align(
              alignment:
                  collapsed ? Alignment.center : Alignment.centerRight,
              child: IconButton(
                onPressed: onToggle,
                tooltip: collapsed ? 'Expand menu' : 'Collapse menu',
                icon: Icon(
                  collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: collapsed ? 4 : 8),
          ],
          for (var i = 0; i < sections.length; i++) ...[
            _NavTile(
              section: sections[i],
              selected: i == index,
              collapsed: collapsed,
              onTap: () => onSelect(i),
            ),
            const SizedBox(height: 8),
          ],
          if (!collapsed) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DocGenie',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scan banking documents, auto-fill fields, and route them through the Maker-Checker workflow.',
                    style: TextStyle(
                      color: Color(0xCCFFFFFF),
                      height: 1.5,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.section,
    required this.selected,
    required this.onTap,
    this.collapsed = false,
  });

  final _Section section;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Tooltip(
        message: section.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? section.accent.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(
                  section.icon,
                  color: selected ? Colors.white : const Color(0xCCFFFFFF),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? section.accent.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  section.icon,
                  color: selected ? Colors.white : const Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                    Text(
                      section.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSectionBanner extends StatelessWidget {
  const _CompactSectionBanner({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      backgroundColor: ColorConstants.surface,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: section.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(section.icon, color: section.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.label, style: AppTextStyles.subtitle),
                Text(section.subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
