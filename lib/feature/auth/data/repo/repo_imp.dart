import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf_viewer/feature/auth/data/model/user_model.dart';
import 'package:pdf_viewer/feature/auth/domain/entity/auth_entity.dart';
import 'package:pdf_viewer/feature/auth/domain/repo/repo.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;

  AuthRepositoryImpl(this.firebaseAuth);

  @override
  Future<UserEntity> login(String email, String password) async {
    final result = await firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return UserModel.fromFirebaseUser(result.user);
  }

  @override
  Future<UserEntity> signup(String email, String password) async {
    final result = await firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    return UserModel.fromFirebaseUser(result.user);
  }
}
