import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'message_cache_model.g.dart';

@collection
class MessageCacheModel extends GenericCacheModel<MessageItem> {
  late String author;
  late String title;
  late String contentHtml;

  final student = IsarLink<StudentCacheModel>();

  @override
  void apply(CacheContext<MessageItem> ctx) {
    this
      ..author = ctx.data.author
      ..title = ctx.data.title
      ..createdAt = ctx.data.date
      ..contentHtml = ctx.data.contentHTML
      ..student.value = ctx.cacheManager.findStudent();
  }
}
