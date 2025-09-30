import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationReminderService {
  static final MedicationReminderService _instance = MedicationReminderService._internal();
  factory MedicationReminderService() => _instance;
  MedicationReminderService._internal();

  final User? user = FirebaseAuth.instance.currentUser;

  // Verificar medicamentos que precisam ser tomados agora
  Future<List<Map<String, dynamic>>> checkDueMedications() async {
    if (user == null) return [];

    try {
      final now = DateTime.now();
      final currentTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      
      final snapshot = await FirebaseFirestore.instance
          .collection('medications')
          .where('userId', isEqualTo: user!.uid)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> dueMedications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final times = List<String>.from(data['times'] ?? []);
        
        for (String time in times) {
          if (_isTimeMatch(time, currentTime)) {
            // Verificar se já foi tomado hoje
            final alreadyTaken = await _checkIfAlreadyTaken(doc.id, time, now);
            if (!alreadyTaken) {
              dueMedications.add({
                'id': doc.id,
                'name': data['name'],
                'dosage': data['dosage'],
                'type': data['type'],
                'scheduledTime': time,
                'data': data,
              });
            }
          }
        }
      }

      return dueMedications;
    } catch (e) {
      print('Erro ao verificar medicamentos: $e');
      return [];
    }
  }

  // Verificar se o horário atual corresponde ao horário do medicamento (com tolerância de 5 minutos)
  bool _isTimeMatch(String scheduledTime, String currentTime) {
    final scheduledParts = scheduledTime.split(':');
    final currentParts = currentTime.split(':');
    
    final scheduledMinutes = int.parse(scheduledParts[0]) * 60 + int.parse(scheduledParts[1]);
    final currentMinutes = int.parse(currentParts[0]) * 60 + int.parse(currentParts[1]);
    
    // Tolerância de 5 minutos
    return (currentMinutes - scheduledMinutes).abs() <= 5;
  }

  // Verificar se o medicamento já foi tomado hoje no horário especificado
  Future<bool> _checkIfAlreadyTaken(String medicationId, String scheduledTime, DateTime today) async {
    try {
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await FirebaseFirestore.instance
          .collection('dose_history')
          .where('medicationId', isEqualTo: medicationId)
          .where('userId', isEqualTo: user!.uid)
          .where('scheduledTime', isEqualTo: scheduledTime)
          .where('takenAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('takenAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erro ao verificar histórico: $e');
      return false;
    }
  }

  // Marcar medicamento como tomado
  Future<bool> markMedicationAsTaken(String medicationId, String medicationName, String scheduledTime) async {
    try {
      await FirebaseFirestore.instance.collection('dose_history').add({
        'userId': user?.uid,
        'medicationId': medicationId,
        'medicationName': medicationName,
        'scheduledTime': scheduledTime,
        'takenAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erro ao marcar medicamento: $e');
      return false;
    }
  }

  // Obter estatísticas de aderência
  Future<Map<String, dynamic>> getAdherenceStats(String medicationId, {int days = 7}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      // Buscar o medicamento
      final medicationDoc = await FirebaseFirestore.instance
          .collection('medications')
          .doc(medicationId)
          .get();

      if (!medicationDoc.exists) {
        return {'error': 'Medicamento não encontrado'};
      }

      final medicationData = medicationDoc.data()!;
      final times = List<String>.from(medicationData['times'] ?? []);
      final frequency = medicationData['frequency'] ?? 1;

      // Calcular doses esperadas
      final expectedDoses = days * frequency;

      // Buscar doses tomadas
      final historySnapshot = await FirebaseFirestore.instance
          .collection('dose_history')
          .where('medicationId', isEqualTo: medicationId)
          .where('userId', isEqualTo: user!.uid)
          .where('takenAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('takenAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final takenDoses = historySnapshot.docs.length;
      final adherencePercentage = expectedDoses > 0 ? (takenDoses / expectedDoses * 100).round() : 0;

      return {
        'expectedDoses': expectedDoses,
        'takenDoses': takenDoses,
        'adherencePercentage': adherencePercentage,
        'missedDoses': expectedDoses - takenDoses,
        'days': days,
      };
    } catch (e) {
      print('Erro ao calcular estatísticas: $e');
      return {'error': 'Erro ao calcular estatísticas'};
    }
  }

  // Obter próximos medicamentos do dia
  Future<List<Map<String, dynamic>>> getUpcomingMedications() async {
    if (user == null) return [];

    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final snapshot = await FirebaseFirestore.instance
          .collection('medications')
          .where('userId', isEqualTo: user!.uid)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> upcomingMedications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final times = List<String>.from(data['times'] ?? []);
        
        for (String time in times) {
          final parts = time.split(':');
          final timeMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          
          if (timeMinutes > currentMinutes) {
            // Verificar se já foi tomado hoje
            final alreadyTaken = await _checkIfAlreadyTaken(doc.id, time, now);
            if (!alreadyTaken) {
              upcomingMedications.add({
                'id': doc.id,
                'name': data['name'],
                'dosage': data['dosage'],
                'type': data['type'],
                'scheduledTime': time,
                'timeMinutes': timeMinutes,
                'data': data,
              });
            }
          }
        }
      }

      // Ordenar por horário
      upcomingMedications.sort((a, b) => a['timeMinutes'].compareTo(b['timeMinutes']));

      return upcomingMedications.take(5).toList(); // Próximos 5
    } catch (e) {
      print('Erro ao buscar próximos medicamentos: $e');
      return [];
    }
  }

  // Obter medicamentos atrasados
  Future<List<Map<String, dynamic>>> getOverdueMedications() async {
    if (user == null) return [];

    try {
      final now = DateTime.now();
      final currentMinutes = now.hour * 60 + now.minute;

      final snapshot = await FirebaseFirestore.instance
          .collection('medications')
          .where('userId', isEqualTo: user!.uid)
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> overdueMedications = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final times = List<String>.from(data['times'] ?? []);
        
        for (String time in times) {
          final parts = time.split(':');
          final timeMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          
          // Medicamento atrasado se passou mais de 30 minutos do horário
          if (currentMinutes > timeMinutes + 30) {
            // Verificar se já foi tomado hoje
            final alreadyTaken = await _checkIfAlreadyTaken(doc.id, time, now);
            if (!alreadyTaken) {
              final minutesLate = currentMinutes - timeMinutes;
              overdueMedications.add({
                'id': doc.id,
                'name': data['name'],
                'dosage': data['dosage'],
                'type': data['type'],
                'scheduledTime': time,
                'minutesLate': minutesLate,
                'data': data,
              });
            }
          }
        }
      }

      // Ordenar por tempo de atraso (mais atrasado primeiro)
      overdueMedications.sort((a, b) => b['minutesLate'].compareTo(a['minutesLate']));

      return overdueMedications;
    } catch (e) {
      print('Erro ao buscar medicamentos atrasados: $e');
      return [];
    }
  }
}

// Widget para exibir lembretes de medicamentos
class MedicationReminderWidget extends StatefulWidget {
  const MedicationReminderWidget({Key? key}) : super(key: key);

  @override
  State<MedicationReminderWidget> createState() => _MedicationReminderWidgetState();
}

class _MedicationReminderWidgetState extends State<MedicationReminderWidget> {
  final MedicationReminderService _reminderService = MedicationReminderService();
  List<Map<String, dynamic>> dueMedications = [];
  List<Map<String, dynamic>> overdueMedications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    setState(() => isLoading = true);
    
    final due = await _reminderService.checkDueMedications();
    final overdue = await _reminderService.getOverdueMedications();
    
    setState(() {
      dueMedications = due;
      overdueMedications = overdue;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dueMedications.isEmpty && overdueMedications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Todos os medicamentos em dia!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Medicamentos atrasados
        if (overdueMedications.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Medicamentos Atrasados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...overdueMedications.map((med) => _buildMedicationCard(med, isOverdue: true)),
              ],
            ),
          ),
        ],

        // Medicamentos na hora
        if (dueMedications.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Hora de Tomar!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...dueMedications.map((med) => _buildMedicationCard(med)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication, {bool isOverdue = false}) {
    final name = medication['name'] ?? '';
    final dosage = medication['dosage'] ?? '';
    final scheduledTime = medication['scheduledTime'] ?? '';
    final minutesLate = medication['minutesLate'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOverdue ? Colors.red.shade300 : Colors.green.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isOverdue ? Colors.red.shade700 : Colors.green.shade700,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$dosage - $scheduledTime',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (isOverdue && minutesLate > 0)
                  Text(
                    'Atrasado ${_formatDelay(minutesLate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _markAsTaken(medication),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOverdue ? Colors.red.shade700 : Colors.green.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Tomei'),
          ),
        ],
      ),
    );
  }

  String _formatDelay(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h${remainingMinutes > 0 ? ' ${remainingMinutes}min' : ''}';
    }
  }

  Future<void> _markAsTaken(Map<String, dynamic> medication) async {
    final success = await _reminderService.markMedicationAsTaken(
      medication['id'],
      medication['name'],
      medication['scheduledTime'],
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medicamento marcado como tomado!'),
  
(Content truncated due to size limit. Use page ranges or line ranges to read remaining content)