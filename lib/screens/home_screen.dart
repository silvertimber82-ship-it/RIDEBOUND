import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/trips/models/trip.dart';
import '../core/constants/colors.dart';
import '../features/trips/repositories/trip_repository.dart';
import '../features/trips/screens/add_trip_screen.dart';
import '../features/trips/screens/trip_detail_screen.dart';
import '../features/maps/screens/map_screen.dart';
import '../features/gear/screens/gear_screen.dart';
import '../features/route_planner/screens/route_test_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _openAddTrip(BuildContext context, DateTime startDate) async {
    final trip = await Navigator.push<Trip>(
      context,
      MaterialPageRoute<Trip>(
        builder: (_) => AddTripScreen(initialStartDate: startDate),
      ),
    );

    if (trip != null && context.mounted) {
      await context.read<TripRepository>().addTrip(trip);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(trip: trip),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            const _Header(),
            const SizedBox(height: 20),
            const _StatsRow(),
            const SizedBox(height: 24),
            Text(
              'Upcoming Trips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _UpcomingTripsCalendar(
              onOpenTrip: (trip) => _openTrip(context, trip),
              onCreateTrip: (date) => _openAddTrip(context, date),
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Access',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _QuickAccessGrid(
              onFeatureTap: (feature) {
                if (feature == 'Maps') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MapScreen(),
                    ),
                  );
                } else if (feature == 'Route Testing') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RouteTestScreen(),
                    ),
                  );
                } else {
                  _showComingSoon(context, feature);
                }
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Trips',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _RecentTripsSection(
              onOpenTrip: (trip) => _openTrip(context, trip),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.two_wheeler,
            color: Colors.black,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RideBound',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Plan the ride. Live the journey.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications are coming soon!'),
              ),
            );
          },
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    );
  }
}

class _UpcomingTripsCalendar extends StatefulWidget {
  final ValueChanged<Trip> onOpenTrip;
  final ValueChanged<DateTime> onCreateTrip;

  const _UpcomingTripsCalendar({
    required this.onOpenTrip,
    required this.onCreateTrip,
  });

  @override
  State<_UpcomingTripsCalendar> createState() =>
      _UpcomingTripsCalendarState();
}

class _UpcomingTripsCalendarState extends State<_UpcomingTripsCalendar> {
  late DateTime _displayedMonth;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _displayedMonth = DateTime(today.year, today.month);
    _selectedDate = DateTime(today.year, today.month, today.day);
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _tripOccursOnDate(Trip trip, DateTime date) {
    if (trip.status == Trip.statusCompleted || trip.startDate == null) {
      return false;
    }

    final start = _dateOnly(trip.startDate!);
    final end = _dateOnly(trip.endDate ?? trip.startDate!);
    final selected = _dateOnly(date);

    return !selected.isBefore(start) && !selected.isAfter(end);
  }

  void _changeMonth(int amount) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + amount,
      );
      _selectedDate = DateTime(
        _displayedMonth.year,
        _displayedMonth.month,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TripRepository>(
      builder: (context, repository, child) {
        final trips = repository.trips.toList();
        final today = _dateOnly(DateTime.now());

        final firstDay = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          1,
        );
        final daysInMonth = DateTime(
          _displayedMonth.year,
          _displayedMonth.month + 1,
          0,
        ).day;
        final startingWeekday = firstDay.weekday % 7;
        final totalCells =
            ((startingWeekday + daysInMonth + 6) ~/ 7) * 7;

        final selectedTrips = trips
            .where((trip) => _tripOccursOnDate(trip, _selectedDate))
            .toList()
          ..sort((a, b) => a.startDate!.compareTo(b.startDate!));

        final upcomingTrips = trips.where((trip) {
          if (trip.status == Trip.statusCompleted || trip.startDate == null) {
            return false;
          }
          final end = _dateOnly(trip.endDate ?? trip.startDate!);
          return !end.isBefore(today);
        }).toList()
          ..sort((a, b) => a.startDate!.compareTo(b.startDate!));

        final nextTrips = upcomingTrips.take(3).toList();
        final monthName = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December',
        ][_displayedMonth.month - 1];

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '$monthName ${_displayedMonth.year}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - startingWeekday + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final date = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month,
                    dayNumber,
                  );
                  final isToday = _isSameDay(date, today);
                  final isSelected = _isSameDay(date, _selectedDate);
                  final hasPlannedTrips = trips.any(
                        (trip) =>
                    trip.status == Trip.statusPlanned &&
                        _tripOccursOnDate(trip, date),
                  );

                  final hasInProgressTrips = trips.any(
                        (trip) =>
                    trip.status == Trip.statusInProgress &&
                        _tripOccursOnDate(trip, date),
                  );

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedDate = date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isToday
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primary)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: hasInProgressTrips
                                    ? Border.all(
                                  color: isSelected
                                      ? Colors.black
                                      : AppColors.primary,
                                  width: 2,
                                )
                                    : null,
                              ),
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected ? Colors.black : null,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          if (hasPlannedTrips || hasInProgressTrips)
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.black
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 4),

                        ],
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      MaterialLocalizations.of(context)
                          .formatMediumDate(_selectedDate),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${selectedTrips.length} '
                        '${selectedTrips.length == 1 ? 'ride' : 'rides'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (selectedTrips.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No trips scheduled for this day.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...selectedTrips.map(
                      (trip) => _TripListTile(
                    trip: trip,
                    onTap: () => widget.onOpenTrip(trip),
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => widget.onCreateTrip(_selectedDate),
                icon: const Icon(Icons.add),
                label: const Text('Plan Trip for Selected Date'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coming Up Next',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${nextTrips.length} of 3',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (nextTrips.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No upcoming trips yet. Choose a date above to plan your next ride.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                ...nextTrips.map(
                      (trip) => _TripListTile(
                    trip: trip,
                    subtitle: MaterialLocalizations.of(context)
                        .formatMediumDate(trip.startDate!),
                    onTap: () => widget.onOpenTrip(trip),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TripListTile extends StatelessWidget {
  final Trip trip;
  final String? subtitle;
  final VoidCallback onTap;

  const _TripListTile({
    required this.trip,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: const Icon(
          Icons.two_wheeler,
          color: AppColors.primary,
        ),
        title: Text(
          trip.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle ?? '${trip.startLocation} → ${trip.endLocation}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trip.status == Trip.statusInProgress)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'IN PROGRESS',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<TripRepository>();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.route,
            value: repository.tripCount.toString(),
            label: 'Trips',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.speed,
            value:
            '${repository.trips.fold<double>(
              0.0,
                  (total, trip) => total + trip.distanceMiles,
            ).toStringAsFixed(1)} mi',
            label: 'Distance',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite,
            value: repository.favoriteCount.toString(),
            label: 'Favorites',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 26,
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final ValueChanged<String> onFeatureTap;

  const _QuickAccessGrid({
    required this.onFeatureTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _FeatureCard(
          icon: Icons.map_outlined,
          title: 'Maps',
          subtitle: 'Plan your route',
          color: AppColors.maps,
          onTap: () => onFeatureTap('Maps'),
        ),
    _FeatureCard(
    icon: Icons.backpack_outlined,
    title: 'Gear',
    subtitle: 'Packing checklist',
    color: AppColors.gear,
    onTap: () {
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => const GearScreen(),
    ),
    );
    },
        ),
        _FeatureCard(
          icon: Icons.cloud_outlined,
          title: 'Weather',
          subtitle: 'Check conditions',
          color: AppColors.weather,
          onTap: () => onFeatureTap('Weather'),
        ),
        _FeatureCard(
          icon: Icons.build_outlined,
          title: 'Maintenance',
          subtitle: 'Track service',
          color: AppColors.maintenance,
          onTap: () => onFeatureTap('Maintenance'),
        ),
        _FeatureCard(
          icon: Icons.route_outlined,
          title: 'Route Testing',
          subtitle: 'Test motorcycle routing',
          color: AppColors.maps,
          onTap: () => onFeatureTap('Route Testing'),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class _RecentTripsSection extends StatefulWidget {
  final ValueChanged<Trip> onOpenTrip;

  const _RecentTripsSection({
    required this.onOpenTrip,
  });

  @override
  State<_RecentTripsSection> createState() =>
      _RecentTripsSectionState();
}

class _RecentTripsSectionState extends State<_RecentTripsSection> {
  String _selectedFilter = 'all';

  static const int _pageSize = 10;
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<TripRepository>(
      builder: (context, repository, child) {
        final trips = repository.trips
            .where((trip) => trip.status == Trip.statusCompleted)
            .toList()
          ..sort(
                (a, b) => b.createdDate.compareTo(a.createdDate),
          );

        // Favorites only includes completed trips.
        final filteredTrips = _selectedFilter == 'favorites'
            ? trips.where((trip) => trip.isFavorite).toList()
            : trips;

        final totalTrips = filteredTrips.length;
        final pageCount = (totalTrips / _pageSize).ceil();

        // Keep the current page valid if trips are deleted.
        final currentPage = pageCount == 0
            ? 0
            : (_currentPage >= pageCount
            ? pageCount - 1
            : _currentPage);

        final startIndex = currentPage * _pageSize;
        final endIndex = (startIndex + _pageSize).clamp(0, totalTrips);

        final visibleTrips = filteredTrips
            .skip(startIndex)
            .take(_pageSize)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedFilter,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Filter Trips',
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Completed Trips'),
                ),
                DropdownMenuItem(
                  value: 'favorites',
                  child: Text('Favorite Completed Trips'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  _selectedFilter = value;
                  _currentPage = 0;
                });
              },
            ),
            const SizedBox(height: 16),

            if (filteredTrips.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _selectedFilter == 'favorites'
                        ? 'No favorite completed trips yet.'
                        : 'No completed trips yet. Your finished rides will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Showing ${startIndex + 1}–$endIndex of $totalTrips rides',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

              ...visibleTrips.map(
                    (trip) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: AppColors.surface,
                  child: ListTile(
                    leading: Icon(
                      Icons.two_wheeler,
                      color: AppColors.primary,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            trip.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'COMPLETED',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      '${trip.startLocation} → ${trip.endLocation}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trip.isFavorite)
                          const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 19,
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => widget.onOpenTrip(trip),
                  ),
                ),
              ),

              if (pageCount > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: currentPage > 0
                          ? () {
                        setState(() {
                          _currentPage = currentPage - 1;
                        });
                      }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Previous'),
                    ),
                    Text(
                      'Page ${currentPage + 1} of $pageCount',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton.icon(
                      onPressed: currentPage < pageCount - 1
                          ? () {
                        setState(() {
                          _currentPage = currentPage + 1;
                        });
                      }
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
