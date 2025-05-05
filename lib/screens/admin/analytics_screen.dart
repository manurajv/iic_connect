import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:iic_connect/utils/theme.dart';
import 'package:iic_connect/widgets/glass_card.dart';

class AnalyticsScreen extends StatelessWidget {
  static const routeName = '/analytics';

  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserStatsCard(context),
            const SizedBox(height: 20),
            _buildUserRoleChart(context),
            const SizedBox(height: 20),
            _buildActivityChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatsCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'User Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, 'Total Users', '1,245', Icons.people),
              _buildStatItem(context, 'Active Today', '324', Icons.today),
              _buildStatItem(context, 'New This Week', '56', Icons.new_releases),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildUserRoleChart(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'User Distribution by Role',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            height: 300,
            child: SfCircularChart(
              palette: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.tertiary,
                Colors.amber,
              ],
              series: <CircularSeries>[
                PieSeries<ChartData, String>(
                  dataSource: [
                    ChartData('Students', 65),
                    ChartData('Faculty', 20),
                    ChartData('Staff', 10),
                    ChartData('Admin', 5),
                  ],
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.value,
                  dataLabelSettings: const DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                  ),
                  explode: true,
                  explodeIndex: 0,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Monthly Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              primaryYAxis: NumericAxis(
                minimum: 0,
                maximum: 60,
                interval: 10,
              ),
              series: <CartesianSeries<ChartData, String>>[
                ColumnSeries<ChartData, String>(
                  dataSource: [
                    ChartData('Jan', 35),
                    ChartData('Feb', 28),
                    ChartData('Mar', 45),
                    ChartData('Apr', 32),
                    ChartData('May', 40),
                    ChartData('Jun', 50),
                  ],
                  xValueMapper: (ChartData data, _) => data.category,
                  yValueMapper: (ChartData data, _) => data.value,
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String category;
  final int value;

  ChartData(this.category, this.value);
}