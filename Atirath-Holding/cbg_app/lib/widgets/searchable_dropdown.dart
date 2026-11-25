import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchableDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final ValueChanged<T?> onChanged;
  final String label;
  final String hint;
  final bool isRequired;
  final String Function(T) itemLabel;
  final String Function(T)? itemSubtitle;
  final Widget Function(T, bool)? itemBuilder;
  final Widget Function(T?)? selectedBuilder;
  final bool enabled;

  const SearchableDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    required this.label,
    this.hint = 'Search employee...',
    this.isRequired = true,
    required this.itemLabel,
    this.itemSubtitle,
    this.itemBuilder,
    this.selectedBuilder,
    this.enabled = true,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  late TextEditingController _displayController;

  @override
  void initState() {
    super.initState();
    _displayController = TextEditingController(
      text: widget.selectedItem != null ? widget.itemLabel(widget.selectedItem as T) : '',
    );
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItem != oldWidget.selectedItem) {
      final newText = widget.selectedItem != null ? widget.itemLabel(widget.selectedItem as T) : '';
      if (_displayController.text != newText) {
        _displayController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    super.dispose();
  }

  void _clearSelection() {
    if (!widget.enabled) return;
    _displayController.clear();
    widget.onChanged(null);
    setState(() {});
  }

  Future<void> _openPickerModal() async {
    if (!widget.enabled) return;

    final T? selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SearchPickerSheet<T>(
          items: widget.items,
          selectedItem: widget.selectedItem,
          title: widget.label.isNotEmpty ? widget.label : 'Select Option',
          hint: widget.hint,
          itemLabel: widget.itemLabel,
          itemSubtitle: widget.itemSubtitle,
          itemBuilder: widget.itemBuilder,
        );
      },
    );

    // If a selection was made or cleared explicitly
    if (selected != null) {
      widget.onChanged(selected);
      _displayController.text = widget.itemLabel(selected);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                if (widget.isRequired)
                  Text(
                    ' *',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        // Selection Field Trigger
        InkWell(
          onTap: widget.enabled ? _openPickerModal : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: widget.enabled ? Colors.white : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.selectedItem != null
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFCBD5E1),
                width: widget.selectedItem != null ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.selectedItem != null ? Icons.person : Icons.search,
                  size: 20,
                  color: widget.selectedItem != null
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: widget.selectedBuilder != null
                      ? widget.selectedBuilder!(widget.selectedItem)
                      : Text(
                          widget.selectedItem != null
                              ? widget.itemLabel(widget.selectedItem as T)
                              : widget.hint,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: widget.selectedItem != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: widget.selectedItem != null
                                ? const Color(0xFF1E293B)
                                : const Color(0xFF94A3B8),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                ),
                if (widget.selectedItem != null && widget.enabled)
                  GestureDetector(
                    onTap: _clearSelection,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(Icons.close, size: 18, color: Color(0xFF94A3B8)),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchPickerSheet<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final String title;
  final String hint;
  final String Function(T) itemLabel;
  final String Function(T)? itemSubtitle;
  final Widget Function(T, bool)? itemBuilder;

  const _SearchPickerSheet({
    required this.items,
    required this.selectedItem,
    required this.title,
    required this.hint,
    required this.itemLabel,
    required this.itemSubtitle,
    required this.itemBuilder,
  });

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final sheetHeight = mediaQuery.size.height * 0.82;

    final filteredItems = _query.trim().isEmpty
        ? widget.items
        : widget.items.where((item) {
            final label = widget.itemLabel(item).toLowerCase();
            final subtitle = widget.itemSubtitle?.call(item).toLowerCase() ?? '';
            final q = _query.toLowerCase().trim();
            return label.contains(q) || subtitle.contains(q);
          }).toList();

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.people_alt_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${filteredItems.length} ${filteredItems.length == 1 ? 'employee' : 'employees'} found',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB), size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel, color: Color(0xFF94A3B8), size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() => _query = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 6),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Clear selection action (if an item is currently selected)
            if (widget.selectedItem != null && _query.isEmpty) ...[
              Material(
                color: Colors.white,
                child: InkWell(
                  onTap: () {
                    // Return null to clear selection
                    Navigator.pop(context, null);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.clear, color: Color(0xFFDC2626), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Clear Selection (None)',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],

            // Filtered Items List
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_search_outlined, size: 52, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              widget.items.isEmpty
                                  ? 'No employees available'
                                  : 'No results for "$_query"',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.items.isEmpty
                                  ? 'Please check your connection or try again later.'
                                  : 'Check the spelling or try searching with a different keyword.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: filteredItems.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF8FAFC)),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final isSelected = widget.selectedItem == item;

                          return Material(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context, item);
                              },
                              child: widget.itemBuilder != null
                                  ? widget.itemBuilder!(item, isSelected)
                                  : Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: isSelected
                                                ? const Color(0xFF2563EB)
                                                : const Color(0xFFE2E8F0),
                                            child: Text(
                                              widget.itemLabel(item).isNotEmpty
                                                  ? widget.itemLabel(item)[0].toUpperCase()
                                                  : '?',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  widget.itemLabel(item),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                                    color: isSelected
                                                        ? const Color(0xFF2563EB)
                                                        : const Color(0xFF1E293B),
                                                  ),
                                                ),
                                                if (widget.itemSubtitle != null &&
                                                    widget.itemSubtitle!(item).isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    widget.itemSubtitle!(item),
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: const Color(0xFF64748B),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20),
                                        ],
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
