import 'package:brikto_admin_panel/core/constants/colors.dart';
import 'package:brikto_admin_panel/core/constants/sizes.dart';
import 'package:brikto_admin_panel/core/widgets/loader.dart';
import 'package:brikto_admin_panel/core/widgets/navbar.dart';
import 'package:brikto_admin_panel/core/widgets/sidebar.dart';
import 'package:brikto_admin_panel/core/utils/responsive.dart';
import 'package:brikto_admin_panel/services/pro_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProManagementScreen extends StatefulWidget {
  const ProManagementScreen({super.key});

  @override
  State<ProManagementScreen> createState() => _ProManagementScreenState();
}

class _ProManagementScreenState extends State<ProManagementScreen> {
  final ProService _service = ProService();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  bool _loading = true;
  List<Map<String, dynamic>> _records = [];
  int? _trialDays = 14;
  int? _trialDaysId;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);

    try {
      final records = await _service.fetchRecords();
      final trialData = await Supabase.instance.client.from('trail_days').select('days, id').limit(1).maybeSingle();
      
      if (!mounted) {
        return;
      }

      setState(() {
        _records = records;
        if (trialData != null) {
          _trialDays = int.tryParse(trialData['days'].toString());
          _trialDaysId = int.tryParse(trialData['id'].toString());
        }
      });
    } catch (error) {
      _showMessage('Failed to load PRO records: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _editTrialDays() async {
    final ctrl = TextEditingController(text: _trialDays?.toString() ?? '14');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Global Trial Period'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Trial days', helperText: 'Applied to all new trial subscriptions.'),
        ),
        actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                 final val = int.tryParse(ctrl.text);
                 if (val == null || val <= 0) return;
                 try {
                   if (_trialDaysId == null) {
                      await Supabase.instance.client.from('trail_days').insert({'days': val});
                   } else {
                      await Supabase.instance.client.from('trail_days').update({'days': val}).eq('id', _trialDaysId!);
                   }
                   Navigator.pop(context, true);
                 } catch (e) {
                   _showMessage('Failed to save trial days: $e');
                 }
              },
              child: const Text('Save'),
            )
        ]
      )
    );

    if (saved == true) {
      _showMessage('Trial period updated');
      _loadRecords();
    }
  }

  Future<void> _saveRecord({
    required String planName,
    required double originalPrice,
    double? discountedPrice,
    DateTime? discountExpiry,
    required int durationDays,
    required bool isActive,
    Map<String, dynamic>? existing,
  }) async {
    final payload = <String, dynamic>{
      'plan_name': planName,
      'original_price': originalPrice,
      'discounted_price': discountedPrice,
      'discount_expiry': discountExpiry?.toIso8601String(),
      'duration_days': durationDays,
      'is_active': isActive,
    };

    if (existing == null) {
      await _service.createRecord(payload);
      _showMessage('Plan created');
      return;
    }

    await _service.updateRecord(existing['id'], payload);
    _showMessage('Plan updated');
  }

  Future<void> _toggleActive(Map<String, dynamic> record) async {
    final isActive = record['is_active'] == true;

    try {
      await _service.setActive(record['id'], !isActive);
      _showMessage(isActive ? 'Plan deactivated' : 'Plan activated');
      await _loadRecords();
    } catch (error) {
      _showMessage('Failed to update plan status: $error');
    }
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete subscription plan'),
            content: Text(
              'Delete "${_displayName(record)}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    try {
      await _service.deleteRecord(record['id']);
      _showMessage('Plan deleted');
      await _loadRecords();
    } catch (error) {
      _showMessage('Failed to delete plan: $error');
    }
  }

  Future<void> _openForm({Map<String, dynamic>? record}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: _readString(record, ['plan_name']),
    );
    final originalPriceController = TextEditingController(
      text: _readNumber(record?['original_price']),
    );
    final discountedPriceController = TextEditingController(
      text: _readNullableNumber(record?['discounted_price']),
    );
    final durationController = TextEditingController(
      text: _readInt(record?['duration_days']),
    );
    final expiryController = TextEditingController(
      text: _readDate(record?['discount_expiry']),
    );
    var isActive = record?['is_active'] != false;
    DateTime? selectedExpiry = _parseDate(record?['discount_expiry']);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            record == null ? 'Add subscription plan' : 'Edit subscription plan',
          ),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Plan name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Plan name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: originalPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Original price'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Original price is required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: discountedPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Discounted price',
                        hintText: 'Optional',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Enter a valid discounted price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration in months',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Duration is required';
                        }
                        final days = int.tryParse(value.trim());
                        if (days == null || days <= 0) {
                          return 'Enter a valid number of months';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: expiryController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Discount expiry',
                        hintText: 'Optional',
                        suffixIcon: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Pick date',
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate:
                                      selectedExpiry ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked == null) {
                                  return;
                                }

                                setDialogState(() {
                                  selectedExpiry = picked;
                                  expiryController.text = _dateFormat.format(picked);
                                });
                              },
                            ),
                            IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setDialogState(() {
                                  selectedExpiry = null;
                                  expiryController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Plan is active'),
                      value: isActive,
                      onChanged: (value) {
                        setDialogState(() => isActive = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                try {
                  await _saveRecord(
                    planName: nameController.text.trim(),
                    originalPrice: double.parse(
                      originalPriceController.text.trim(),
                    ),
                    discountedPrice:
                        discountedPriceController.text.trim().isEmpty
                            ? null
                            : double.parse(
                                discountedPriceController.text.trim(),
                              ),
                    discountExpiry: selectedExpiry,
                    durationDays: int.parse(durationController.text.trim()),
                    isActive: isActive,
                    existing: record,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pop(context, true);
                } catch (error) {
                  _showMessage('Failed to save PRO record: $error');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await _loadRecords();
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _displayName(Map<String, dynamic> record) {
    return _readString(record, ['plan_name'], fallback: 'Unnamed plan');
  }

  String _displayOriginalPrice(Map<String, dynamic> record) {
    return _currency(record['original_price']);
  }

  String _displayDiscountedPrice(Map<String, dynamic> record) {
    if (record['discounted_price'] == null) {
      return 'No discount';
    }
    return _currency(record['discounted_price']);
  }

  String _displayStatus(Map<String, dynamic> record) {
    return record['is_active'] == true ? 'Active' : 'Inactive';
  }

  String _formatDurationInMonths(dynamic daysValue) {
    final days = int.tryParse(daysValue.toString()) ?? 0;
    if (days >= 360) {
      final years = (days / 365).floor();
      final remainingMonths = ((days % 365) / 30).round();
      if (remainingMonths > 0) {
        return '$years Year${years > 1 ? 's' : ''} $remainingMonths Month${remainingMonths > 1 ? 's' : ''}';
      }
      return '$years Year${years > 1 ? 's' : ''}';
    }
    if (days >= 28) {
      final months = (days / 30).round();
      return '$months Month${months > 1 ? 's' : ''}';
    }
    return '$days Day${days > 1 ? 's' : ''}';
  }

  String _displayDuration(Map<String, dynamic> record) {
    if (record['duration_days'] == null) return '-';
    return _formatDurationInMonths(record['duration_days']);
  }

  String _displayDiscountExpiry(Map<String, dynamic> record) {
    final parsed = _parseDate(record['discount_expiry']);
    return parsed == null ? 'No expiry' : _dateFormat.format(parsed);
  }

  String _readString(
    Map<String, dynamic>? record,
    List<String> keys, {
    String fallback = '',
  }) {
    if (record == null) {
      return fallback;
    }

    for (final key in keys) {
      final value = record[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return fallback;
  }

  String _readNumber(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  String _readNullableNumber(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  String _readInt(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  String _readDate(dynamic value) {
    final parsed = _parseDate(value);
    if (parsed == null) {
      return '';
    }
    return _dateFormat.format(parsed);
  }

  String _currency(dynamic value) {
    if (value == null) {
      return '-';
    }

    return 'Rs. ${value.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: mobile ? const Sidebar() : null,
      appBar: Navbar(title: 'PRO Module', showMenu: mobile),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Plan',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Row(
        children: [
          if (!mobile) const Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              child: Column(
                children: [
                  Card(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Icon(Icons.timer, color: Colors.white),
                      ),
                      title: const Text('Global Trial Period', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('$_trialDays days'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: _editTrialDays,
                      )
                    )
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _loading
                        ? const LoadingIndicator()
                        : _records.isEmpty
                            ? _EmptyState(onPressed: _openForm)
                            : RefreshIndicator(
                                onRefresh: _loadRecords,
                                child: ListView.separated(
                            itemCount: _records.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final record = _records[index];
                              final status = _displayStatus(record);

                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: status == 'Active'
                                        ? AppColors.success.withValues(alpha: 0.14)
                                        : AppColors.warning.withValues(alpha: 0.14),
                                    child: Icon(
                                      Icons.workspace_premium,
                                      color: status == 'Active'
                                          ? AppColors.success
                                          : AppColors.warning,
                                    ),
                                  ),
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _displayName(record),
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Wrap(
                                        spacing: 2,
                                        children: [
                                          IconButton(
                                            tooltip: status == 'Active' ? 'Deactivate' : 'Activate',
                                            icon: Icon(
                                              status == 'Active' ? Icons.toggle_on : Icons.toggle_off,
                                              color: status == 'Active' ? AppColors.success : AppColors.textSecondary,
                                            ),
                                            onPressed: () => _toggleActive(record),
                                          ),
                                          IconButton(
                                            tooltip: 'Edit',
                                            icon: const Icon(Icons.edit, color: Colors.orange),
                                            onPressed: () => _openForm(record: record),
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                            onPressed: () => _deleteRecord(record),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Original: ${_displayOriginalPrice(record)}\n'
                                      'Discount: ${_displayDiscountedPrice(record)}\n'
                                      'Duration: ${_displayDuration(record)} | Expiry: ${_displayDiscountExpiry(record)}\n'
                                      'Status: $status',
                                    ),
                                  ),
                                  isThreeLine: false,
                                ),
                              );
                            },
                          ),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPressed});

  final Future<void> Function({Map<String, dynamic>? record}) onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            size: 72,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No subscription plans found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create the first plan to start managing the PRO module.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => onPressed(),
            icon: const Icon(Icons.add),
            label: const Text('Add Plan'),
          ),
        ],
      ),
    );
  }
}
