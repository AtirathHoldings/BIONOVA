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

  const SearchableDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    required this.label,
    this.hint = 'Search...',
    this.isRequired = true,
    required this.itemLabel,
    this.itemSubtitle,
    this.itemBuilder,
    this.selectedBuilder,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _searchQuery = '';
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.selectedItem != null 
        ? widget.itemLabel(widget.selectedItem as T) 
        : '';
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant SearchableDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.items != oldWidget.items || widget.selectedItem != oldWidget.selectedItem) {
      final newText = widget.selectedItem != null
          ? widget.itemLabel(widget.selectedItem as T)
          : '';
      if (_controller.text != newText) {
        _controller.text = newText;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _overlayEntry?.markNeedsBuild();
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _closeDropdown();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _openDropdown();
    } else {
      _closeDropdown();
    }
  }

  void _openDropdown() {
    if (_overlayEntry != null) return;

    setState(() {
      _isOpen = true;
      _searchQuery = '';
    });

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildDropdownOverlay(),
    );

    Overlay.of(context).insert(_overlayEntry!);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayEntry?.markNeedsBuild();
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() {
        _isOpen = false;
        _searchQuery = '';
        if (widget.selectedItem != null && _controller.text != widget.itemLabel(widget.selectedItem as T)) {
          _controller.text = widget.itemLabel(widget.selectedItem as T);
        }
      });
    }
  }

  void _clearSelection() {
    _controller.clear();
    setState(() {
      _searchQuery = '';
    });
    widget.onChanged(null);
  }

  Widget _buildDropdownOverlay() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final filteredItems = _searchQuery.isEmpty
        ? widget.items
        : widget.items.where((item) {
            final label = widget.itemLabel(item).toLowerCase();
            final subtitle = widget.itemSubtitle?.call(item).toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase().trim();
            return label.contains(query) || subtitle.contains(query);
          }).toList();

    return Positioned(
      left: offset.dx,
      top: offset.dy + size.height + 2,
      width: size.width,
      child: TapRegion(
        groupId: this,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(0, size.height + 2),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 300,
                minHeight: 50,
              ),
              child: filteredItems.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: widget.items.isEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Loading employees...',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'No results found',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        color: Color(0xFFE2E8F0),
                      ),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = widget.selectedItem == item;

                        return InkWell(
                          onTap: () {
                            widget.onChanged(item);
                            _controller.text = widget.itemLabel(item);
                            _focusNode.unfocus();
                            _closeDropdown();
                          },
                          child: widget.itemBuilder != null
                              ? widget.itemBuilder!(item, isSelected)
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      // Default generic item builder if not provided
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.itemLabel(item),
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1E293B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            if (widget.itemSubtitle != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.itemSubtitle!(item),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: const Color(0xFF64748B),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF2563EB),
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
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
        // Search TextField
        TapRegion(
          groupId: this,
          onTapOutside: (event) {
            _focusNode.unfocus();
          },
          child: CompositedTransformTarget(
            link: _layerLink,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onTap: () {
                if (_isOpen) {
                  _focusNode.unfocus();
                } else {
                  if (!_focusNode.hasFocus) {
                    _focusNode.requestFocus();
                  } else {
                    _openDropdown();
                  }
                }
              },
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: _controller.text.isEmpty
                    ? const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 20,
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: _clearSelection,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  if (!_isOpen) {
                    _openDropdown();
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
