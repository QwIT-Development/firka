class NoticeBoardItem {
  final String uid;
  final String author;
  final DateTime validFrom;
  final DateTime validTo;
  final String title;
  final String contentHTML;
  final String contentText;

  NoticeBoardItem(
      {required this.uid,
      required this.author,
      required this.validFrom,
      required this.validTo,
      required this.title,
      required this.contentHTML,
      required this.contentText});

  factory NoticeBoardItem.fromJson(Map<String, dynamic> json) {
    return NoticeBoardItem(
        uid: json['Uid'],
        author: json['RogzitoNeve'],
        validFrom: DateTime.parse(json['ErvenyessegKezdete']),
        validTo: DateTime.parse(json['ErvenyessegVege']),
        title: json['Cim'],
        contentHTML: json['Tartalom'],
        contentText: json['TartalomText']);
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
