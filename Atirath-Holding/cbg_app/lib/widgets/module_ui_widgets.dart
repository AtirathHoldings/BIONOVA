import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/header.dart';
import '../services/api_service.dart';

class ModuleSubmoduleItem {
  final String key;
  final String title;
  final String shortLabel;
  final String? category;
  final IconData icon;
  final bool isComingSoon;

  const ModuleSubmoduleItem({
    required this.key,
    required this.title,
    required this.shortLabel,
    this.category,
    required this.icon,
    this.isComingSoon = false,
  });
}

class ModuleShellScaffold extends StatefulWidget {
  final String headerTitle;
  final String moduleName;
  final List<ModuleSubmoduleItem> submodules;
  final String activeKey;
  final ValueChanged<String> onSelectSubmodule;
  final bool hasAccess;
  final bool isLoadingPermissions;
  final String accessDeniedMessage;
  final Widget child;

  const ModuleShellScaffold({
    super.key,
    required this.headerTitle,
    required this.moduleName,
    required this.submodules,
    required this.activeKey,
    required this.onSelectSubmodule,
    required this.hasAccess,
    this.isLoadingPermissions = false,
    required this.accessDeniedMessage,
    required this.child,
  });

  @override
  State<ModuleShellScaffold> createState() => _ModuleShellScaffoldState();
}

class _ModuleShellScaffoldState extends State<ModuleShellScaffold> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifCount();
  }

  Future<void> _loadNotifCount() async {
    try {
      final list = await ApiService.getUnreadNotifications();
      if (mounted) setState(() => _unreadCount = list.length);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final activeMeta = widget.submodules.firstWhere(
      (s) => s.key == widget.activeKey,
      orElse: () => widget.submodules.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomHeader(
        title: widget.headerTitle,
        automaticallyImplyLeading: false,
        notificationCount: _unreadCount,
        onNotificationTap: () async {
          await Navigator.pushNamed(context, '/notifications');
          _loadNotifCount();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Back & Breadcrumb Bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacementNamed(context, '/main');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_ios_new, size: 13, color: AppColors.textDark),
                          const SizedBox(width: 4),
                          Text(
                            'Menu',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            widget.moduleName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (activeMeta.category != null) ...[
                            const Icon(Icons.chevron_right, size: 15, color: AppColors.textLight),
                            Text(
                              activeMeta.category!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const Icon(Icons.chevron_right, size: 15, color: AppColors.textLight),
                          Text(
                            activeMeta.shortLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.accentBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (activeMeta.isComingSoon) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Soon',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Submodule horizontal pill switcher
            if (widget.hasAccess && !widget.isLoadingPermissions)
              Container(
                height: 46,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF1F5F9)),
                    bottom: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  itemCount: widget.submodules.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final item = widget.submodules[idx];
                    final isSelected = item.key == widget.activeKey;
                    return GestureDetector(
                      onTap: () => widget.onSelectSubmodule(item.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              size: 14,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.shortLabel,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Main Content
            Expanded(
              child: widget.isLoadingPermissions
                  ? const Center(child: CircularProgressIndicator())
                  : (!widget.hasAccess
                      ? _buildAccessDenied()
                      : widget.child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
              ),
              child: const Icon(Icons.lock_outline, size: 38, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 18),
            Text(
              'Access Denied',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.accessDeniedMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModuleKpiItem {
  final String label;
  final String value;
  final String subtext;
  final Color accentColor;
  final Color? valueColor;
  final IconData icon;
  final VoidCallback? onTap;

  const ModuleKpiItem({
    required this.label,
    required this.value,
    required this.subtext,
    required this.accentColor,
    this.valueColor,
    required this.icon,
    this.onTap,
  });
}

class ModuleKpiGrid extends StatelessWidget {
  final List<ModuleKpiItem> items;

  const ModuleKpiGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.48,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: item.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.icon, size: 16, color: item.accentColor),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: item.valueColor ?? const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  item.subtext,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: item.accentColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ModuleAlertBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color borderColor;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ModuleAlertBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.borderColor = const Color(0xFFEA580C),
    this.bgColor = const Color(0xFFFFF7ED),
    this.iconColor = const Color(0xFFC2410C),
    this.icon = Icons.warning_amber_rounded,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF334155),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: borderColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      actionLabel!,
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ModuleEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ModuleEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class ModuleTag extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const ModuleTag({
    super.key,
    required this.text,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

Future<void> exportCsvData(
  BuildContext context, {
  required String fileName,
  required List<String> headers,
  required List<List<dynamic>> rows,
}) async {
  String escapeCell(dynamic v) {
    final s = (v ?? '').toString().replaceAll('"', '""');
    return '"$s"';
  }

  final csvBuffer = StringBuffer();
  csvBuffer.writeln(headers.map(escapeCell).join(','));
  for (final r in rows) {
    csvBuffer.writeln(r.map(escapeCell).join(','));
  }
  final csvText = csvBuffer.toString();

  await Clipboard.setData(ClipboardData(text: csvText));

  String? savedPath;
  try {
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsString(csvText);
    savedPath = file.path;
  } catch (_) {}

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        savedPath != null
            ? 'CSV exported ($fileName) & copied to clipboard'
            : 'CSV data copied to clipboard ($fileName)',
      ),
      backgroundColor: const Color(0xFF059669),
      duration: const Duration(seconds: 3),
    ),
  );
}

void showPrintablePreviewDialog(
  BuildContext context, {
  required String title,
  required Widget content,
  required String copyText,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.print_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: copyText));
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Document summary copied to clipboard for printing/sharing'),
                          backgroundColor: Color(0xFF059669),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 15),
                  label: const Text('Copy / Print Summary'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

InputDecoration moduleInputDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
    ),
  );
}
