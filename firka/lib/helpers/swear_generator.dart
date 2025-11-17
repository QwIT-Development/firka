import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';

List<String> _nouns = [];
List<String> _adjectives = [];

Future<void> loadDirtyWords() async {
  final xmlString = await rootBundle.loadString('assets/swears/DirtyWords.xml');
  final document = XmlDocument.parse(xmlString);

  for (final node in document.findAllElements('Word')) {
    final type = node.getAttribute('type');
    final text = node.text.trim();

    if (type == 'f') {
      _nouns.add(text);
    } else if (type == 'm') {
      _adjectives.add(text);
    }
  }
}

String generateSwearSentence(
    {int words = 3, bool capitalize = true, bool exclamation = true}) {
  if (words < 1) {
    throw ArgumentError('Words must be at least 1');
  }

  final random = Random();

  // if we only need one word, return a noun, that's the one that fits the most
  if (words == 1) {
    final word = _nouns[random.nextInt(_nouns.length)].toLowerCase();
    return (capitalize ? word[0].toUpperCase() + word.substring(1) : word) +
        (exclamation ? '!' : '');
  }

  final chosenNouns = List.generate(
    words - 1,
    (_) => _nouns[random.nextInt(_nouns.length)],
  );

  final adjective = _adjectives[random.nextInt(_adjectives.length)];

  final swear = '${chosenNouns.join(', ')} $adjective'.toLowerCase();

  return (capitalize ? swear[0].toUpperCase() + swear.substring(1) : swear) +
      (exclamation ? '!' : '');
}
