import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationDetailsScreen extends StatefulWidget {
  final String medicationId;
  final Map<String, dynamic> medication;

  const MedicationDetailsScreen({
    Key? key,
    required this.medicationId,
    required this.medication,
  }) : super(key: key);

  @override
  State<MedicationDetailsScreen> createState() => _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final medication = widget.medication;
    final String name = medication['name'] ?? 'Medicamento';
    final String type = medication['type'] ?? 'Comprimido';
    final String dosage = medication['dosage'] ?? '';
    final int frequency = medication['frequency'] ?? 1;
    final List<dynamic> times = medication['times'] ?? [];
    final String doctor = medication['doctor'] ?? '';
    final String observations = medication['observations'] ?? '';
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, size: 24),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AddMedicationScreen(
                    medicationId: widget.medicationId,
                    existingMedication: medication,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho com informações principais
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getMedicationIcon(type),
                            size: 32,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '$type - $dosage',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Frequência',
                            '${frequency}x ao dia',
                            Icons.repeat,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Próxima Dose',
                            _getNextDoseTime(times),
                            Icons.schedule,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Horários de hoje
              _buildTodaySchedule(times),

              // Informações detalhadas
              _buildDetailedInfo(doctor, observations),

              // Histórico de doses
              _buildDoseHistory(),

              // Ações rápidas
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMedicationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'líquido':
      case 'xarope':
        return Icons.medication_liquid;
      case 'injeção':
        return Icons.vaccines;
      case 'pomada':
      case 'creme':
        return Icons.healing;
      case 'gotas':
        return Icons.water_drop;
      case 'spray':
        return Icons.air;
      default:
        return Icons.medication;
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getNextDoseTime(List<dynamic> times) {
    if (times.isEmpty) return 'Não definido';
    
    final now = TimeOfDay.now();
    final currentMinutes = now.hour * 60 + now.minute;
    
    for (String timeStr in times) {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeMinutes = hour * 60 + minute;
      
      if (timeMinutes > currentMinutes) {
        return timeStr;
      }
    }
    
    // Se não há mais doses hoje, retorna a primeira de amanhã
    return '${times.first} (amanhã)';
  }

  Widget _buildTodaySchedule(List<dynamic> times) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.today,
                size: 24,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              const Text(
                'Horários de Hoje',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (times.isEmpty)
            const Text(
              'Nenhum horário definido',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            )
          else
            ...times.map((timeStr) => _buildTimeSlot(timeStr.toString())).toList(),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String timeStr) {
    final now = TimeOfDay.now();
    final parts = timeStr.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final timeOfDay = TimeOfDay(hour: hour, minute: minute);
    
    final currentMinutes = now.hour * 60 + now.minute;
    final slotMinutes = hour * 60 + minute;
    final isPast = slotMinutes < currentMinutes;
    final isCurrent = (slotMinutes - currentMinutes).abs() <= 30;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.green.shade50
            : isPast
                ? Colors.grey.shade50
                : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? Colors.green.shade300
              : isPast
                  ? Colors.grey.shade300
                  : Colors.blue.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? Colors.green.shade700
                  : isPast
                      ? Colors.grey.shade400
                      : Colors.blue.shade700,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPast ? Icons.check : Icons.schedule,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeOfDay.format(context),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPast ? Colors.grey.shade600 : Colors.black,
                  ),
                ),
                Text(
                  isPast
                      ? 'Dose tomada'
                      : isCurrent
                          ? 'Hora de tomar!'
                          : 'Próxima dose',
                  style: TextStyle(
                    fontSize: 14,
                    color: isCurrent
                        ? Colors.green.shade700
                        : isPast
                            ? Colors.grey.shade500
                            : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          if (!isPast)
            ElevatedButton(
              onPressed: () => _markAsTaken(timeStr),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
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

  Widget _buildDetailedInfo(String doctor, String observations) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 24,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              const Text(
                'Informações Detalhadas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (doctor.isNotEmpty) ...[
            _buildInfoRow('Médico Responsável', doctor, Icons.person),
            const SizedBox(height: 12),
          ],
          if (observations.isNotEmpty) ...[
            _buildInfoRow('Observações', observations, Icons.note),
          ],
          if (doctor.isEmpty && observations.isEmpty)
            const Text(
              'Nenhuma informação adicional',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.green.shade700),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoseHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                size: 24,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              const Text(
                'Histórico Recente',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('dose_history')
                .where('medicationId', isEqualTo: widget.medicationId)
                .where('userId', isEqualTo: user?.uid)
      
(Content truncated due to size limit. Use page ranges or line ranges to read remaining content)