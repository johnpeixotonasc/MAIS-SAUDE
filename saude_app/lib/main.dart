import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '+ SAÚDE',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18.0),
          bodyMedium: TextStyle(fontSize: 16.0),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData) {
            return const HomeScreen(); // Tela após login
          }
          return const LoginScreen(); // Tela de login
        },
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tela de Login Simples', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Simular login para teste
                try {
                  await FirebaseAuth.instance.signInWithEmailAndPassword(
                    email: 'teste@saude.com',
                    password: '123456',
                  );
                } catch (e) {
                  // Se a conta não existe, cria uma
                  try {
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: 'teste@saude.com',
                      password: '123456',
                    );
                    await FirebaseAuth.instance.currentUser?.updateDisplayName('Usuário Teste');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Conta criada e logado!')), 
                    );
                  } catch (e2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao criar/logar: $e2')), 
                    );
                  }
                }
              },
              child: const Text('Entrar como Teste', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bem-vindo!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Olá, ${user?.displayName ?? 'Usuário'}!', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            const Text('Login realizado com sucesso!', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
