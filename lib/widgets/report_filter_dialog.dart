import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report_filter.dart';
import '../utils/app_constants.dart';

class ReportFilterDialog extends StatefulWidget {
  const ReportFilterDialog({required this.initialFilter, super.key});
  final ReportFilter initialFilter;

  @override
  State<ReportFilterDialog> createState() => _ReportFilterDialogState();
}

class _ReportFilterDialogState extends State<ReportFilterDialog> {
  late ReportFilter _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Reports'),
      backgroundColor: AppConstants.colors.backgroundAlt,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(_currentFilter.startDate != null ? DateFormat('dd/MM/yyyy').format(_currentFilter.startDate!) : 'Not set'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _currentFilter.startDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _currentFilter = _currentFilter.copyWith(startDate: date));
                }
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(_currentFilter.endDate != null ? DateFormat('dd/MM/yyyy').format(_currentFilter.endDate!) : 'Not set'),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _currentFilter.endDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _currentFilter = _currentFilter.copyWith(endDate: date));
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _currentFilter),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
