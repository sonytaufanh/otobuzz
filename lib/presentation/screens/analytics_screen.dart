import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/analytics/analytics_bloc.dart';
import '../blocs/analytics/analytics_event.dart';
import '../blocs/analytics/analytics_state.dart';
import '../blocs/vehicle/vehicle_bloc.dart';
import '../blocs/vehicle/vehicle_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
        builder: (context, state) {
          if (state is AnalyticsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AnalyticsError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          if (state is AnalyticsLoaded) {
            return _AnalyticsContent(state: state);
          }
          // Initial - trigger load
          context.read<AnalyticsBloc>().add(const LoadAnalytics());
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final AnalyticsLoaded state;
  const _AnalyticsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final theme = Theme.of(context);

    // KM change percentage
    String kmChangeText = '';
    Color kmChangeColor = Colors.grey;
    if (state.totalKmLastMonth > 0) {
      final pct = ((state.totalKmThisMonth - state.totalKmLastMonth) /
              state.totalKmLastMonth *
              100)
          .toStringAsFixed(0);
      kmChangeText = '${int.parse(pct) >= 0 ? '+' : ''}$pct% vs bulan lalu';
      kmChangeColor = int.parse(pct) >= 0 ? Colors.green : Colors.red;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filter row
        _FilterRow(state: state),
        const SizedBox(height: 16),

        // Summary Cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Total KM',
                value: '${state.totalKmThisMonth.toStringAsFixed(0)} km',
                subtitle: kmChangeText,
                subtitleColor: kmChangeColor,
                icon: Icons.speed,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Biaya Service',
                value: currencyFormat.format(state.totalMaintenanceCostThisMonth),
                icon: Icons.build,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Biaya BBM',
                value: currencyFormat.format(state.totalFuelCostThisMonth),
                icon: Icons.local_gas_station,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SummaryCard(
                title: 'Konsumsi',
                value: state.averageFleetKmPerLiter > 0
                    ? '${state.averageFleetKmPerLiter.toStringAsFixed(1)} km/L'
                    : '-',
                icon: Icons.eco,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // KM Chart
        if (state.dailyKmData.isNotEmpty) ...[
          Text('Kilometer Harian',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _KmLineChart(data: state.dailyKmData),
          ),
          const SizedBox(height: 24),
        ],

        // Monthly cost bar chart
        if (state.monthlyCostData.isNotEmpty) ...[
          Text('Biaya Maintenance per Bulan',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _MonthlyCostBarChart(data: state.monthlyCostData),
          ),
          const SizedBox(height: 24),
        ],

        // Pie chart by type
        if (state.typeCostData.isNotEmpty) ...[
          Text('Distribusi Biaya per Tipe',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _TypeCostPieChart(data: state.typeCostData),
          ),
          const SizedBox(height: 24),
        ],

        // Fuel cost bar chart
        if (state.monthlyFuelData.isNotEmpty) ...[
          Text('Pengeluaran BBM per Bulan',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: _FuelCostBarChart(data: state.monthlyFuelData),
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final AnalyticsLoaded state;
  const _FilterRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      builder: (context, vehicleState) {
        final vehicles =
            vehicleState is VehiclesLoaded ? vehicleState.vehicles : [];

        return Row(
          children: [
            // Vehicle filter
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: state.selectedVehicleId,
                decoration: const InputDecoration(
                  labelText: 'Kendaraan',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(
                      value: null, child: Text('Semua')),
                  ...vehicles.map((v) => DropdownMenuItem(
                        value: v.id,
                        child: Text(v.name),
                      )),
                ],
                onChanged: (id) {
                  context
                      .read<AnalyticsBloc>()
                      .add(ChangeAnalyticsVehicle(id));
                },
              ),
            ),
            const SizedBox(width: 8),
            // Period filter
            Expanded(
              child: DropdownButtonFormField<int>(
                value: state.periodDays,
                decoration: const InputDecoration(
                  labelText: 'Periode',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 hari')),
                  DropdownMenuItem(value: 30, child: Text('30 hari')),
                  DropdownMenuItem(value: 90, child: Text('3 bulan')),
                ],
                onChanged: (days) {
                  if (days != null) {
                    context
                        .read<AnalyticsBloc>()
                        .add(ChangeAnalyticsPeriod(days));
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? subtitleColor;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: subtitleColor)),
            ],
          ],
        ),
      ),
    );
  }
}

class _KmLineChart extends StatelessWidget {
  final List<DailyKm> data;
  const _KmLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.km);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (data.length / 5).ceilToDouble().clamp(1, 10),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const Text('');
                return Text(
                  DateFormat('dd/MM').format(data[idx].date),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: FlDotData(show: data.length <= 14),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                '${s.y.toStringAsFixed(0)} km',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MonthlyCostBarChart extends StatelessWidget {
  final List<MonthlyCost> data;
  const _MonthlyCostBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 50),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const Text('');
                return Text(months[data[idx].month - 1],
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.cost,
                color: Colors.orange,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                currencyFormat.format(rod.toY),
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TypeCostPieChart extends StatelessWidget {
  final List<MaintenanceTypeCost> data;
  const _TypeCostPieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.indigo,
    ];

    final total = data.fold<double>(0, (s, d) => s + d.cost);

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: data.asMap().entries.map((e) {
                final pct = (e.value.cost / total * 100).toStringAsFixed(0);
                return PieChartSectionData(
                  value: e.value.cost,
                  color: colors[e.key % colors.length],
                  title: '$pct%',
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                  radius: 60,
                );
              }).toList(),
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: data.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[e.key % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(e.value.typeName,
                      style: const TextStyle(fontSize: 11)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FuelCostBarChart extends StatelessWidget {
  final List<MonthlyFuel> data;
  const _FuelCostBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 50),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const Text('');
                return Text(months[data[idx].month - 1],
                    style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.cost,
                color: Colors.green,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                currencyFormat.format(rod.toY),
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
    );
  }
}
