import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Importar telas de medicamentos
// import 'add_medication_screen.dart';
// import 'medication_details_screen.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({Key? key}) : super(key: key);

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Usuário não logado.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Medicamentos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('medications')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child:
                    Text('Erro ao carregar medicamentos: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum medicamento cadastrado.',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Clique no ' + ' para adicionar um novo.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var medication = snapshot.data!.docs[index];
              var medicationData = medication.data() as Map<String, dynamic>;

              IconData iconData;
              Color iconColor;
              switch (medicationData['type']) {
                case 'Comprimido':
                  iconData = Icons.medical_information;
                  iconColor = Colors.green.shade700;
                  break;
                case 'Cápsula':
                  iconData = Icons.local_pharmacy;
                  iconColor = Colors.green.shade700;
                  break;
                case 'Líquido':
                  iconData = Icons.water_drop;
                  iconColor = Colors.blue.shade700;
                  break;
                case 'Xarope':
                  iconData = Icons.medication_liquid;
                  iconColor = Colors.blue.shade700;
                  break;
                case 'Injeção':
                  iconData = Icons.vaccines;
                  iconColor = Colors.red.shade700;
                  break;
                case 'Pomada':
                  iconData = Icons.healing;
                  iconColor = Colors.orange.shade700;
                  break;
                case 'Creme':
                  iconData = Icons.sanitizer;
                  iconColor = Colors.orange.shade700;
                  break;
                case 'Gotas':
                  iconData = Icons.opacity;
                  iconColor = Colors.cyan.shade700;
                  break;
                case 'Spray':
                  iconData = Icons.spray_can;
                  iconColor = Colors.purple.shade700;
                  break;
                case 'Adesivo':
                  iconData = Icons.sticky_note_2;
                  iconColor = Colors.brown.shade700;
                  break;
                default:
                  iconData = Icons.medication;
                  iconColor = Colors.grey.shade700;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    // Navegar para detalhes do medicamento
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => MedicationDetailsScreen(medicationId: medication.id)));
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(iconData, size: 32, color: iconColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                medicationData['name'] ??
                                    'Medicamento sem nome',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  // Navegar para tela de edição
                                  // Navigator.push(context, MaterialPageRoute(builder: (context) => AddMedicationScreen(medicationId: medication.id)));
                                } else if (value == 'delete') {
                                  _confirmDelete(medication.id);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Editar',
                                      style: TextStyle(fontSize: 16)),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Excluir',
                                      style: TextStyle(fontSize: 16),
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Dosagem: ${medicationData['dosage'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tipo: ${medicationData['type'] ?? 'N/A'}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Frequência: ${medicationData['frequency'] ?? 'N/A'} ao dia',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Horários: ${(medicationData['times'] as List<dynamic>?)?.join(', ') ?? 'N/A'}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navegar para tela de adicionar medicamento
          // Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMedicationScreen()));
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  Future<void> _confirmDelete(String medicationId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tem certeza que deseja excluir este medicamento?',
                    style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Excluir',
                  style: TextStyle(fontSize: 18, color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('medications')
                    .doc(medicationId)
                    .delete();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Medicamento excluído com sucesso!'),
                      backgroundColor: Colors.green),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
