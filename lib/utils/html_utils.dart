/// Убирает HTML-теги из текста. Описания товаров хранятся в Django как HTML
/// (редактор CKEditor), поэтому без этой очистки в приложении были бы видны
/// сырые теги вроде <p>, <br>, <li>.
String stripHtml(String html) {
  var text = html;

  // Переносы строк для блочных элементов, до того как теги будут вырезаны.
  text = text.replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(
    RegExp(r'</\s*(p|div|li|h[1-6])\s*>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<\s*li[^>]*>', caseSensitive: false), '• ');

  // Все оставшиеся теги.
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  text = _decodeHtmlEntities(text);

  // Схлопываем лишние пробелы/пустые строки.
  text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return text.trim();
}

// Именованные HTML-сущности, которые реально встречаются в текстах из
// CKEditor (типографские символы: тире, буллеты, кавычки-ёлочки и т.д.).
const _namedHtmlEntities = <String, String>{
  'nbsp': ' ',
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'bull': '•',
  'ndash': '–',
  'mdash': '—',
  'hellip': '…',
  'laquo': '«',
  'raquo': '»',
  'lsquo': '\u2018',
  'rsquo': '\u2019',
  'ldquo': '\u201C',
  'rdquo': '\u201D',
  'copy': '©',
  'reg': '®',
  'trade': '™',
  'deg': '°',
  'plusmn': '±',
  'times': '×',
  'divide': '÷',
  'euro': '€',
  'pound': '£',
  'cent': '¢',
  'yen': '¥',
  'sect': '§',
  'para': '¶',
  'middot': '·',
  'emsp': '\u2003',
  'ensp': '\u2002',
  'thinsp': '\u2009',
  'shy': '',

  // Латинские буквы с диакритикой — стандартные HTML-сущности (не
  // специфичные для туркменского, но именно ими CKEditor кодирует буквы
  // вроде ä, ö, ü, ç, ý в туркменском тексте). Без них весь туркменский
  // перевод выглядел как "g&ouml;rn&uuml;ş" вместо "görnüş".
  'aacute': 'á', 'Aacute': 'Á',
  'eacute': 'é', 'Eacute': 'É',
  'iacute': 'í', 'Iacute': 'Í',
  'oacute': 'ó', 'Oacute': 'Ó',
  'uacute': 'ú', 'Uacute': 'Ú',
  'yacute': 'ý', 'Yacute': 'Ý',
  'ntilde': 'ñ', 'Ntilde': 'Ñ',
  'ccedil': 'ç', 'Ccedil': 'Ç',
  'auml': 'ä', 'Auml': 'Ä',
  'euml': 'ë', 'Euml': 'Ë',
  'iuml': 'ï', 'Iuml': 'Ï',
  'ouml': 'ö', 'Ouml': 'Ö',
  'uuml': 'ü', 'Uuml': 'Ü',
  'yuml': 'ÿ', 'Yuml': 'Ÿ',
  'acirc': 'â', 'Acirc': 'Â',
  'ecirc': 'ê', 'Ecirc': 'Ê',
  'icirc': 'î', 'Icirc': 'Î',
  'ocirc': 'ô', 'Ocirc': 'Ô',
  'ucirc': 'û', 'Ucirc': 'Û',
  'agrave': 'à', 'Agrave': 'À',
  'egrave': 'è', 'Egrave': 'È',
  'igrave': 'ì', 'Igrave': 'Ì',
  'ograve': 'ò', 'Ograve': 'Ò',
  'ugrave': 'ù', 'Ugrave': 'Ù',
  'aring': 'å', 'Aring': 'Å',
  'atilde': 'ã', 'Atilde': 'Ã',
  'otilde': 'õ', 'Otilde': 'Õ',
  'oslash': 'ø', 'Oslash': 'Ø',
  'aelig': 'æ', 'AElig': 'Æ',
  'szlig': 'ß',
};

/// Раскодирует HTML-сущности: именованные (см. [_namedHtmlEntities]),
/// десятичные (`&#128512;`) и шестнадцатеричные (`&#x1F600;`) — именно через
/// числовые сущности CKEditor обычно сохраняет эмодзи, поэтому без их
/// поддержки эмодзи в описании не показывались.
String _decodeHtmlEntities(String input) {
  final pattern = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);');
  return input.replaceAllMapped(pattern, (match) {
    final entity = match.group(1)!;
    try {
      if (entity.startsWith('#x') || entity.startsWith('#X')) {
        return String.fromCharCode(int.parse(entity.substring(2), radix: 16));
      }
      if (entity.startsWith('#')) {
        return String.fromCharCode(int.parse(entity.substring(1)));
      }
      return _namedHtmlEntities[entity] ?? match.group(0)!;
    } catch (_) {
      return match.group(0)!;
    }
  });
}
