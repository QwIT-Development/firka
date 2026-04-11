import '../extensions.dart';
import 'generic.dart';

class NoticeBoardItem extends UidObj {
  final String author;
  final DateTime validFrom;
  final DateTime validTo;
  final String title;
  final String contentHTML;
  final String contentText;

  NoticeBoardItem({
    required super.uid,
    required this.author,
    required this.validFrom,
    required this.validTo,
    required this.title,
    required this.contentHTML,
    required this.contentText,
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

class InfoBoardItem extends UidObj {
  final String title;
  final DateTime date;
  final String author;
  final DateTime createdAt;
  final String contentHTML;
  final String contentText;
  final NameUidDesc type;

  InfoBoardItem({
    required super.uid,
    required this.title,
    required this.date,
    required this.author,
    required this.createdAt,
    required this.contentHTML,
    required this.contentText,
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
