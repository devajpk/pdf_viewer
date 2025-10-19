import 'package:pdf_viewer/feature/auth/domain/entity/auth_entity.dart';

class UserModel extends UserEntity {
  UserModel({required String id, required String email}) : super(id: id, email: email);

  factory UserModel.fromFirebaseUser(user) {
    return UserModel(id: user.uid, email: user.email ?? '');
  }
}
