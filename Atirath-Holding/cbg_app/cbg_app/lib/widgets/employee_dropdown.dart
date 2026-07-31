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
      itemBuilder: (item, isSelected) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2E8F0),
                  border: isSelected ? Border.all(color: const Color(0xFF2563EB), width: 2) : null,
                  image: (item.profileImageUrl != null && item.profileImageUrl!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(item.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (item.profileImageUrl == null || item.profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Color(0xFF94A3B8), size: 20)
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
                        color: const Color(0xFF1E293B),
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
                  padding: EdgeInsets.only(top: 8.0, left: 8.0),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF2563EB),
                    size: 20,
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
    if (item.plantName != null && item.plantName!.isNotEmpty && 
        item.companyName != null && item.companyName!.isNotEmpty) {
      return '${item.plantName} (${item.companyName})';
    } else if (item.companyName != null && item.companyName!.isNotEmpty) {
      return item.companyName!;
    }
    return '';
  }
}
