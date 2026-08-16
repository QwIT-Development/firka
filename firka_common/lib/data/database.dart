import 'package:firka_common/data/models/app_settings_model.dart';
import 'package:firka_common/data/models/class_average_cache_model.dart';
import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/homework_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/message_cache_model.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/models/teacher_model.dart';
import 'package:firka_common/data/models/test_cache_model.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:firka_common/data/models/user_theme_model.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

late Isar isarInit;

Future<Isar> initDB() async {
  final dir = await getApplicationDocumentsDirectory();

  isarInit = await Isar.open(
    [
      TokenModelSchema,
      TeacherModelSchema,
      ClassAverageCacheModelSchema,
      ClassGroupCacheModelSchema,
      GradeCacheModelSchema,
      LessonCacheModelSchema,
      MessageCacheModelSchema,
      OmissionCacheModelSchema,
      TestCacheModelSchema,
      HomeworkCacheModelSchema,
      AppSettingsModelSchema,
      SubjectCacheModelSchema,
      StudentCacheModelSchema,
      UserThemeModelSchema,
    ],
    inspector: true,
    directory: dir.path,
  );

  return isarInit;
}
