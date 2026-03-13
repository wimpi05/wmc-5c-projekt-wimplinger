import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

const double _kUnifiedHeaderHeight = 108;
const double _kUnifiedHeaderTitleSize = 28;
const double _kUnifiedHeaderSubtitleSize = 13;
const double _kUnifiedHeaderTitleSubtitleGap = 4;
const double _kUnifiedHeaderLeftInset = 24;

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService _apiService = ApiService();

  bool _loading = true;
  String? _error;

  int _totalRides = 0;
  int _asDriver = 0;
  int _asPassenger = 0;
  double _kmShared = 0;
  double _co2Saved = 0;
  List<double> _weekKm = List.filled(7, 0);
  List<String> _weekLabels = const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final summary = await _apiService.getMyRideStats();
      final weekly = await _apiService.getMyWeeklyStats();

      final weekMap = <String, double>{};
      for (final row in weekly) {
        final day = (row['day_key'] ?? '').toString();
        final km = (row['km'] as num?)?.toDouble() ?? 0;
        weekMap[day] = km;
      }

      final now = DateTime.now();
      const shortWeekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
      final weekValues = List.generate(7, (index) {
        final day = now.subtract(Duration(days: 6 - index));
        final key =
            '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        return weekMap[key] ?? 0;
      });
      final weekLabels = List.generate(7, (index) {
        final day = now.subtract(Duration(days: 6 - index));
        return shortWeekdays[day.weekday - 1];
      });

      if (!mounted) return;
      setState(() {
        _totalRides = (summary['total_rides'] as num?)?.toInt() ?? 0;
        _asDriver = (summary['as_driver'] as num?)?.toInt() ?? 0;
        _asPassenger = (summary['as_passenger'] as num?)?.toInt() ?? 0;
        _kmShared = (summary['km_shared'] as num?)?.toDouble() ?? 0;
        _co2Saved = (summary['co2_saved'] as num?)?.toDouble() ?? 0;
        _weekKm = weekValues;
        _weekLabels = weekLabels;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: topInset + _kUnifiedHeaderHeight,
          padding: EdgeInsets.only(top: topInset),
          decoration: BoxDecoration(color: scheme.primary),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(_kUnifiedHeaderLeftInset, 0, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Dein Impact',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: _kUnifiedHeaderTitleSize,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: _kUnifiedHeaderTitleSubtitleGap),
                  Text(
                    'Verfolge deine Fahrgemeinschafts-Statistik',
                    style: TextStyle(
                      fontSize: _kUnifiedHeaderSubtitleSize,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Statistiken konnten nicht geladen werden:\n$_error', textAlign: TextAlign.center))
                  : RefreshIndicator(
                      onRefresh: _loadStats,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        children: [
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _buildCo2Card(_co2Saved, scheme)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildKmCard(_kmShared, scheme)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildWeeklyChartCard(_weekLabels, _weekKm, scheme),
                          const SizedBox(height: 16),
                          _buildBottomStatsRow(_totalRides, _asDriver, _asPassenger, scheme),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCo2Card(double co2Kg, ColorScheme scheme) {
    final bg = Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.13),
      scheme.surfaceContainer,
    );
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco_rounded, color: scheme.primary, size: 22),
                const Spacer(),
                _badge('Gesamt', scheme),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '${co2Kg.toStringAsFixed(1)} kg',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 34,
                color: scheme.primary,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'CO₂ gespart',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKmCard(double totalKm, ColorScheme scheme) {
    final itemColor = scheme.secondary;
    final bg = Color.alphaBlend(
      itemColor.withValues(alpha: 0.13),
      scheme.surfaceContainer,
    );
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, color: itemColor, size: 22),
                const Spacer(),
                _badge('Gesamt', scheme),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              totalKm.toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 34,
                color: itemColor,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'KM geteilt',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildWeeklyChartCard(
    List<String> labels,
    List<double> kmValues,
    ColorScheme scheme,
  ) {
    final maxVal = kmValues.reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal > 0 ? (maxVal * 1.4).ceilToDouble() : 20.0;
    final interval = chartMax > 16 ? (chartMax / 4).roundToDouble() : 5.0;

    final spots = List.generate(
      kmValues.length,
      (i) => FlSpot(i.toDouble(), kmValues[i]),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart_rounded, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Kilometer Letzte 7 Tage',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: chartMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.55),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[idx], style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: scheme.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                          radius: 4,
                          color: scheme.primary,
                          strokeWidth: 2,
                          strokeColor: scheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary.withValues(alpha: 0.22),
                            scheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomStatsRow(
    int total,
    int driver,
    int passenger,
    ColorScheme scheme,
  ) {
    return Row(
      children: [
        Expanded(child: _buildStatTile(total.toString(), 'Fahrten\ngesamt', scheme.primary, scheme)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile(driver.toString(), 'Als\nFahrer', scheme.secondary, scheme)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatTile(passenger.toString(), 'Als\nMitfahrer', scheme.tertiary, scheme)),
      ],
    );
  }

  Widget _buildStatTile(
    String value,
    String label,
    Color valueColor,
    ColorScheme scheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
