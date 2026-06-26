import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../services/notification_service.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String dosage = '';
  TimeOfDay? selectedTime;
  String notes = '';
  String frequency = 'Daily';
  int? selectedDayOfWeek; // 0=Monday ... 6=Sunday, only used when frequency == Weekly
  bool reminderEnabled = true;
  bool isSaving = false;

  // For caregivers — the patient they are adding this med for
  List<Map<String, dynamic>> myPatients = [];
  int? selectedPatientId;
  String? selectedPatientName;
  bool loadingPatients = false;

  static const List<String> _dayLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isCaregiver) {
      _fetchMyPatients(auth.accessToken!);
    }
  }

  Future<void> _fetchMyPatients(String token) async {
    setState(() => loadingPatients = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.care}patients/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        final List data = jsonDecode(response.body);
        setState(() {
          myPatients = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching patients: $e');
    } finally {
      if (mounted) setState(() => loadingPatients = false);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) setState(() => selectedTime = time);
  }

  String getFormattedTime() {
    if (selectedTime == null) return '';
    final hour = selectedTime!.hour.toString().padLeft(2, '0');
    final minute = selectedTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveMedication() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.accessToken;
    if (token == null) return;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Caregiver must select a patient
    if (auth.isCaregiver && selectedPatientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient for this medication.')),
      );
      return;
    }

    if (selectedTime == null && reminderEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time for the reminder.')),
      );
      return;
    }

    // Weekly medications need a day of week
    if (frequency == 'Weekly' && selectedDayOfWeek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a day of the week.')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Build request body
      final body = {
        'name': name,
        'dosage': dosage,
        'time': getFormattedTime(),
        'frequency': frequency,
        'notes': notes,
        'reminder': reminderEnabled,
      };

      if (frequency == 'Weekly' && selectedDayOfWeek != null) {
        body['day_of_week'] = selectedDayOfWeek.toString();
      }

      // If caregiver, add patient id so backend assigns it to the patient
      if (auth.isCaregiver && selectedPatientId != null) {
        body['patient_id'] = selectedPatientId.toString();
      }

      final response = await http.post(
        Uri.parse(ApiConfig.medications),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final int medId = responseData['id'];

        if (reminderEnabled && selectedTime != null) {
          if (auth.isPatient) {
            // Patient gets a reminder for themselves
            if (frequency == 'Weekly' && selectedDayOfWeek != null) {
              await NotificationService().scheduleWeeklyNotification(
                id: medId,
                title: '💊 Time for $name',
                body: 'Dosage: $dosage — tap to confirm',
                dayOfWeek: selectedDayOfWeek!,
                hour: selectedTime!.hour,
                minute: selectedTime!.minute,
              );
            } else {
              await NotificationService().scheduleDailyNotification(
                id: medId,
                title: '💊 Time for $name',
                body: 'Dosage: $dosage — tap to confirm',
                hour: selectedTime!.hour,
                minute: selectedTime!.minute,
              );
            }
          } else if (auth.isCaregiver && selectedPatientName != null) {
            // Caregiver gets a missed dose alert if patient doesn't confirm
            await NotificationService().scheduleMissedDoseAlert(
              id: medId,
              patientName: selectedPatientName!,
              medicationName: name,
              hour: selectedTime!.hour,
              minute: selectedTime!.minute,
              graceMinutes: 3,
            );
          }
        }

        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted) {
          final errorBody = jsonDecode(response.body);
          final errorMsg = errorBody is Map
              ? errorBody.values.first.toString()
              : 'Failed to add medication.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add Medication',
            style: TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Caregiver: pick which patient ──────────────────────────
                if (auth.isCaregiver) ...[
                  const Text('Adding medication for',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  loadingPatients
                      ? const Center(child: CircularProgressIndicator())
                      : myPatients.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      color: Colors.orange, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'No patients linked yet. Invite a patient from the home screen first.',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.orange),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder()),
                              hint: const Text('Select patient'),
                              initialValue: selectedPatientId,
                              items: myPatients.map((rel) {
                                final patient = rel['patient_detail'];
                                final id = patient['id'] as int;
                                final patientName =
                                    patient['name'] as String? ?? 'Patient';
                                return DropdownMenuItem<int>(
                                  value: id,
                                  child: Text(patientName),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  selectedPatientId = val;
                                  final rel = myPatients.firstWhere(
                                    (r) => r['patient_detail']['id'] == val,
                                  );
                                  selectedPatientName =
                                      rel['patient_detail']['name'];
                                });
                              },
                              validator: (val) => val == null
                                  ? 'Please select a patient'
                                  : null,
                            ),
                  const SizedBox(height: 16),
                ],

                // ── Medication name ────────────────────────────────────────
                const Text('Medication Name',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  onSaved: (val) => name = val ?? '',
                  validator: (val) => val == null || val.isEmpty
                      ? 'Please enter medication name'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Dosage ─────────────────────────────────────────────────
                const Text('Dosage (e.g. 500mg)',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  onSaved: (val) => dosage = val ?? '',
                ),
                const SizedBox(height: 16),

                // ── Time ───────────────────────────────────────────────────
                const Text('Time',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          selectedTime != null
                              ? selectedTime!.format(context)
                              : 'Select Time',
                          style: TextStyle(
                            color: selectedTime != null
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Frequency ──────────────────────────────────────────────
                const Text('Frequency',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  initialValue: frequency,
                  items: ['Daily', 'Weekly', 'Custom']
                      .map((f) =>
                          DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (val) => setState(() {
                    frequency = val!;
                    // Reset day selection if switching away from Weekly
                    if (frequency != 'Weekly') selectedDayOfWeek = null;
                  }),
                ),

                // ── Day of week (only for Weekly) ───────────────────────────
                if (frequency == 'Weekly') ...[
                  const SizedBox(height: 16),
                  const Text('Day of the week',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    hint: const Text('Select day'),
                    initialValue: selectedDayOfWeek,
                    items: List.generate(7, (i) => i).map((dayIndex) {
                      return DropdownMenuItem<int>(
                        value: dayIndex,
                        child: Text(_dayLabels[dayIndex]),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedDayOfWeek = val),
                    validator: (val) => frequency == 'Weekly' && val == null
                        ? 'Please select a day'
                        : null,
                  ),
                ],

                // ── Custom frequency note ───────────────────────────────────
                if (frequency == 'Custom') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Custom frequency currently reminds you daily. '
                            'Full custom scheduling is coming soon.',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // ── Notes ──────────────────────────────────────────────────
                const Text('Notes',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  maxLines: 2,
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  onSaved: (val) => notes = val ?? '',
                ),
                const SizedBox(height: 16),

                // ── Reminder toggle ────────────────────────────────────────
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Reminder',
                      style: TextStyle(fontSize: 16)),
                  subtitle: Text(
                    auth.isCaregiver
                        ? 'You will be alerted if the patient misses this dose'
                        : 'You will get a notification at the selected time',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: reminderEnabled,
                  onChanged: (val) =>
                      setState(() => reminderEnabled = val),
                ),
                const SizedBox(height: 30),

                // ── Save button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _saveMedication,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Medication',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}