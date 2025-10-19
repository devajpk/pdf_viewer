import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf_viewer/feature/auth/data/repo/repo_imp.dart';
import 'package:pdf_viewer/feature/auth/domain/repo/repo.dart';
import 'package:pdf_viewer/feature/auth/presentation/view/login_page.dart';
import 'package:pdf_viewer/feature/pdf/data/repo/repo.dart';
import 'package:pdf_viewer/feature/pdf/domain/repo/pdf_repo_imp.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view_model/pdf_bloc.dart';
import 'firebase_options.dart';
import 'feature/auth/presentation/view_model/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) => AuthRepositoryImpl(FirebaseAuth.instance),
        ),
        RepositoryProvider<PdfRepository>(
          create: (_) => PdfRepositoryImpl(FirebaseStorage.instance), // your PDF repo
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(context.read<AuthRepository>()),
          ),
          BlocProvider<PdfBloc>(
            create: (context) => PdfBloc(context.read<PdfRepository>()),
          ),
        ],
        child: MaterialApp(
          title: 'PDF Viewer',
          debugShowCheckedModeBanner: false,
          home: Login(),
        ),
      ),
    );
  }
}
