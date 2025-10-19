import 'package:pdf_viewer/feature/auth/domain/entity/auth_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> signup(String email, String password);
}
