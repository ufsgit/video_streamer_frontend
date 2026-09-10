import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<UserModel?> getUserProfile();
}

class UserRepositoryImpl implements UserRepository {
  final DioClient _client;

  UserRepositoryImpl({DioClient? client}) : _client = client ?? DioClient();

  @override
  Future<UserModel?> getUserProfile() async {
    try {
      final response = await _client.dio.get(ApiConstants.userProfilePath);
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map<String, dynamic> && body['success'] == true) {
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            return UserModel.fromJson(data);
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
