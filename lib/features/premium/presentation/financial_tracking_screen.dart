import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../data/models/financial_goal.dart';
import '../../../data/models/spending_log.dart';
import '../../../providers/focus_financial_providers.dart';
import '../../../providers/app_providers.dart';

class FinancialTrackingScreen extends ConsumerStatefulWidget {
  const FinancialTrackingScreen({super.key});

  @override
  ConsumerState<FinancialTrackingScreen> createState() =>
      _FinancialTrackingScreenState();
}

class _FinancialTrackingScreenState
    extends ConsumerState<FinancialTrackingScreen> {
  final _goalNameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _spendingAmountController = TextEditingController();

  @override
  void dispose() {
    _goalNameController.dispose();
    _targetAmountController.dispose();
    _spendingAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(userIdProvider);
    final goals = ref.watch(financialGoalsProvider(userId ?? ''));
    final insights = ref.watch(financialInsightsProvider(userId ?? ''));

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Tracking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          insights.when(
            data: (data) => SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Financial Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Saved'),
                          Text(
                            '\$${data.totalSaved.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Spent'),
                          Text(
                            '\$${data.totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Goals'),
                          Text(
                            '${data.completedGoals}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Financial Goal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _goalNameController,
                  decoration: InputDecoration(
                    labelText: 'Goal Name (e.g., Vacation)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetAmountController,
                  decoration: InputDecoration(
                    labelText: 'Target Amount (\$)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Add Goal',
                  onPressed: () => _createGoal(userId!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log Spending',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _spendingAmountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (\$)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Log Spending',
                  onPressed: () => _logSpending(userId!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Active Goals',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          goals.when(
            data: (list) {
              final active = list.where((g) => !g.isCompleted);
              return Column(
                children: active.map((goal) {
                  final progress = goal.progress;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  goal.goalName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${progress.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${goal.currentAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('Error: $error'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGoal(String userId) async {
    if (_goalNameController.text.isEmpty ||
        _targetAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final goal = FinancialGoal(
      id: '',
      userId: userId,
      goalName: _goalNameController.text,
      targetAmount: double.parse(_targetAmountController.text),
      currentAmount: 0,
      reason: null,
      targetDate: null,
      isCompleted: false,
      completedAt: null,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(createFinancialGoalProvider(goal).future);
      _goalNameController.clear();
      _targetAmountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goal added!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding goal: $e')),
      );
    }
  }

  Future<void> _logSpending(String userId) async {
    if (_spendingAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount')),
      );
      return;
    }

    final log = SpendingLog(
      id: '',
      userId: userId,
      categoryId: null,
      amount: double.parse(_spendingAmountController.text),
      description: null,
      loggedDate: DateTime.now(),
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(logSpendingProvider(log).future);
      _spendingAmountController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spending logged!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging spending: $e')),
      );
    }
  }
}
