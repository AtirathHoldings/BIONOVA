import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/employee_option.dart';
import 'searchable_dropdown.dart';

class EmployeeDropdown extends StatelessWidget {
  final String label;
  final EmployeeOption? selectedItem;
  final ValueChanged<EmployeeOption?> onChanged;
  final List<EmployeeOption> items;
  final List<EmployeeOption> excluded;
  final bool isRequired;

  const EmployeeDropdown({
    super.key,
    required this.label,
    required this.selectedItem,
    required this.onChanged,
    required this.items,
    this.excluded = const [],
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) {
    // Filter out excluded employees
    final filteredItems = items.where((emp) {
      if (excluded.isEmpty) return true;
      return !excluded.any((ex) => ex.id == emp.id);
    }).toList();

    return SearchableDropdown<EmployeeOption>(
      label: label,
      items: filteredItems,
      selectedItem: selectedItem,
      onChanged: onChanged,
      isRequired: isRequired,
      hint: 'Search employee...',
      itemLabel: (item) => item.name,
      itemSubtitle: (item) => _getSubtitle(item),
      selectedBuilder: (item) {
        if (item == null) return const SizedBox.shrink();
        return Row(
          children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: const Color(0xFFEFF6FF),
              backgroundImage: (item.profileImageUrl != null && item.profileImageUrl!.isNotEmpty)
                  ? NetworkImage(item.profileImageUrl!)
                  : null,
              child: (item.profileImageUrl == null || item.profileImageUrl!.isEmpty)
                  ? Text(
                      item.initials,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
      itemBuilder: (item, isSelected) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image or Initials
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFEFF6FF),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
                    width: isSelected ? 2 : 1,
                  ),
                  image: (item.profileImageUrl != null && item.profileImageUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(item.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (item.profileImageUrl == null || item.profileImageUrl!.isEmpty)
                    ? Center(
                        child: Text(
                          item.initials,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Employee Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.designation,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (_getCompanyPlantText(item).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _getCompanyPlantText(item),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),

              // Checkmark for selection
              if (isSelected)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getSubtitle(EmployeeOption item) {
    String sub = item.designation;
    final companyPlant = _getCompanyPlantText(item);
    if (companyPlant.isNotEmpty) {
      sub += ' • $companyPlant';
    }
    return sub;
  }

  String _getCompanyPlantText(EmployeeOption item) {
    if (item.plantName != null &&
        item.plantName!.isNotEmpty &&
        item.companyName != null &&
        item.companyName!.isNotEmpty) {
      return '${item.plantName} (${item.companyName})';
    } else if (item.companyName != null && item.companyName!.isNotEmpty) {
      return item.companyName!;
    }
    return '';
  }
}
