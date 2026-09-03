import 'package:my_todo_list_app/api/api_client.dart';
import 'package:my_todo_list_app/model/server/diary.dart';
import 'package:my_todo_list_app/model/server/diary_image.dart';
import 'package:my_todo_list_app/model/server/schedule.dart';
import 'package:my_todo_list_app/model/server/schedule_type.dart';
import 'package:my_todo_list_app/model/server/user.dart';

class RestApiService {
  RestApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<User> login({required String email, required String password}) async {
    final json = await _apiClient.post('/users/login', {
      'userEmail': email,
      'userPassword': password,
    });
    return User.fromJson(json);
  }

  Future<String> findAccount({
    required String name,
    required String phone,
  }) async {
    final json = await _apiClient.post('/users/find-account', {
      'userName': name,
      'userPhone': phone,
    });
    return json['userEmail'] as String;
  }

  Future<bool> isEmailAvailable(String email) async {
    final json = await _apiClient.getMap(
      '/users/check-email',
      queryParameters: {'email': email},
    );
    return json['available'] == true;
  }

  Future<bool> isPhoneAvailable(String phone, {int? excludeUserId}) async {
    final json = await _apiClient.getMap(
      '/users/check-phone',
      queryParameters: {
        'phone': phone,
        if (excludeUserId != null) 'excludeUserId': excludeUserId,
      },
    );
    return json['available'] == true;
  }

  Future<User> createUser(User user) async {
    final json = await _apiClient.post('/users', user.toJson());
    return User.fromJson(json);
  }

  Future<User> getUser(int userId) async {
    final json = await _apiClient.getMap('/users/$userId');
    return User.fromJson(json);
  }

  Future<User> updateUser(int userId, User user) async {
    final json = await _apiClient.patch('/users/$userId', user.toJson());
    return User.fromJson(json);
  }

  Future<User> updateUserFields(int userId, Map<String, dynamic> fields) async {
    final json = await _apiClient.patch('/users/$userId', fields);
    return User.fromJson(json);
  }

  Future<User> updateUserPassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final json = await _apiClient.patch('/users/$userId/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return User.fromJson(json);
  }

  Future<List<ScheduleType>> getScheduleTypes() async {
    final json = await _apiClient.getList('/schedule-types');
    return json
        .map((item) => ScheduleType.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ScheduleType> createScheduleType(ScheduleType scheduleType) async {
    final json = await _apiClient.post(
      '/schedule-types',
      scheduleType.toJson(),
    );
    return ScheduleType.fromJson(json);
  }

  Future<List<Schedule>> getSchedules({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    final json = await _apiClient.getList(
      '/schedules',
      queryParameters: {
        'userId': userId,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return json
        .map((item) => Schedule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Schedule>> getSchedulesByDate({
    required int userId,
    required String date,
  }) {
    return getSchedules(userId: userId, startDate: date, endDate: date);
  }

  Future<Schedule> createSchedule(Schedule schedule) async {
    final json = await _apiClient.post('/schedules', schedule.toJson());
    return Schedule.fromJson(json);
  }

  Future<Schedule> updateSchedule(int scheduleId, Schedule schedule) async {
    final json = await _apiClient.patch(
      '/schedules/$scheduleId',
      schedule.toJson(),
    );
    return Schedule.fromJson(json);
  }

  Future<Schedule> updateScheduleFields(
    int scheduleId,
    Map<String, dynamic> fields,
  ) async {
    final json = await _apiClient.patch('/schedules/$scheduleId', fields);
    return Schedule.fromJson(json);
  }

  Future<void> deleteSchedule(int scheduleId) {
    return _apiClient.delete('/schedules/$scheduleId');
  }

  Future<List<ServerDiary>> getDiaries({
    required int userId,
    String? startDate,
    String? endDate,
  }) async {
    final json = await _apiClient.getList(
      '/diaries',
      queryParameters: {
        'userId': userId,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
    );
    return json
        .map((item) => ServerDiary.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ServerDiary?> getDiaryByDate({
    required int userId,
    required String date,
  }) async {
    final json = await _apiClient.getNullableMap(
      '/diaries/by-date',
      queryParameters: {'userId': userId, 'date': date},
    );
    return json == null ? null : ServerDiary.fromJson(json);
  }

  Future<ServerDiary> createDiary(ServerDiary diary) async {
    final json = await _apiClient.post('/diaries', diary.toJson());
    return ServerDiary.fromJson(json);
  }

  Future<ServerDiary> updateDiary(int diaryId, ServerDiary diary) async {
    final json = await _apiClient.patch('/diaries/$diaryId', diary.toJson());
    return ServerDiary.fromJson(json);
  }

  Future<void> deleteDiary(int diaryId) {
    return _apiClient.delete('/diaries/$diaryId');
  }

  Future<List<DiaryImage>> getDiaryImages(int diaryId) async {
    final json = await _apiClient.getList('/diaries/$diaryId/images');
    return json
        .map((item) => DiaryImage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DiaryImage> createDiaryImage(DiaryImage diaryImage) async {
    final json = await _apiClient.post(
      '/diaries/${diaryImage.diaryId}/images',
      diaryImage.toJson(),
    );
    return DiaryImage.fromJson(json);
  }

  Future<void> deleteDiaryImage(int diaryId, int diaryImageId) {
    return _apiClient.delete('/diaries/$diaryId/images/$diaryImageId');
  }
}
