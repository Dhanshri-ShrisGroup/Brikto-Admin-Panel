import 'package:brikto_admin_panel/core/constants/api.dart';
import 'package:brikto_admin_panel/core/constants/colors.dart';
import 'package:brikto_admin_panel/core/constants/sizes.dart';
import 'package:brikto_admin_panel/core/widgets/loader.dart';
import 'package:brikto_admin_panel/core/widgets/navbar.dart';
import 'package:brikto_admin_panel/core/widgets/sidebar.dart';
import 'package:brikto_admin_panel/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionManagementPage extends StatefulWidget {
  const SubscriptionManagementPage({super.key});

  @override
  State<SubscriptionManagementPage> createState() =>
      _SubscriptionManagementPageState();
}

class _SubscriptionManagementPageState
    extends State<SubscriptionManagementPage> {
  static const List<String> _typeOptions = ['FREE', 'PRO', 'TRIAL'];

  final SupabaseClient _supabase = Supabase.instance.client;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  bool _loading = true;
  Set<String> _selectedFilters = {'All'};
  String? _selectedProPlanId;
  List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _plans = [];
  int _trialDays = 14;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _supabase
            .from(ApiConstants.sites)
            .select(
              'id, owner_id, name, location, subscription_type, '
              'trial_start_date, trial_end_date, '
              'subscription_start_date, subscription_end_date, '
              'owner:owner_id(full_name, email)',
            )
            .order('created_at', ascending: false),
        _supabase
            .from(ApiConstants.subscriptionPlans)
            .select()
            .eq('is_active', true)
            .order('duration_days', ascending: true),
        _supabase
            .from('trail_days')
            .select('days')
            .limit(1)
            .maybeSingle(),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _sites = List<Map<String, dynamic>>.from(results[0] as List);
        _plans = List<Map<String, dynamic>>.from(results[1] as List);
        if (results.length > 2 && results[2] != null) {
          final trialData = results[2] as Map<String, dynamic>;
          _trialDays = int.tryParse(trialData['days']?.toString() ?? '14') ?? 14;
        }
      });
    } catch (error) {
      _showMessage('Failed to load subscription data: $error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<String> get _filterOptions => const ['All', ..._typeOptions];

  List<Map<String, dynamic>> get _filteredSites {
    if (_selectedFilters.contains('All')) {
      return _sites;
    }

    return _sites.where((site) {
      final type = _normalizedType(site['subscription_type']);
      if (!_selectedFilters.contains(type)) return false;
      
      if (type == 'PRO' && _selectedProPlanId != null) {
        final plan = _matchingPlan(site);
        if (_selectedProPlanId == 'custom') {
           if (plan != null) return false;
        } else {
           if (plan == null || plan['id'].toString() != _selectedProPlanId) return false;
        }
      }
      return true;
    }).toList();
  }

  void _toggleFilter(String filter) {
    setState(() {
      if (filter == 'All') {
        _selectedFilters = {'All'};
        _selectedProPlanId = null;
      } else {
        _selectedFilters.remove('All');
        if (_selectedFilters.contains(filter)) {
          _selectedFilters.remove(filter);
          if (filter == 'PRO') _selectedProPlanId = null;
        } else {
          _selectedFilters.add(filter);
        }
        if (_selectedFilters.isEmpty) {
          _selectedFilters.add('All');
        }
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedFilters = {'All'};
      _selectedProPlanId = null;
    });
  }

  Future<void> _openSubscriptionDialog(Map<String, dynamic> site) async {
    final currentType = _normalizedType(site['subscription_type']);
    String selectedType =
        _typeOptions.contains(currentType) ? currentType : 'FREE';
    String? selectedPlanId = _matchingPlan(site)?['id']?.toString();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Manage ${_readString(site['name'], fallback: 'Site')}',
          ),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _ownerLabel(site),
                  readOnly: true,
                  decoration: const InputDecoration(labelText: 'Owner'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Subscription type',
                  ),
                  items: _typeOptions
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setDialogState(() {
                      selectedType = value;
                      if (selectedType != 'PRO') {
                        selectedPlanId = null;
                      } else if (selectedPlanId == null && _plans.isNotEmpty) {
                        selectedPlanId = _plans.first['id'].toString();
                      }
                    });
                  },
                ),
                if (selectedType == 'PRO') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedPlanId ??
                        (_plans.isNotEmpty ? _plans.first['id'].toString() : null),
                    decoration: const InputDecoration(labelText: 'Plan name'),
                    items: _plans
                        .map(
                          (plan) => DropdownMenuItem<String>(
                            value: plan['id'].toString(),
                            child: Text(
                              '${plan['plan_name']} (${_formatDurationInMonths(plan['duration_days'])})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedPlanId = value);
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _previewText(type: selectedType, planId: selectedPlanId),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final updatePayload = _buildSubscriptionPayload(
                    type: selectedType,
                    planId: selectedPlanId,
                  );

                  await _supabase
                      .from(ApiConstants.sites)
                      .update(updatePayload)
                      .eq('id', site['id']);

                  if (!context.mounted) {
                    return;
                  }

                  Navigator.pop(context, true);
                } catch (error) {
                  _showMessage('Failed to update subscription: $error');
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      _showMessage('Subscription updated');
      await _loadData();
    }
  }

  Future<void> _showManualSubscriptionForm() async {
    bool loadingDevs = true;
    List<Map<String, dynamic>> developers = [];
    int? selectedDevId;

    bool loadingSites = false;
    List<Map<String, dynamic>> devSites = [];
    int? selectedSiteId;

    String? selectedPlanId;
    final durationCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    try {
      final res = await _supabase.from('owner').select('id, full_name, phone').order('full_name', ascending: true);
      developers = List<Map<String, dynamic>>.from(res);
    } catch (_) {}
    loadingDevs = false;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSB) {
          return AlertDialog(
            title: const Text('Manual Subscription Activation'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loadingDevs) const LinearProgressIndicator(),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Select Developer'),
                      value: selectedDevId,
                      items: developers.map((d) => DropdownMenuItem(
                        value: d['id'] as int,
                        child: Text('${d['full_name']} (${d['phone'] ?? '-'})'),
                      )).toList(),
                      onChanged: (val) async {
                        if (val == null) return;
                        setSB(() {
                          selectedDevId = val;
                          selectedSiteId = null;
                          loadingSites = true;
                        });
                        try {
                          final sitesRes = await _supabase.from('sites').select('id, name, location').eq('owner_id', val);
                          setSB(() {
                            devSites = List<Map<String, dynamic>>.from(sitesRes);
                          });
                        } catch (_) {}
                        setSB(() => loadingSites = false);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (loadingSites) const LinearProgressIndicator(),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Select Site'),
                      value: selectedSiteId,
                      items: devSites.map((s) => DropdownMenuItem(
                        value: s['id'] as int,
                        child: Text('${s['name']} (${s['location'] ?? ''})'),
                      )).toList(),
                      onChanged: (val) => setSB(() => selectedSiteId = val),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Select Plan'),
                      value: selectedPlanId,
                      items: [
                        const DropdownMenuItem(value: 'custom', child: Text('Custom Plan')),
                        ..._plans.map((p) => DropdownMenuItem(
                          value: p['id'].toString(),
                          child: Text('${p['plan_name']} (${p['duration_days']} Days) - Rs. ${p['discounted_price'] ?? p['original_price']}'),
                        ))
                      ],
                      onChanged: (val) {
                        setSB(() {
                          selectedPlanId = val;
                          if (val != 'custom' && val != null) {
                            final plan = _plans.firstWhere((p) => p['id'].toString() == val);
                            durationCtrl.text = plan['duration_days'].toString();
                            amountCtrl.text = (plan['discounted_price'] ?? plan['original_price']).toString();
                          } else {
                            durationCtrl.clear();
                            amountCtrl.clear();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Duration (Days)'))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Actual Amount Paid (Rs)'))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Note (Optional)')),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Transaction Date: ${selectedDate.toString().split(' ')[0]}'),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setSB(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (selectedDevId == null || selectedSiteId == null) {
                    _showMessage('Please select Developer and Site.');
                    return;
                  }
                  final dur = int.tryParse(durationCtrl.text);
                  final amt = double.tryParse(amountCtrl.text);
                  if (dur == null || dur <= 0) {
                    _showMessage('Invalid duration.');
                    return;
                  }
                  if (amt == null || amt < 0) {
                    _showMessage('Invalid amount.');
                    return;
                  }

                  try {
                    final startDate = selectedDate;
                    final endDate = startDate.add(Duration(days: dur));
                    final planName = selectedPlanId == 'custom' 
                        ? 'Custom ($dur Days)' 
                        : _plans.firstWhere((p) => p['id'].toString() == selectedPlanId)['plan_name'];

                    // Update Sites
                    await _supabase.from('sites').update({
                      'subscription_type': 'PRO',
                      'subscription_start_date': startDate.toIso8601String(),
                      'subscription_end_date': endDate.toIso8601String(),
                    }).eq('id', selectedSiteId as int);

                    // Update Owner
                    await _supabase.from('owner').update({
                      'subscription_plan': planName,
                      'subscription_start_date': startDate.toIso8601String().split('T')[0],
                      'subscription_expiry_date': endDate.toIso8601String().split('T')[0],
                    }).eq('id', selectedDevId as int);

                    // Insert Payment History
                    String noteText = 'Manual Admin Sub: $planName.';
                    if (noteCtrl.text.trim().isNotEmpty) noteText += ' Note: ${noteCtrl.text.trim()}';

                    final paymentPayload = {
                      'developer_id': selectedDevId,
                      'amount': amt,
                      'subscription_category': 'PRO',
                      'note': noteText,
                      'payment_date': startDate.toIso8601String().split('T')[0]
                    };
                    
                    try {
                      await _supabase.from('subscription_payments').insert(paymentPayload);
                    } catch (paymentErr) {
                      debugPrint('Could not insert payment record (table might not exist): $paymentErr');
                    }

                    if (mounted) Navigator.pop(context, true);
                  } catch (e) {
                    _showMessage('Error activating subscription: $e');
                  }
                },
                child: const Text('Activate Subscription'),
              )
            ]
          );
        }
      )
    );

    _loadData();
  }

  Map<String, dynamic> _buildSubscriptionPayload({
    required String type,
    required String? planId,
  }) {
    final now = DateTime.now();
    final payload = <String, dynamic>{
      'subscription_type': type,
      'trial_start_date': null,
      'trial_end_date': null,
      'subscription_start_date': null,
      'subscription_end_date': null,
      'updated_at': now.toIso8601String(),
    };

    if (type == 'TRIAL') {
      payload['trial_start_date'] = now.toIso8601String();
      payload['trial_end_date'] =
          now.add(Duration(days: _trialDays)).toIso8601String();
      return payload;
    }

    if (type == 'PRO') {
      final plan = _plans.firstWhere(
        (item) => item['id'].toString() == planId,
        orElse: () => <String, dynamic>{},
      );

      if (plan.isEmpty) {
        throw Exception('Select a valid plan');
      }

      final durationDays = int.tryParse(plan['duration_days'].toString());
      if (durationDays == null || durationDays <= 0) {
        throw Exception('Selected plan has an invalid duration');
      }

      payload['subscription_start_date'] = now.toIso8601String();
      payload['subscription_end_date'] =
          now.add(Duration(days: durationDays)).toIso8601String();
      return payload;
    }

    return payload;
  }

  Map<String, dynamic>? _matchingPlan(Map<String, dynamic> site) {
    final start = _parseDate(site['subscription_start_date']);
    final end = _parseDate(site['subscription_end_date']);
    if (start == null || end == null) {
      return null;
    }

    final diffDays = end.difference(start).inDays;
    for (final plan in _plans) {
      final planDays = int.tryParse(plan['duration_days'].toString()) ?? 0;
      if ((planDays - diffDays).abs() <= 5) {
        return plan;
      }
    }
    return null;
  }

  String _previewText({
    required String type,
    required String? planId,
  }) {
    if (type == 'FREE') {
      return 'FREE will clear trial and subscription dates.';
    }

    if (type == 'TRIAL') {
      return 'TRIAL will automatically apply $_trialDays days from today.';
    }

    final plan = _plans.cast<Map<String, dynamic>?>().firstWhere(
          (item) => item?['id'].toString() == planId,
          orElse: () => null,
        );

    if (plan == null) {
      return 'Select a plan to apply PRO dates.';
    }

    return 'PRO will apply ${plan['plan_name']} for ${_formatDurationInMonths(plan['duration_days'])} from today.';
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

  String _normalizedType(dynamic value) {
    final type = _readString(value, fallback: 'FREE').toUpperCase();
    return _typeOptions.contains(type) ? type : 'FREE';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  DateTime _addMonths(DateTime source, int months) {
    final totalMonths = source.month + months;
    final targetYear = source.year + ((totalMonths - 1) ~/ 12);
    final targetMonth = ((totalMonths - 1) % 12) + 1;
    final maxDay = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = source.day > maxDay ? maxDay : source.day;

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }

  // Removed _monthDifference

  String _formatDate(dynamic value) {
    final parsed = _parseDate(value);
    if (parsed == null) {
      return '-';
    }
    return _dateFormat.format(parsed.toLocal());
  }

  String _formatDateRange(dynamic start, dynamic end) {
    final startText = _formatDate(start);
    final endText = _formatDate(end);

    if (startText == '-' && endText == '-') {
      return '-';
    }
    return '$startText to $endText';
  }

  String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }

    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String _ownerLabel(Map<String, dynamic> site) {
    final owner = site['owner'];
    if (owner is Map<String, dynamic>) {
      final name = _readString(owner['full_name']);
      final email = _readString(owner['email']);
      if (name.isNotEmpty && email.isNotEmpty) {
        return '$name \n$email';
      }
      if (name.isNotEmpty) {
        return name;
      }
      if (email.isNotEmpty) {
        return email;
      }
    }

    return 'Owner ID: ${site['owner_id']}';
  }

  String _planLabel(Map<String, dynamic> site) {
    final type = _normalizedType(site['subscription_type']);
    if (type != 'PRO') return '';

    final plan = _matchingPlan(site);
    return plan == null
        ? 'Custom PRO'
        : _readString(plan['plan_name'], fallback: 'Unknown PRO Plan');
  }

  String _durationLabel(Map<String, dynamic> site) {
    final type = _normalizedType(site['subscription_type']);
    if (type == 'FREE') {
      return 'Free';
    }
    if (type == 'TRIAL') {
      return '$_trialDays days trial';
    }

    final plan = _matchingPlan(site);
    if (plan == null) {
      return 'Subscription';
    }

    return '${_formatDurationInMonths(plan['duration_days'])} subscription';
  }

  String _activeRangeLabel(Map<String, dynamic> site) {
    final type = _normalizedType(site['subscription_type']);
    if (type == 'TRIAL') {
      return _formatDateRange(site['trial_start_date'], site['trial_end_date']);
    }
    if (type == 'PRO') {
      return _formatDateRange(
        site['subscription_start_date'],
        site['subscription_end_date'],
      );
    }
    return '-';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'FREE':
        return AppColors.warning;
      case 'TRIAL':
        return Colors.blue;
      default:
        return AppColors.success;
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

  Widget _buildSiteCard(Map<String, dynamic> site, bool mobile) {
    final type = _normalizedType(site['subscription_type']);
    final typeColor = _typeColor(type);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(mobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: typeColor.withValues(alpha: 0.14),
                  child: Icon(
                    Icons.apartment,
                    color: typeColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _readString(site['name'], fallback: 'Unnamed Site'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   _ownerLabel(site),
                      //   style: const TextStyle(
                      //     color: AppColors.textSecondary,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _openSubscriptionDialog(site),
                ),
              ],
            ),
            const SizedBox(height: 14),
                      Text(
                        _ownerLabel(site),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'Type', value: type, color: typeColor),
                // if (type == 'PRO')
                //   _InfoChip(
                //     label: 'Pro Plan',
                //     value: _planLabel(site),
                //     color: AppColors.primary,
                //   ),
                _InfoChip(
                  label: 'Duration',
                  value: _durationLabel(site),
                  color: AppColors.secondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Location: ${_readString(site['location'], fallback: '-')}',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Active range: ${_activeRangeLabel(site)}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 3;
    if (width >= 900) return 2;
    if (width >= 600) return 1;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final filteredSites = _filteredSites;

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: mobile ? const Sidebar() : null,
      appBar: Navbar(title: 'Subscription Management', showMenu: mobile),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showManualSubscriptionForm,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_card, color: Colors.white),
        label: const Text('Manual Subscription', style: TextStyle(color: Colors.white)),
      ),
      body: Row(
        children: [
          if (!mobile) const Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              child: Column(
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._filterOptions.map((filter) {
                        final isSelected = _selectedFilters.contains(filter);
                        return FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (_) => _toggleFilter(filter),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          checkmarkColor: AppColors.primary,
                        );
                      }),
                      if (_selectedFilters.contains('PRO') && _plans.isNotEmpty)
                        DropdownButton<String?>(
                          value: _selectedProPlanId,
                          hint: const Text('All PRO Plans'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All PRO Plans')),
                            const DropdownMenuItem(value: 'custom', child: Text('Custom PRO')),
                            ..._plans.map((p) => DropdownMenuItem(
                              value: p['id'].toString(), 
                              child: Text('${p['plan_name']} (${_formatDurationInMonths(p['duration_days'])})')
                            ))
                          ],
                          onChanged: (val) => setState(() => _selectedProPlanId = val),
                        ),
                      TextButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        onPressed: _clearFilters,
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _loading
                        ? const LoadingIndicator()
                        : filteredSites.isEmpty
                            ? const Center(child: Text('No sites found'))
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                child: GridView.builder(
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: _getCrossAxisCount(context),
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    mainAxisExtent: 260,
                                  ),
                                  itemCount: filteredSites.length,
                                  itemBuilder: (_, index) {
                                    return _buildSiteCard(
                                      filteredSites[index],
                                      mobile,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
