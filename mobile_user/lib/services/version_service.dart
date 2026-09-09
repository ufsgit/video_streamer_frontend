import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../core/network/dio_client.dart';

class VersionCheckResult {
  final bool updateAvailable;
  final bool isForced;
  final String currentVersion;
  final String latestVersion;
  final String? releaseNotes;
  final String? updateUrl;
  final String? message;

  const VersionCheckResult({
    required this.updateAvailable,
    required this.isForced,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseNotes,
    this.updateUrl,
    this.message,
  });
}

class VersionService {
  final DioClient _dioClient;

  VersionService({DioClient? dioClient})
    : _dioClient = dioClient ?? DioClient();

  /// Checks the current version with the backend `app-version/check` API before login.
  /// The backend handles comparison and returns `update_required`, `update_message`, etc.
  Future<VersionCheckResult> checkVersion({
    String currentVersion = AppConstants.appVersion,
    int isAdminUpdate = 3,
  }) async {
    try {
      final params = {
        'current_version': currentVersion,
        'is_admin_update': isAdminUpdate,
      };

      Response response;
      try {
        response = await _dioClient.dio.get(
          ApiConstants.appVersionCheckPath,
          queryParameters: params,
        );
      } on DioException catch (dioErr) {
        // If GET returns 400, 404, or 405, fallback to POST
        if (dioErr.response?.statusCode == 400 ||
            dioErr.response?.statusCode == 404 ||
            dioErr.response?.statusCode == 405) {
          response = await _dioClient.dio.post(
            ApiConstants.appVersionCheckPath,
            data: params,
          );
        } else {
          rethrow;
        }
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        Map<String, dynamic> target = data;
        if (data['data'] is Map<String, dynamic>) {
          target = data['data'];
        }

        // 1. Check if backend signaled that an update is required
        bool updateRequired = false;
        if (target.containsKey('update_required')) {
          final val = target['update_required'];
          updateRequired =
              (val == 1 || val == true || val == '1' || val == 'true');
        } else if (target.containsKey('is_update_required')) {
          final val = target['is_update_required'];
          updateRequired =
              (val == 1 || val == true || val == '1' || val == 'true');
        } else if (target.containsKey('update_available')) {
          final val = target['update_available'];
          updateRequired =
              (val == 1 || val == true || val == '1' || val == 'true');
        }

        // 2. Check if update is forced (default to forced if update_required == 1)
        bool isForced = updateRequired;
        if (target.containsKey('is_forced')) {
          final val = target['is_forced'];
          isForced = (val == 1 || val == true || val == '1' || val == 'true');
        } else if (target.containsKey('force_update')) {
          final val = target['force_update'];
          isForced = (val == 1 || val == true || val == '1' || val == 'true');
        }

        // 3. Extract message sent from backend
        final apiMessage =
            target['update_message']?.toString() ??
            target['msg']?.toString() ??
            target['message']?.toString() ??
            data['update_message']?.toString() ??
            data['msg']?.toString() ??
            data['message']?.toString();

        // 4. Extract download URL
        String? updateUrl;
        final rawDownload =
            target['download_link']?.toString() ??
            target['store_url']?.toString() ??
            target['update_url']?.toString() ??
            target['download_url']?.toString();

        if (rawDownload != null &&
            rawDownload.trim().isNotEmpty &&
            rawDownload.toLowerCase() != 'not provided') {
          updateUrl = rawDownload.trim();
        }

        final serverVersionStr =
            target['latest_version']?.toString() ??
            target['version']?.toString() ??
            target['app_version']?.toString() ??
            currentVersion;

        return VersionCheckResult(
          updateAvailable: updateRequired,
          isForced: isForced,
          currentVersion: currentVersion,
          latestVersion: serverVersionStr,
          releaseNotes:
              target['release_notes']?.toString() ??
              target['notes']?.toString(),
          updateUrl: updateUrl,
          message:
              apiMessage ??
              (updateRequired ? 'Please update the app to continue.' : null),
        );
      }

      return VersionCheckResult(
        updateAvailable: false,
        isForced: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
      );
    } catch (_) {
      // In case of network error, do not block the app
      return VersionCheckResult(
        updateAvailable: false,
        isForced: false,
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        message: 'Could not verify app version.',
      );
    }
  }
}
