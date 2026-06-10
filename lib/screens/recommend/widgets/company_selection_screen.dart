import 'package:flutter/material.dart';

class CompanySelectionScreen extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final String? selectedCompany;

  const CompanySelectionScreen({
    super.key,
    required this.onSelect,
    this.selectedCompany,
  });

  @override
  Widget build(BuildContext context) {
    final companies = ['친구', '연인', '가족', '혼자'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        spacing: 14,
        children: companies
            .map((company) {
              final isSelected = company == selectedCompany;
              return GestureDetector(
                onTap: () => onSelect(company),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6B9358) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6B9358) : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
}
