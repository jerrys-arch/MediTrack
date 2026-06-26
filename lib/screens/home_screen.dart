import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../services/notification_service.dart';
import 'medication_screen.dart';
import 'add_medication_screen.dart';
import 'symptom_tracker_screen.dart';
import 'add_symptom_entry_screen.dart';
import 'health_journal_screen.dart';
import 'add_health_entry_screen.dart';
import 'emergency_screen.dart';
import 'settings_screen.dart';
import 'package:http/http.dart' as http;

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _currentIndex = 0;

  // ── Patient data ───────────────────────────────────────────────
  List<Map<String, dynamic>> allMedications = [];
  List<Map<String, dynamic>> todaysMedications = [];
  List<Map<String, dynamic>> upcomingReminders = [];

  // ── Caregiver data ─────────────────────────────────────────────
  List<Map<String, dynamic>> myPatients = [];
  Map<int, List<Map<String, dynamic>>> patientDoses = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isCaregiver) {
      await _fetchPatients(auth.accessToken!);
    } else {
      await _fetchMedications(auth.accessToken!);
    }
  }

  // ── Patient: fetch own medications ─────────────────────────────

  Future<void> _fetchMedications(String token) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.medications),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        allMedications = List<Map<String, dynamic>>.from(data);
        final now = DateTime.now();
        todaysMedications = allMedications.where((med) {
          final createdAt = DateTime.tryParse(med['created_at'] ?? '');
          if (createdAt == null) return false;
          return createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
        }).toList();
        upcomingReminders = allMedications
            .where((med) =>
                med['reminder'] == true &&
                (med['taken'] == false || med['taken'] == null))
            .toList();

        // ── Ensure local reminders are scheduled on THIS device ──────────
        // This is the fix for: caregiver adds medication on their phone,
        // but the patient's phone never schedules its own local alarm.
        // Every time the patient opens their dashboard, we check each
        // medication that has reminder=true and schedule it locally if
        // we haven't already (tracked via shared_preferences so we don't
        // re-schedule the same alarm over and over).
        await _ensureLocalRemindersScheduled(allMedications);
      }
    } catch (e) {
      debugPrint('Error fetching medications: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Schedules a local notification for any medication with reminder=true
  /// that hasn't already been scheduled on this device.
  Future<void> _ensureLocalRemindersScheduled(
      List<Map<String, dynamic>> medications) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledIds =
        prefs.getStringList('scheduledReminderIds') ?? <String>[];

    bool changed = false;

    for (final med in medications) {
      final reminder = med['reminder'] == true;
      final timeStr = med['time'] as String?;
      final medId = med['id'];

      if (!reminder || timeStr == null || timeStr.trim().isEmpty) continue;
      if (medId == null) continue;

      final idKey = medId.toString();
      if (scheduledIds.contains(idKey)) continue; // already scheduled

      final parts = timeStr.split(':');
      if (parts.length < 2) continue;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) continue;

      final name = med['name'] ?? 'Medication';
      final dosage = med['dosage'] ?? '';
      final frequency = med['frequency'] ?? 'Daily';
      final dayOfWeek = med['day_of_week'];

      try {
        if (frequency == 'Weekly' && dayOfWeek != null) {
          await NotificationService().scheduleWeeklyNotification(
            id: medId,
            title: '💊 Time for $name',
            body: 'Dosage: $dosage — tap to confirm',
            dayOfWeek: dayOfWeek is int ? dayOfWeek : int.parse(dayOfWeek.toString()),
            hour: hour,
            minute: minute,
          );
        } else {
          await NotificationService().scheduleDailyNotification(
            id: medId,
            title: '💊 Time for $name',
            body: 'Dosage: $dosage — tap to confirm',
            hour: hour,
            minute: minute,
          );
        }
        scheduledIds.add(idKey);
        changed = true;
        debugPrint('✅ Locally scheduled reminder for $name (id: $medId)');
      } catch (e) {
        debugPrint('Failed to schedule local reminder for $name: $e');
      }
    }

    if (changed) {
      await prefs.setStringList('scheduledReminderIds', scheduledIds);
    }
  }

  Future<void> _markMedicationAsTaken(int medId) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    try {
      final dosesResponse = await http.get(
        Uri.parse('${ApiConfig.care}doses/'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (dosesResponse.statusCode == 200) {
        final List doses = jsonDecode(dosesResponse.body);
        final pending = doses.where((d) =>
            d['medication'] == medId && d['status'] == 'pending'
        ).toList();

        if (pending.isNotEmpty) {
          final doseLogId = pending.first['id'];
          final confirmResponse = await http.post(
            Uri.parse('${ApiConfig.care}doses/confirm/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'dose_log_id': doseLogId}),
          );

          if (confirmResponse.statusCode == 200) {
            await http.patch(
              Uri.parse('${ApiConfig.medications}$medId/'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'taken': true}),
            );
            // Cancel the local reminder/missed-dose alert since it's confirmed
            await NotificationService().cancelNotification(medId);
            if (mounted) await _fetchMedications(token);
          }
        } else {
          await http.patch(
            Uri.parse('${ApiConfig.medications}$medId/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'taken': true}),
          );
          await NotificationService().cancelNotification(medId);
          if (mounted) await _fetchMedications(token);
        }
      }
    } catch (e) {
      debugPrint('Error marking medication as taken: $e');
    }
  }

  // ── Caregiver: fetch patients + their doses ────────────────────

  Future<void> _fetchPatients(String token) async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.care}patients/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        myPatients = List<Map<String, dynamic>>.from(data);
        for (final rel in myPatients) {
          final patient = rel['patient_detail'];
          if (patient != null) {
            final patientId = patient['id'] as int;
            await _fetchPatientDoses(token, patientId);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _fetchPatientDoses(String token, int patientId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.care}patient/$patientId/doses/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        patientDoses[patientId] = List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('Error fetching doses for patient $patientId: $e');
    }
  }

  // ── Quick actions ───────────────────────────────

  Future<void> _handleQuickAction(String label) async {
    if (label == "Add Medication") {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
      );
      if (result == true && mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (auth.isCaregiver) {
          await _fetchPatients(auth.accessToken!);
        } else if (auth.accessToken != null) {
          await _fetchMedications(auth.accessToken!);
        }
      }
    } else if (label == "Log Symptom") {
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSymptomEntryScreen()));
    } else if (label == "Add Entry") {
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddHealthEntryScreen()));
    } else if (label == "Emergency") {
      await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()));
    }
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MedicationScreen()));
    } else if (index == 2) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SymptomTrackerScreen()));
    } else if (index == 3) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HealthJournalScreen()));
    }
  }

  String _displayTime(String? time) {
    if (time == null || time.trim().isEmpty) return "No time set";
    return time;
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.userName ?? 'User';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Hello, $userName',
          style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.blue),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: auth.isCaregiver
                  ? _buildCaregiverDashboard()
                  : _buildPatientDashboard(),
            ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medication), label: 'Medications'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Journal'),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CAREGIVER DASHBOARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildCaregiverDashboard() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _roleBadge('Caregiver', Colors.blue),
          const SizedBox(height: 20),
          _caregiverSummaryRow(),
          const SizedBox(height: 24),
          _invitePatientCard(),
          const SizedBox(height: 24),
          const Text('Your Patients',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          myPatients.isEmpty
              ? _infoCard(
                  icon: Icons.people_outline,
                  title: 'No patients linked yet',
                  subtitle:
                      'Tap "Invite Patient" above to generate an invite code.',
                )
              : Column(
                  children: myPatients.map((rel) {
                    final patient = rel['patient_detail'];
                    if (patient == null) return const SizedBox();
                    final patientId = patient['id'] as int;
                    final doses = patientDoses[patientId] ?? [];
                    return _patientCard(patient, doses);
                  }).toList(),
                ),
          const SizedBox(height: 24),
          const Text('Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _quickActionButton(Icons.add_circle, 'Add Medication'),
              _quickActionButton(Icons.call, 'Emergency'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 14, color: color),
          const SizedBox(width: 4),
          Text(role,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _caregiverSummaryRow() {
    int total = myPatients.length;
    int missedCount = 0;
    for (final doses in patientDoses.values) {
      missedCount += doses.where((d) => d['status'] == 'missed').length;
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          child: _summaryTile(
            label: 'Patients',
            value: '$total',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            label: 'Missed Doses',
            value: '$missedCount',
            icon: Icons.warning_amber_rounded,
            color: missedCount > 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _invitePatientCard() {
    return GestureDetector(
      onTap: _generateInviteCode,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_add_alt_1, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite a Patient',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('Generate an invite code to link with a patient',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _generateInviteCode() async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.care}invite/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final code = data['invite_code'];
        _showInviteCodeDialog(code);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate invite code.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error. Please try again.')),
        );
      }
    }
  }

  void _showInviteCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Invite Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Share this code with your patient. They enter it in the app to link with you.'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(
      Map<String, dynamic> patient, List<Map<String, dynamic>> doses) {
    final name = patient['name'] ?? 'Patient';
    final takenCount = doses.where((d) => d['status'] == 'taken').length;
    final missedCount =
        doses.where((d) => d['status'] == 'missed').length;
    final pendingCount =
        doses.where((d) => d['status'] == 'pending').length;
    final total = doses.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        total == 0
                            ? 'No doses scheduled today'
                            : '$takenCount of $total doses taken today',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (missedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('$missedCount missed',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
            if (total > 0) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? takenCount / total : 0,
                  minHeight: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _doseChip('$takenCount taken', Colors.green),
                  const SizedBox(width: 6),
                  if (pendingCount > 0)
                    _doseChip('$pendingCount pending', Colors.orange),
                  const SizedBox(width: 6),
                  if (missedCount > 0)
                    _doseChip('$missedCount missed', Colors.red),
                ],
              ),
            ],
            if (doses.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              ...doses.map((dose) => _doseRow(dose)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _doseChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Widget _doseRow(Map<String, dynamic> dose) {
    final status = dose['status'] as String;
    final name = dose['medication_name'] ?? 'Medication';
    final scheduledTime = dose['scheduled_time'] != null
        ? DateTime.tryParse(dose['scheduled_time'])
        : null;
    final timeStr = scheduledTime != null
        ? '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}'
        : 'No time';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'taken':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'missed':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(name, style: const TextStyle(fontSize: 13))),
          Text(timeStr,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PATIENT DASHBOARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildPatientDashboard() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _roleBadge('Patient', Colors.green),
              TextButton.icon(
                onPressed: _showLinkWithCaregiverDialog,
                icon: const Icon(Icons.link, size: 16),
                label: const Text('Link with Caregiver',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Today's Medications",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          todaysMedications.isEmpty
              ? _infoCard(
                  icon: Icons.medication,
                  title: 'No medications today',
                  subtitle:
                      'Your medications will appear here once added.',
                )
              : Column(
                  children: todaysMedications
                      .map((med) => _medicationCard(
                            med['id'],
                            med['name'] ?? 'Unnamed',
                            _displayTime(med['time']),
                            med['taken'] ?? false,
                          ))
                      .toList(),
                ),
          const SizedBox(height: 24),
          const Text('Upcoming Reminders',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          upcomingReminders.isEmpty
              ? _infoCard(
                  icon: Icons.notifications_off,
                  title: 'No reminders yet',
                  subtitle: 'Reminders will show here when enabled.',
                )
              : SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: upcomingReminders
                        .map((med) => _reminderCard(
                            med['name'] ?? 'Unnamed',
                            _displayTime(med['time'])))
                        .toList(),
                  ),
                ),
          const SizedBox(height: 24),
          const Text('Quick Actions',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _quickActionButton(Icons.add_circle, 'Add Medication'),
              _quickActionButton(Icons.fact_check, 'Log Symptom'),
              _quickActionButton(Icons.book, 'Add Entry'),
              _quickActionButton(Icons.call, 'Emergency'),
            ],
          ),
        ],
      ),
    );
  }

  void _showLinkWithCaregiverDialog() {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Link with Caregiver'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Ask your caregiver for their invite code and enter it below.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Invite Code',
                hintText: 'e.g. ABC123',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim().toUpperCase();
              Navigator.pop(context);
              await _acceptInvite(code);
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvite(String code) async {
    final token =
        Provider.of<AuthProvider>(context, listen: false).accessToken;
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.care}accept-invite/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'invite_code': code}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Linked with ${data['caregiver']} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final body = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  body['invite_code']?[0] ?? 'Invalid code. Try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Network error. Please try again.')),
        );
      }
    }
  }

  // ── Shared widgets ─────────────────────────────────────────────

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title:
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _medicationCard(int id, String name, String time, bool taken) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: Text(name),
        subtitle: Text(time),
        trailing: ElevatedButton(
          onPressed: taken ? null : () => _markMedicationAsTaken(id),
          style: ElevatedButton.styleFrom(
            backgroundColor: taken ? Colors.grey[300] : Colors.blue,
          ),
          child: Text(
            taken ? 'Taken ✓' : 'Mark Taken',
            style: TextStyle(
                color: taken ? Colors.grey[600] : Colors.white,
                fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _reminderCard(String name, String time) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_active, color: Colors.blue),
          const SizedBox(height: 8),
          Text(name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(time, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label) {
    final btnWidth = (MediaQuery.of(context).size.width - 48) / 2;
    return SizedBox(
      width: btnWidth,
      child: InkWell(
        onTap: () => _handleQuickAction(label),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blue.shade50,
              child: Icon(icon, color: Colors.blue),
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}