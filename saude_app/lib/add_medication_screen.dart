import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMedicationScreen extends StatefulWidget {
  final String? medicationId;
  final Map<String, dynamic>? existingMedication;
  
  const AddMedicationScreen({
    Key? key,
    this.medicationId,
    this.existingMedication,
  }) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? user = FirebaseAuth.instance.currentUser;
  
  // Controladores dos campos
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _doctorController = TextEditingController();
  final _observationsController = TextEditingController();
  
  // Variáveis de estado
  String _selectedType = 'Comprimido';
  int _frequency = 1;
  List<TimeOfDay> _selectedTimes = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  
  // Opções de tipos de medicamento
  final List<String> _medicationTypes = [
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
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.existingMedication != null) {
      final medication = widget.existingMedication!;
      _nameController.text = medication['name'] ?? '';
      _dosageController.text = medication['dosage'] ?? '';
      _doctorController.text = medication['doctor'] ?? '';
      _observationsController.text = medication['observations'] ?? '';
      _selectedType = medication['type'] ?? 'Comprimido';
      _frequency = medication['frequency'] ?? 1;
      
      // Converter horários salvos para TimeOfDay
      if (medication['times'] != null) {
        _selectedTimes = (medication['times'] as List<dynamic>)
            .map((time) => _parseTimeString(time.toString()))
            .toList();
      }
      
      // Converter datas
      if (medication['startDate'] != null) {
        _startDate = (medication['startDate'] as Timestamp).toDate();
      }
      if (medication['endDate'] != null) {
        _endDate = (medication['endDate'] as Timestamp).toDate();
      }
    } else {
      // Configurar horários padrão baseado na frequência
      _updateDefaultTimes();
    }
  }

  TimeOfDay _parseTimeString(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  void _updateDefaultTimes() {
    _selectedTimes.clear();
    switch (_frequency) {
      case 1:
        _selectedTimes.add(const TimeOfDay(hour: 8, minute: 0));
        break;
      case 2:
        _selectedTimes.addAll([
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ]);
        break;
      case 3:
        _selectedTimes.addAll([
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ]);
        break;
      case 4:
        _selectedTimes.addAll([
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 12, minute: 0),
          const TimeOfDay(hour: 16, minute: 0),
          const TimeOfDay(hour: 20, minute: 0),
        ]);
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _doctorController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicationId != null;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Medicamento' : 'Adicionar Medicamento',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nome do medicamento
                _buildSectionTitle('Nome do Medicamento'),
                _buildTextField(
                  controller: _nameController,
                  label: 'Nome do medicamento',
                  hint: 'Ex: Paracetamol, Losartana...',
                  icon: Icons.medication,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite o nome do medicamento';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Tipo e Dosagem
                _buildSectionTitle('Tipo e Dosagem'),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildDropdownField(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildTextField(
                        controller: _dosageController,
                        label: 'Dosagem',
                        hint: 'Ex: 500mg, 10ml...',
                        icon: Icons.straighten,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Digite a dosagem';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Frequência
                _buildSectionTitle('Frequência de Uso'),
                _buildFrequencySelector(),
                
                const SizedBox(height: 24),
                
                // Horários
                _buildSectionTitle('Horários de Tomada'),
                _buildTimesSection(),
                
                const SizedBox(height: 24),
                
                // Período de tratamento
                _buildSectionTitle('Período de Tratamento'),
                _buildDateSection(),
                
                const SizedBox(height: 24),
                
                // Médico responsável
                _buildSectionTitle('Médico Responsável (Opcional)'),
                _buildTextField(
                  controller: _doctorController,
                  label: 'Nome do médico',
                  hint: 'Dr. João Silva...',
                  icon: Icons.person,
                ),
                
                const SizedBox(height: 24),
                
                // Observações
                _buildSectionTitle('Observações (Opcional)'),
                _buildTextField(
                  controller: _observationsController,
                  label: 'Observações',
                  hint: 'Tomar com alimentos, efeitos colaterais...',
                  icon: Icons.note,
                  maxLines: 3,
                ),
                
                const SizedBox(height: 32),
                
                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveMedication,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Atualizar' : 'Salvar',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 16),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 16),
        prefixIcon: Icon(icon, size: 24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedType,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          labelStyle: TextStyle(fontSize: 16),
          prefixIcon: Icon(Icons.category, size: 24),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: const TextStyle(fontSize: 18, color: Colors.black),
        items: _medicationTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedType = value!;
          });
        },
      ),
    );
  }

  Widget _buildFrequencySelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quantas vezes por dia?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [1, 2, 3, 4].map((freq) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _frequency = freq;
                        _updateDefaultTimes();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _frequency == freq
                            ? Colors.green.shade700
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _frequency == freq
                              ? Colors.green.shade700
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        '${freq}x',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _frequency == freq
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Horários definidos:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              TextButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Adicionar'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_selectedTimes.isEmpty)
            const Text(
   
(Content truncated due to size limit. Use page ranges or line ranges to read remaining content)