import 'package:brikto_admin_panel/core/constants/colors.dart';
import 'package:brikto_admin_panel/core/constants/sizes.dart';
import 'package:brikto_admin_panel/core/widgets/loader.dart';
import 'package:brikto_admin_panel/core/widgets/navbar.dart';
import 'package:brikto_admin_panel/core/widgets/sidebar.dart';
import 'package:brikto_admin_panel/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;

  double _totalSubscriptionAmount = 0;
  List<Map<String, dynamic>> _expenses = [];

  final _typeOptions = ['PRO', 'FREE', 'TRAIL END'];
  String _selectedFilter = 'PRO';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    try {
      final expensesRes = await _supabase.from('admin_expenses').select().order('created_at', ascending: false);
      _expenses = List<Map<String, dynamic>>.from(expensesRes);

      final paymentsRes = await _supabase
          .from('subscription_payments')
          .select('amount')
          .eq('subscription_category', _selectedFilter);

      double total = 0;
      for (var row in paymentsRes) {
        total += double.tryParse(row['amount'].toString()) ?? 0;
      }
      _totalSubscriptionAmount = total;
    } catch (e) {
      debugPrint('Finance Screen Error (Tables might not exist yet): $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAddExpenseModal() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSB) => AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Expense Date: ${selectedDate.toString().split(' ')[0]}'),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) return;

                try {
                  await _supabase.from('admin_expenses').insert({
                    'amount': amount,
                    'note': noteCtrl.text.trim(),
                    'expense_date': selectedDate.toIso8601String().split('T')[0],
                  });
                  if (mounted) Navigator.pop(context);
                  _loadData();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving expense: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Navbar(title: 'Payment & Expenses', showMenu: mobile),
      drawer: mobile ? const Sidebar() : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseModal,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white)),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mobile) const Sidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Revenue Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _typeOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedFilter = filter);
                          _loadData();
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: AppColors.success.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Subscription Revenue ($_selectedFilter)', style: const TextStyle(fontSize: 16, color: AppColors.success)),
                              const SizedBox(height: 8),
                              _loading ? const SizedBox(height: 40, width: 40, child: CircularProgressIndicator()) : Text('Rs. ${_totalSubscriptionAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.success)),
                            ],
                          ),
                          const Icon(Icons.account_balance_wallet, size: 64, color: AppColors.success),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Admin Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _loading
                        ? const LoadingIndicator()
                        : _expenses.isEmpty
                            ? const Center(child: Text('No expenses recorded yet.'))
                            : ListView.builder(
                                itemCount: _expenses.length,
                                itemBuilder: (context, index) {
                                  final exp = _expenses[index];
                                  return Card(
                                    child: ListTile(
                                      leading: const CircleAvatar(backgroundColor: AppColors.danger, child: Icon(Icons.money_off, color: Colors.white)),
                                      title: Text('Rs. ${exp['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                      subtitle: Text(exp['note'] ?? 'No Note'),
                                      trailing: Text(exp['expense_date']?.toString() ?? ''),
                                    ),
                                  );
                                },
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
