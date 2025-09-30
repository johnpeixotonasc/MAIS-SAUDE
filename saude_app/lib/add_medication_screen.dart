import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddMedicationScreen extends StatefulWidget {
  final String? medicationId;

  const AddMedicationScreen({Key? key, this.medicationId}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String? _selectedType;
  int _selectedFrequency = 1;
  List<TimeOfDay> _selectedTimes = [];
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (widget.medicationId != null) {
      _loadMedicationData();
    } else {
      _setInitialTimes();
    }
  }

  void _setInitialTimes() {
    _selectedTimes = _generateDefaultTimes(_selectedFrequency);
  }

  List<TimeOfDay> _generateDefaultTimes(int frequency) {
    switch (frequency) {
      case 1:
        return [const TimeOfDay(hour: 8, minute: 0)];
      case 2:
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0)
        ];
      case 3:
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0)
        ];
      case 4:
        return [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 16, minute: 0),
          const TimeOfDay(hour: 20, minute: 0)
        ];
      default:
        return [];
    }
  }

  Future<void> _loadMedicationData() async {
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('medications')
          .doc(widget.medicationId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['name'] ?? '';
        _dosageController.text = data['dosage'] ?? '';
        _doctorController.text = data['doctor'] ?? '';
        _notesController.text = data['notes'] ?? '';
        _selectedType = data['type'];
        _selectedFrequency = data['frequency'] ?? 1;
        _startDate = (data['startDate'] as Timestamp?)?.toDate();
        _endDate = (data['endDate'] as Timestamp?)?.toDate();

        final List<dynamic> timesData = data['times'] ?? [];
        _selectedTimes = timesData.map((timeStr) {
          final parts = timeStr.split(':');
          return TimeOfDay(
              hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
        _sortTimes();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar medicamento: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortTimes() {
    _selectedTimes.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null && !_selectedTimes.contains(picked)) {
      setState(() {
        _selectedTimes.add(picked);
        _sortTimes();
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _startDate!.isAfter(_endDate!)) {
            _endDate =
                _startDate; // Ajusta a data final se for anterior à inicial
          }
        } else {
          _endDate = picked;
          if (_startDate != null && _endDate!.isBefore(_startDate!)) {
            _startDate =
                _endDate; // Ajusta a data inicial se for posterior à final
          }
        }
      });
    }
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Por favor, adicione pelo menos um horário para o medicamento.')),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não logado.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final medicationData = {
        'name': _nameController.text,
        'dosage': _dosageController.text,
        'type': _selectedType,
        'doctor': _doctorController.text,
        'notes': _notesController.text,
        'frequency': _selectedFrequency,
        'times': _selectedTimes
            .map((e) =>
                '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}')
            .toList(),
        'startDate':
            _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.medicationId == null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('medications')
            .add(medicationData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Medicamento adicionado com sucesso!'),
              backgroundColor: Colors.green),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('medications')
            .doc(widget.medicationId)
            .update(medicationData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Medicamento atualizado com sucesso!'),
              backgroundColor: Colors.green),
        );
      }
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar medicamento: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medicationId == null
              ? 'Adicionar Medicamento'
              : 'Editar Medicamento',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nome do Medicamento',
                      hint: 'Ex: Dorflex, Amoxicilina',
                      icon: Icons.medication,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira o nome do medicamento.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      label: 'Tipo de Medicamento',
                      value: _selectedType,
                      items: const [
                        'Comprimido',
                        'Cápsula',
                        'Líquido',
                        'Xarope',
                        'Injeção',
                        'Pomada',
                        'Creme',
                        'Gotas',
                        'Spray',
                        'Adesivo',
                      ],
                      icon: Icons.category,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecione o tipo de medicamento.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _dosageController,
                      label: 'Dosagem',
                      hint: 'Ex: 500mg, 10ml, 1 comprimido',
                      icon: Icons.science,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira a dosagem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _doctorController,
                      label: 'Médico Responsável (Opcional)',
                      hint: 'Ex: Dr. João Silva',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _notesController,
                      label: 'Observações (Opcional)',
                      hint: 'Ex: Tomar após as refeições',
                      icon: Icons.notes,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    _buildFrequencySection(),
                    const SizedBox(height: 20),
                    _buildTimesSection(),
                    const SizedBox(height: 20),
                    _buildDateSelectionSection(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _saveMedication,
                        icon: const Icon(Icons.save, size: 28),
                        label: Text(
                          widget.medicationId == null
                              ? 'Salvar Medicamento'
                              : 'Atualizar Medicamento',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 28, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        labelStyle: TextStyle(fontSize: 18, color: Colors.green.shade700),
        hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      style: const TextStyle(fontSize: 18),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 28, color: Colors.green.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        labelStyle: TextStyle(fontSize: 18, color: Colors.green.shade700),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      items: items.map((String item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item, style: const TextStyle(fontSize: 18)),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(fontSize: 18, color: Colors.black),
      icon: Icon(Icons.arrow_drop_down, size: 32, color: Colors.green.shade700),
      isExpanded: true,
    );
  }

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequência (vezes ao dia)',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) {
            final freq = index + 1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedFrequency = freq;
                      _selectedTimes = _generateDefaultTimes(freq);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedFrequency == freq
                        ? Colors.green.shade700
                        : Colors.green.shade100,
                    foregroundColor: _selectedFrequency == freq
                        ? Colors.white
                        : Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text('$freq x'),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horários de Tomada',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _selectedTimes.map((time) {
            return Chip(
              label: Text(time.format(context),
                  style: const TextStyle(fontSize: 16, color: Colors.white)),
              backgroundColor: Colors.green.shade500,
              deleteIcon:
                  const Icon(Icons.close, size: 18, color: Colors.white),
              onDeleted: () {
                setState(() {
                  _selectedTimes.remove(time);
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _selectTime(context),
            icon: Icon(Icons.add_alarm, size: 28, color: Colors.green.shade700),
            label: Text('Adicionar Horário',
                style: TextStyle(fontSize: 18, color: Colors.green.shade700)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              side: BorderSide(color: Colors.green.shade700, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Período de Tratamento',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildDateButton(
                label: 'Data de Início',
                date: _startDate,
                onPressed: () => _selectDate(context, true),
                icon: Icons.calendar_today,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDateButton(
                label: 'Data de Fim (Opcional)',
                date: _endDate,
                onPressed: () => _selectDate(context, false),
                icon: Icons.event_busy,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28, color: Colors.green.shade700),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            date == null
                ? 'Selecionar Data'
                : '${date.day}/${date.month}/${date.year}',
            style: TextStyle(
                fontSize: 18,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        side: BorderSide(color: Colors.green.shade700, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
