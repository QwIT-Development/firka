import 'package:firka_common/data/models/generic_cache_model.dart';
import 'package:firka_common/data/models/student_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';

part 'message_cache_model.g.dart';

@collection
class MessageCacheModel extends GenericCacheModel<MessageItem> {
  String? uid;
  late String author;
  late String title;
  late String contentHtml;
  String? contentText;
  DateTime? validFrom;
  DateTime? validTo;
  DateTime? itemCreatedAt;
  String? type;

  final student = IsarLink<StudentCacheModel>();

  @override
  void apply(CacheContext<MessageItem> ctx) {
    this
      ..uid = ctx.data.uid
      ..author = ctx.data.author
      ..title = ctx.data.title
      ..createdAt = ctx.data.date
      ..contentHtml = ctx.data.contentHTML
      ..contentText = ctx.data.contentText
      ..student.value = ctx.cacheManager.findStudent();

    if (ctx.data is NoticeBoardItem) {
      final nb = ctx.data as NoticeBoardItem;
      validFrom = nb.validFrom;
      validTo = nb.validTo;
      type = 'NoticeBoard';
    } else if (ctx.data is InfoBoardItem) {
      final ib = ctx.data as InfoBoardItem;
      itemCreatedAt = ib.createdAt;
      type = ib.type.name;
    }
  }
}
