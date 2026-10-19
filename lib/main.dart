import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');
const String publicAppName = 'Fargeaula Ops';
const String organizationName = 'FOYER 3 EME AGE CLUB FARGEAULAIS';
const String facilityName = 'FOYER 3 EME AGE CLUB FARGEAULA';

const Color brandNavy = Color(0xFF061D52);
const Color brandTeal = Color(0xFF0A7A73);
const Color brandPurple = Color(0xFF36206D);
const Color brandGold = Color(0xFFE1B34A);
const Color brandSurface = Color(0xFFF5F7FB);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = OperationsStore(screenshotMode: kScreenshotMode);
  final initialData = await store.load();
  runApp(FargeaulaOpsApp(store: store, initialData: initialData));
}

class FargeaulaOpsApp extends StatelessWidget {
  const FargeaulaOpsApp({
    required this.store,
    required this.initialData,
    super.key,
  });

  final OperationsStore store;
  final OperationsData initialData;

  @override
  Widget build(BuildContext context) {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: brandNavy,
          brightness: Brightness.light,
        ).copyWith(
          primary: brandNavy,
          secondary: brandTeal,
          tertiary: brandGold,
          surface: brandSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: const Color(0xFF221800),
        );

    return MaterialApp(
      title: publicAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: brandSurface,
        appBarTheme: const AppBarTheme(
          backgroundColor: brandSurface,
          foregroundColor: brandNavy,
          centerTitle: false,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: brandGold.withValues(alpha: 0.26),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: brandNavy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: brandNavy,
            side: const BorderSide(color: brandNavy),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
          ),
        ),
      ),
      home: OperationsHome(store: store, initialData: initialData),
    );
  }
}

class OperationsHome extends StatefulWidget {
  const OperationsHome({
    required this.store,
    required this.initialData,
    super.key,
  });

  final OperationsStore store;
  final OperationsData initialData;

  @override
  State<OperationsHome> createState() => _OperationsHomeState();
}

class _OperationsHomeState extends State<OperationsHome> {
  late OperationsData _data = widget.initialData;
  int _selectedIndex = 0;

  Future<void> _persist() => widget.store.save(_data);

  void _updateData(OperationsData data) {
    setState(() => _data = data);
    _persist();
  }

  void _addAppointment(Appointment appointment) {
    _updateData(
      _data.copyWith(appointments: [appointment, ..._data.appointments]),
    );
  }

  void _addShipment(Shipment shipment) {
    _updateData(_data.copyWith(shipments: [shipment, ..._data.shipments]));
  }

  void _addEmployee(Employee employee) {
    _updateData(_data.copyWith(employees: [employee, ..._data.employees]));
  }

  void _setAppointmentStatus(String id, String status) {
    final updated = _data.appointments
        .map(
          (appointment) => appointment.id == id
              ? appointment.copyWith(status: status)
              : appointment,
        )
        .toList();
    _updateData(_data.copyWith(appointments: updated));
  }

  void _setShipmentStatus(String id, String status) {
    final updated = _data.shipments
        .map(
          (shipment) =>
              shipment.id == id ? shipment.copyWith(status: status) : shipment,
        )
        .toList();
    _updateData(_data.copyWith(shipments: updated));
  }

  void _toggleQualityItem(String id, bool value) {
    final updated = _data.qualityItems
        .map((item) => item.id == id ? item.copyWith(done: value) : item)
        .toList();
    _updateData(_data.copyWith(qualityItems: updated));
  }

  Future<void> _resetWorkspace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset workspace'),
        content: const Text(
          'Restore the starter appointments, shipments, checks, and team list on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      _updateData(OperationsData.starter());
    }
  }

  void _openAppointmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AppointmentForm(
        onSave: (appointment) {
          _addAppointment(appointment);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openShipmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ShipmentForm(
        onSave: (shipment) {
          _addShipment(shipment);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _openEmployeeSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => EmployeeForm(
        onSave: (employee) {
          _addEmployee(employee);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  String get _title {
    switch (_selectedIndex) {
      case 1:
        return 'Bookings';
      case 2:
        return 'Shipments';
      case 3:
        return 'Quality checks';
      case 4:
        return 'Directory';
      default:
        return 'Today';
    }
  }

  FloatingActionButton? get _fab {
    switch (_selectedIndex) {
      case 1:
        return FloatingActionButton.extended(
          key: const Key('add_record_button'),
          onPressed: _openAppointmentSheet,
          icon: const Icon(Icons.event_available),
          label: const Text('Book'),
        );
      case 2:
        return FloatingActionButton.extended(
          key: const Key('add_record_button'),
          onPressed: _openShipmentSheet,
          icon: const Icon(Icons.inventory_2),
          label: const Text('Log'),
        );
      case 4:
        return FloatingActionButton.extended(
          key: const Key('add_record_button'),
          onPressed: _openEmployeeSheet,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add'),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(
        data: _data,
        onOpenAppointments: () => setState(() => _selectedIndex = 1),
        onOpenShipments: () => setState(() => _selectedIndex = 2),
      ),
      AppointmentsPage(
        appointments: _data.appointments,
        onAdd: _openAppointmentSheet,
        onStatusChanged: _setAppointmentStatus,
      ),
      ShipmentsPage(
        shipments: _data.shipments,
        onAdd: _openShipmentSheet,
        onStatusChanged: _setShipmentStatus,
      ),
      QualityPage(items: _data.qualityItems, onChanged: _toggleQualityItem),
      DirectoryPage(
        employees: _data.employees,
        onAdd: _openEmployeeSheet,
        onReset: _resetWorkspace,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Text(
              facilityName,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey<int>(_selectedIndex),
          child: pages[_selectedIndex],
        ),
      ),
      floatingActionButton: _fab,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            key: Key('nav_home'),
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            key: Key('nav_appointments'),
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Book',
          ),
          NavigationDestination(
            key: Key('nav_shipments'),
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Ship',
          ),
          NavigationDestination(
            key: Key('nav_quality'),
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'QC',
          ),
          NavigationDestination(
            key: Key('nav_directory'),
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2),
            label: 'Team',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.data,
    required this.onOpenAppointments,
    required this.onOpenShipments,
    super.key,
  });

  final OperationsData data;
  final VoidCallback onOpenAppointments;
  final VoidCallback onOpenShipments;

  @override
  Widget build(BuildContext context) {
    final completeChecks = data.qualityItems.where((item) => item.done).length;
    final pendingShipments = data.shipments
        .where((shipment) => shipment.status != 'Received')
        .length;
    final confirmedBookings = data.appointments
        .where((item) => item.status == 'Confirmed')
        .length;
    final availableStaff = data.employees
        .where((employee) => employee.status == 'On shift')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const FeaturedPanel(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 620 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.35,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: [
                MetricTile(
                  icon: Icons.event_available,
                  label: 'Confirmed',
                  value: '$confirmedBookings',
                  accent: brandGold,
                ),
                MetricTile(
                  icon: Icons.inventory_2,
                  label: 'Active loads',
                  value: '$pendingShipments',
                  accent: brandTeal,
                ),
                MetricTile(
                  icon: Icons.verified,
                  label: 'QC complete',
                  value: '$completeChecks/${data.qualityItems.length}',
                  accent: brandPurple,
                ),
                MetricTile(
                  icon: Icons.badge,
                  label: 'On shift',
                  value: '$availableStaff',
                  accent: brandNavy,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Fargeaula Ops',
          actionLabel: 'Bookings',
          onAction: onOpenAppointments,
        ),
        const SizedBox(height: 8),
        PriorityCard(
          icon: Icons.event_note,
          title: data.appointments.first.resident,
          detail:
              '${data.appointments.first.service} at ${data.appointments.first.time}',
          status: data.appointments.first.status,
          color: brandGold,
        ),
        const SizedBox(height: 8),
        PriorityCard(
          icon: Icons.local_shipping,
          title: data.shipments.first.reference,
          detail:
              '${data.shipments.first.vendor} arrives ${data.shipments.first.eta}',
          status: data.shipments.first.status,
          color: brandTeal,
          onTap: onOpenShipments,
        ),
        const SizedBox(height: 16),
        SectionHeader(title: 'Coverage notes'),
        const SizedBox(height: 8),
        InfoStrip(
          icon: Icons.lock_outline,
          title: 'Local workspace',
          body:
              'Bookings, shipment notes, checklists, and staff details stay on this device.',
        ),
      ],
    );
  }
}

class FeaturedPanel extends StatelessWidget {
  const FeaturedPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 2.05,
            child: Image.asset(
              'docs/featured.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: brandNavy),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    brandNavy.withValues(alpha: 0.86),
                    brandNavy.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 120,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  publicAppName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Daily bookings, shipment follow-up, quality checks, and team coverage.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentsPage extends StatelessWidget {
  const AppointmentsPage({
    required this.appointments,
    required this.onAdd,
    required this.onStatusChanged,
    super.key,
  });

  final List<Appointment> appointments;
  final VoidCallback onAdd;
  final void Function(String id, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionHeader(
          title: 'Appointment board',
          actionLabel: 'New',
          onAction: onAdd,
        ),
        const SizedBox(height: 8),
        for (final appointment in appointments)
          AppointmentCard(
            appointment: appointment,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => AppointmentDetailScreen(
                    appointment: appointment,
                    onStatusChanged: onStatusChanged,
                  ),
                ),
              );
            },
            onStatusChanged: onStatusChanged,
          ),
      ],
    );
  }
}

class ShipmentsPage extends StatelessWidget {
  const ShipmentsPage({
    required this.shipments,
    required this.onAdd,
    required this.onStatusChanged,
    super.key,
  });

  final List<Shipment> shipments;
  final VoidCallback onAdd;
  final void Function(String id, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionHeader(
          title: 'Shipment log',
          actionLabel: 'Log',
          onAction: onAdd,
        ),
        const SizedBox(height: 8),
        for (final shipment in shipments)
          ShipmentCard(
            shipment: shipment,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ShipmentDetailScreen(
                    shipment: shipment,
                    onStatusChanged: onStatusChanged,
                  ),
                ),
              );
            },
            onStatusChanged: onStatusChanged,
          ),
      ],
    );
  }
}

class QualityPage extends StatelessWidget {
  const QualityPage({required this.items, required this.onChanged, super.key});

  final List<QualityItem> items;
  final void Function(String id, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) => item.done).length;
    final ratio = completed / items.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SectionHeader(title: 'Quality control'),
        const SizedBox(height: 8),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check, color: brandPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$completed of ${items.length} checks complete',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  color: brandPurple,
                  backgroundColor: brandPurple.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final item in items)
          SurfaceCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: CheckboxListTile(
              value: item.done,
              onChanged: (value) => onChanged(item.id, value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                item.task,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${item.area} | ${item.owner} | due ${item.due}'),
              secondary: ScoreBadge(score: item.score),
            ),
          ),
      ],
    );
  }
}

class DirectoryPage extends StatelessWidget {
  const DirectoryPage({
    required this.employees,
    required this.onAdd,
    required this.onReset,
    super.key,
  });

  final List<Employee> employees;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        SectionHeader(
          title: 'Employee directory',
          actionLabel: 'Add',
          onAction: onAdd,
        ),
        const SizedBox(height: 8),
        for (final employee in employees)
          EmployeeCard(
            employee: employee,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) =>
                      EmployeeDetailScreen(employee: employee),
                ),
              );
            },
          ),
        const SizedBox(height: 10),
        SectionHeader(title: 'Settings and privacy'),
        const SizedBox(height: 8),
        InfoStrip(
          icon: Icons.privacy_tip_outlined,
          title: 'No account or cloud sync',
          body:
              'This app stores operational records locally and does not send them to a server.',
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          key: const Key('reset_workspace_button'),
          onPressed: onReset,
          icon: const Icon(Icons.restore),
          label: const Text('Restore starter workspace'),
        ),
      ],
    );
  }
}

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({
    required this.appointment,
    required this.onStatusChanged,
    super.key,
  });

  final Appointment appointment;
  final void Function(String id, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailHeader(
            icon: Icons.event_available,
            title: appointment.resident,
            status: appointment.status,
          ),
          const SizedBox(height: 12),
          DetailRow(label: 'Service', value: appointment.service),
          DetailRow(label: 'Date', value: appointment.date),
          DetailRow(label: 'Time', value: appointment.time),
          DetailRow(label: 'Room', value: appointment.room),
          DetailRow(label: 'Notes', value: appointment.note),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              onStatusChanged(appointment.id, 'Completed');
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Mark completed'),
          ),
        ],
      ),
    );
  }
}

class ShipmentDetailScreen extends StatelessWidget {
  const ShipmentDetailScreen({
    required this.shipment,
    required this.onStatusChanged,
    super.key,
  });

  final Shipment shipment;
  final void Function(String id, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shipment detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailHeader(
            icon: Icons.local_shipping,
            title: shipment.reference,
            status: shipment.status,
          ),
          const SizedBox(height: 12),
          DetailRow(label: 'Vendor', value: shipment.vendor),
          DetailRow(label: 'Items', value: shipment.items),
          DetailRow(label: 'ETA', value: shipment.eta),
          DetailRow(
            label: 'QC note',
            value: shipment.temperatureChecked
                ? 'Cold chain verified'
                : 'Standard receiving',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              onStatusChanged(shipment.id, 'Received');
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.inventory),
            label: const Text('Mark received'),
          ),
        ],
      ),
    );
  }
}

class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({required this.employee, super.key});

  final Employee employee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DetailHeader(
            icon: Icons.badge,
            title: employee.name,
            status: employee.status,
          ),
          const SizedBox(height: 12),
          DetailRow(label: 'Role', value: employee.role),
          DetailRow(label: 'Shift', value: employee.shift),
          DetailRow(label: 'Phone', value: employee.phone),
          const SizedBox(height: 16),
          InfoStrip(
            icon: Icons.info_outline,
            title: 'Directory use',
            body:
                'Use these locally saved details to coordinate coverage and internal follow-up.',
          ),
        ],
      ),
    );
  }
}

class AppointmentForm extends StatefulWidget {
  const AppointmentForm({required this.onSave, super.key});

  final ValueChanged<Appointment> onSave;

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _resident = TextEditingController();
  final _service = TextEditingController(text: 'Care coordination');
  final _date = TextEditingController(text: 'May 12, 2026');
  final _time = TextEditingController(text: '10:00 AM');
  final _room = TextEditingController(text: 'Reception');
  final _note = TextEditingController(text: 'Prepare staff handoff notes.');

  @override
  void dispose() {
    _resident.dispose();
    _service.dispose();
    _date.dispose();
    _time.dispose();
    _room.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'New appointment',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('appointment_guest_field'),
              controller: _resident,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Resident or visitor',
              ),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              key: const Key('appointment_service_field'),
              controller: _service,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Service'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _date,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Date'),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _time,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Time'),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _room,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _note,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('save_appointment_button'),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  widget.onSave(
                    Appointment(
                      id: _newId('apt'),
                      resident: _resident.text.trim(),
                      service: _service.text.trim(),
                      date: _date.text.trim(),
                      time: _time.text.trim(),
                      room: _room.text.trim(),
                      note: _note.text.trim().isEmpty
                          ? 'No notes added.'
                          : _note.text.trim(),
                      status: 'Confirmed',
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save booking'),
            ),
          ],
        ),
      ),
    );
  }
}

class ShipmentForm extends StatefulWidget {
  const ShipmentForm({required this.onSave, super.key});

  final ValueChanged<Shipment> onSave;

  @override
  State<ShipmentForm> createState() => _ShipmentFormState();
}

class _ShipmentFormState extends State<ShipmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _reference = TextEditingController();
  final _vendor = TextEditingController(text: 'Primary supplier');
  final _items = TextEditingController(text: 'Care supplies and pantry stock');
  final _eta = TextEditingController(text: 'Today, 2:30 PM');
  bool _temperatureChecked = false;

  @override
  void dispose() {
    _reference.dispose();
    _vendor.dispose();
    _items.dispose();
    _eta.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'New shipment',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('shipment_reference_field'),
              controller: _reference,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Reference'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _vendor,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Vendor'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _items,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Items'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _eta,
              decoration: const InputDecoration(labelText: 'Arrival window'),
              validator: _required,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _temperatureChecked,
              onChanged: (value) => setState(() => _temperatureChecked = value),
              title: const Text('Cold chain checked'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('save_shipment_button'),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  widget.onSave(
                    Shipment(
                      id: _newId('ship'),
                      reference: _reference.text.trim(),
                      vendor: _vendor.text.trim(),
                      items: _items.text.trim(),
                      eta: _eta.text.trim(),
                      status: 'Expected',
                      temperatureChecked: _temperatureChecked,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save shipment'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmployeeForm extends StatefulWidget {
  const EmployeeForm({required this.onSave, super.key});

  final ValueChanged<Employee> onSave;

  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _role = TextEditingController(text: 'Operations assistant');
  final _shift = TextEditingController(text: 'Weekday morning');
  final _phone = TextEditingController(text: 'Internal extension');

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _shift.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'New team member',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              key: const Key('employee_name_field'),
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _role,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Role'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _shift,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Shift'),
              validator: _required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Contact note'),
              validator: _required,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('save_employee_button'),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  widget.onSave(
                    Employee(
                      id: _newId('emp'),
                      name: _name.text.trim(),
                      role: _role.text.trim(),
                      shift: _shift.text.trim(),
                      phone: _phone.text.trim(),
                      status: 'On shift',
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Save employee'),
            ),
          ],
        ),
      ),
    );
  }
}

class FormSheet extends StatelessWidget {
  const FormSheet({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                tooltip: 'Close',
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    required this.appointment,
    required this.onTap,
    required this.onStatusChanged,
    super.key,
  });

  final Appointment appointment;
  final VoidCallback onTap;
  final void Function(String id, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.event_available, color: brandGold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.resident,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${appointment.service} | ${appointment.date} | ${appointment.time}',
                        ),
                      ],
                    ),
                  ),
                  StatusPill(label: appointment.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                appointment.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.check, size: 18),
                    label: const Text('Complete'),
                    onPressed: () =>
                        onStatusChanged(appointment.id, 'Completed'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: const Text('Reschedule'),
                    onPressed: () =>
                        onStatusChanged(appointment.id, 'Needs review'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({
    required this.shipment,
    required this.onTap,
    required this.onStatusChanged,
    super.key,
  });

  final Shipment shipment;
  final VoidCallback onTap;
  final void Function(String id, String status) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.inventory_2, color: brandTeal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipment.reference,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 3),
                        Text('${shipment.vendor} | ${shipment.eta}'),
                      ],
                    ),
                  ),
                  StatusPill(label: shipment.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                shipment.items,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.move_to_inbox, size: 18),
                    label: const Text('Received'),
                    onPressed: () => onStatusChanged(shipment.id, 'Received'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.report_problem_outlined, size: 18),
                    label: const Text('Hold'),
                    onPressed: () => onStatusChanged(shipment.id, 'Hold'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmployeeCard extends StatelessWidget {
  const EmployeeCard({required this.employee, required this.onTap, super.key});

  final Employee employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: brandNavy,
          foregroundColor: Colors.white,
          child: Text(employee.initials),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${employee.role} | ${employee.shift}'),
        trailing: StatusPill(label: employee.status),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class PriorityCard extends StatelessWidget {
  const PriorityCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.status,
    required this.color,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String status;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(detail),
        trailing: StatusPill(label: status),
      ),
    );
  }
}

class InfoStrip extends StatelessWidget {
  const InfoStrip({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: brandTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DetailHeader extends StatelessWidget {
  const DetailHeader({
    required this.icon,
    required this.title,
    required this.status,
    super.key,
  });

  final IconData icon;
  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: brandGold.withValues(alpha: 0.22),
            foregroundColor: brandNavy,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          StatusPill(label: status),
        ],
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: brandTeal),
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(actionLabel!),
          ),
      ],
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({required this.child, this.margin, super.key});

  final Widget child;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.07)),
      ),
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Completed' || 'Received' || 'On shift' => brandTeal,
      'Hold' || 'Needs review' => brandPurple,
      _ => brandGold,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          style: TextStyle(
            color: Color.alphaBlend(color.withValues(alpha: 0.35), brandNavy),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class ScoreBadge extends StatelessWidget {
  const ScoreBadge({required this.score, super.key});

  final int score;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brandGold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          '$score%',
          style: const TextStyle(fontWeight: FontWeight.w900, color: brandNavy),
        ),
      ),
    );
  }
}

String? _required(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

String _newId(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}';

class OperationsStore {
  OperationsStore({required this.screenshotMode});

  static const String _storageFileName = 'fargeaula_operations_data_v1.json';
  final bool screenshotMode;

  Directory get _storageDirectory {
    if (Platform.isAndroid) {
      return Directory('/data/user/0/com.taziggg100.foyer_fargeaula_ops/files');
    }
    return Directory('${Directory.systemTemp.path}/fargeaula_ops');
  }

  File get _storageFile => File('${_storageDirectory.path}/$_storageFileName');

  Future<OperationsData> load() async {
    if (screenshotMode) {
      return OperationsData.starter();
    }

    final file = _storageFile;
    if (!file.existsSync()) {
      return OperationsData.starter();
    }

    final raw = await file.readAsString();
    if (raw.isEmpty) {
      return OperationsData.starter();
    }

    try {
      return OperationsData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return OperationsData.starter();
    } on TypeError {
      return OperationsData.starter();
    }
  }

  Future<void> save(OperationsData data) async {
    if (screenshotMode) {
      return;
    }

    final file = _storageFile;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data.toJson()), flush: true);
  }
}

class OperationsData {
  const OperationsData({
    required this.appointments,
    required this.shipments,
    required this.qualityItems,
    required this.employees,
  });

  final List<Appointment> appointments;
  final List<Shipment> shipments;
  final List<QualityItem> qualityItems;
  final List<Employee> employees;

  OperationsData copyWith({
    List<Appointment>? appointments,
    List<Shipment>? shipments,
    List<QualityItem>? qualityItems,
    List<Employee>? employees,
  }) {
    return OperationsData(
      appointments: appointments ?? this.appointments,
      shipments: shipments ?? this.shipments,
      qualityItems: qualityItems ?? this.qualityItems,
      employees: employees ?? this.employees,
    );
  }

  Map<String, dynamic> toJson() => {
    'appointments': appointments.map((item) => item.toJson()).toList(),
    'shipments': shipments.map((item) => item.toJson()).toList(),
    'qualityItems': qualityItems.map((item) => item.toJson()).toList(),
    'employees': employees.map((item) => item.toJson()).toList(),
  };

  factory OperationsData.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(Map<String, dynamic>) parser) {
      final raw = json[key];
      if (raw is! List) {
        return <T>[];
      }
      return raw.whereType<Map<String, dynamic>>().map(parser).toList();
    }

    final data = OperationsData(
      appointments: parseList('appointments', Appointment.fromJson),
      shipments: parseList('shipments', Shipment.fromJson),
      qualityItems: parseList('qualityItems', QualityItem.fromJson),
      employees: parseList('employees', Employee.fromJson),
    );

    if (data.appointments.isEmpty ||
        data.shipments.isEmpty ||
        data.qualityItems.isEmpty ||
        data.employees.isEmpty) {
      return OperationsData.starter();
    }

    return data;
  }

  factory OperationsData.starter() => OperationsData(
    appointments: const [
      Appointment(
        id: 'apt-1',
        resident: 'Mme Bernard family visit',
        service: 'Appointment booking',
        date: 'May 11, 2026',
        time: '09:30 AM',
        room: 'Reception desk',
        note:
            'Confirm visitor arrival, prepare lounge access, and notify care lead.',
        status: 'Confirmed',
      ),
      Appointment(
        id: 'apt-2',
        resident: 'Transport coordination',
        service: 'External medical transfer',
        date: 'May 11, 2026',
        time: '11:15 AM',
        room: 'North entrance',
        note: 'Driver arrival window logged. Wheelchair support assigned.',
        status: 'Needs review',
      ),
      Appointment(
        id: 'apt-3',
        resident: 'Supplier intake meeting',
        service: 'Operations planning',
        date: 'May 12, 2026',
        time: '02:00 PM',
        room: 'Office 2',
        note: 'Review weekly shipment cadence and exception notes.',
        status: 'Confirmed',
      ),
    ],
    shipments: const [
      Shipment(
        id: 'ship-1',
        reference: 'FRG-2408',
        vendor: 'Care supply partner',
        items: 'Gloves, linen packs, hygiene supplies, and pantry dry goods',
        eta: 'Today, 01:45 PM',
        status: 'Expected',
        temperatureChecked: false,
      ),
      Shipment(
        id: 'ship-2',
        reference: 'FRG-2399',
        vendor: 'Kitchen service',
        items: 'Fresh produce and chilled meal prep ingredients',
        eta: 'Today, 08:40 AM',
        status: 'Received',
        temperatureChecked: true,
      ),
      Shipment(
        id: 'ship-3',
        reference: 'FRG-2411',
        vendor: 'Maintenance stock',
        items: 'Cleaning inventory and safety signage',
        eta: 'Tomorrow, 10:20 AM',
        status: 'Expected',
        temperatureChecked: false,
      ),
    ],
    qualityItems: const [
      QualityItem(
        id: 'qc-1',
        area: 'Reception',
        task: 'Visitor register matches appointment board',
        owner: 'Operations lead',
        due: '09:00',
        done: true,
        score: 96,
      ),
      QualityItem(
        id: 'qc-2',
        area: 'Receiving',
        task: 'Shipment intake photos and counts verified',
        owner: 'Logistics',
        due: '14:00',
        done: false,
        score: 82,
      ),
      QualityItem(
        id: 'qc-3',
        area: 'Care floor',
        task: 'Daily safety checklist signed by floor lead',
        owner: 'Care lead',
        due: '16:30',
        done: false,
        score: 78,
      ),
      QualityItem(
        id: 'qc-4',
        area: 'Office',
        task: 'Employee coverage board reviewed',
        owner: 'Administrator',
        due: '17:00',
        done: true,
        score: 91,
      ),
    ],
    employees: const [
      Employee(
        id: 'emp-1',
        name: 'Nadia Martin',
        role: 'Operations lead',
        shift: 'Morning',
        phone: 'Internal extension 101',
        status: 'On shift',
      ),
      Employee(
        id: 'emp-2',
        name: 'Karim Lopez',
        role: 'Receiving desk',
        shift: 'Midday',
        phone: 'Internal extension 118',
        status: 'On shift',
      ),
      Employee(
        id: 'emp-3',
        name: 'Sophie Mercier',
        role: 'Quality coordinator',
        shift: 'Afternoon',
        phone: 'Internal extension 126',
        status: 'Off shift',
      ),
    ],
  );
}

class Appointment {
  const Appointment({
    required this.id,
    required this.resident,
    required this.service,
    required this.date,
    required this.time,
    required this.room,
    required this.note,
    required this.status,
  });

  final String id;
  final String resident;
  final String service;
  final String date;
  final String time;
  final String room;
  final String note;
  final String status;

  Appointment copyWith({String? status}) => Appointment(
    id: id,
    resident: resident,
    service: service,
    date: date,
    time: time,
    room: room,
    note: note,
    status: status ?? this.status,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'resident': resident,
    'service': service,
    'date': date,
    'time': time,
    'room': room,
    'note': note,
    'status': status,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: _readString(json['id']),
    resident: _readString(json['resident']),
    service: _readString(json['service']),
    date: _readString(json['date']),
    time: _readString(json['time']),
    room: _readString(json['room']),
    note: _readString(json['note']),
    status: _readString(json['status']),
  );
}

class Shipment {
  const Shipment({
    required this.id,
    required this.reference,
    required this.vendor,
    required this.items,
    required this.eta,
    required this.status,
    required this.temperatureChecked,
  });

  final String id;
  final String reference;
  final String vendor;
  final String items;
  final String eta;
  final String status;
  final bool temperatureChecked;

  Shipment copyWith({String? status}) => Shipment(
    id: id,
    reference: reference,
    vendor: vendor,
    items: items,
    eta: eta,
    status: status ?? this.status,
    temperatureChecked: temperatureChecked,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'reference': reference,
    'vendor': vendor,
    'items': items,
    'eta': eta,
    'status': status,
    'temperatureChecked': temperatureChecked,
  };

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
    id: _readString(json['id']),
    reference: _readString(json['reference']),
    vendor: _readString(json['vendor']),
    items: _readString(json['items']),
    eta: _readString(json['eta']),
    status: _readString(json['status']),
    temperatureChecked: json['temperatureChecked'] == true,
  );
}

class QualityItem {
  const QualityItem({
    required this.id,
    required this.area,
    required this.task,
    required this.owner,
    required this.due,
    required this.done,
    required this.score,
  });

  final String id;
  final String area;
  final String task;
  final String owner;
  final String due;
  final bool done;
  final int score;

  QualityItem copyWith({bool? done}) => QualityItem(
    id: id,
    area: area,
    task: task,
    owner: owner,
    due: due,
    done: done ?? this.done,
    score: score,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'area': area,
    'task': task,
    'owner': owner,
    'due': due,
    'done': done,
    'score': score,
  };

  factory QualityItem.fromJson(Map<String, dynamic> json) => QualityItem(
    id: _readString(json['id']),
    area: _readString(json['area']),
    task: _readString(json['task']),
    owner: _readString(json['owner']),
    due: _readString(json['due']),
    done: json['done'] == true,
    score: json['score'] is int
        ? json['score'] as int
        : int.tryParse(_readString(json['score'])) ?? 0,
  );
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.shift,
    required this.phone,
    required this.status,
  });

  final String id;
  final String name;
  final String role;
  final String shift;
  final String phone;
  final String status;

  String get initials {
    final parts = name.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'shift': shift,
    'phone': phone,
    'status': status,
  };

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: _readString(json['id']),
    name: _readString(json['name']),
    role: _readString(json['role']),
    shift: _readString(json['shift']),
    phone: _readString(json['phone']),
    status: _readString(json['status']),
  );
}

String _readString(Object? value) => value?.toString() ?? '';
