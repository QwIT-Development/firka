import '../extensions.dart';
import 'generic.dart';

abstract class MessageItem extends UidObj {
  final String title;
  final String author;
  final String contentHTML;
  final String contentText;

  const MessageItem({
    required super.uid,
    required this.title,
    required this.author,
    required this.contentHTML,
    required this.contentText,
  });

  DateTime get date;
}

class NoticeBoardItem extends MessageItem {
  final DateTime validFrom;
  final DateTime validTo;

  @override
  DateTime get date => validFrom;

  const NoticeBoardItem({
    required super.uid,
    required super.title,
    required super.author,
    required super.contentHTML,
    required super.contentText,
    required this.validFrom,
    required this.validTo,
  });

  factory NoticeBoardItem.fromJson(Map<String, dynamic> json) {
    return NoticeBoardItem(
      uid: json['Uid'],
      author: json['RogzitoNeve'],
      validFrom: json.localDate('ErvenyessegKezdete')!,
      validTo: json.localDate('ErvenyessegVege')!,
      title: json['Cim'],
      contentHTML: json['Tartalom'],
      contentText: json['TartalomText'],
    );
  }

  @override
  String toString() {
    return 'NoticeBoardItem('
        'uid: "$uid", '
        'author: "$author", '
        'validFrom: "$validFrom", '
        'validTo: "$validTo", '
        'title: "$title", '
        'contentHTML: "$contentHTML", '
        'contentText: "$contentText"'
        ')';
  }
}

class InfoBoardItem extends MessageItem {
  final DateTime date;
  final DateTime createdAt;
  final NameUidDesc type;

  const InfoBoardItem({
    required super.uid,
    required super.title,
    required super.author,
    required super.contentHTML,
    required super.contentText,
    required this.createdAt,
    required this.date,
    required this.type,
  });

  factory InfoBoardItem.fromJson(Map<String, dynamic> json) {
    return InfoBoardItem(
      uid: json['Uid'],
      title: json['Cim'],
      date: json.localDate('Datum')!,
      author: json['KeszitoTanarNeve'],
      createdAt: json.localDate('KeszitesDatuma')!,
      contentText: json['Tartalom'],
      contentHTML: json['TartalomFormazott'],
      type: json.nameUidDesc('Tipus')!,
    );
  }

  @override
  String toString() {
    return 'InfoBoard('
        'uid: "$uid", '
        'title: "$title", '
        'date: "$date", '
        'author: "$author", '
        'createdAt: "$createdAt", '
        'contentText: "$contentText", '
        'contentHTML: "$contentHTML", '
        'type: $type'
        ')';
  }
}
