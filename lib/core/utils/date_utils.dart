extension DateTimeExtension on DateTime {
  /// YYYY-MM-DD 形式の文字列を返す
  String toDateString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  /// 時刻を除いた日付のみで比較するために使う
  DateTime toDateOnly() {
    return DateTime(year, month, day);
  }
}

extension StringDateExtension on String {
  /// YYYY-MM-DD 形式の文字列から DateTime を生成
  DateTime toDateTime() {
    return DateTime.parse(this);
  }

  /// 2つの日付文字列の差分（日数）を返す
  int daysDifferenceTo(String other) {
    final a = DateTime.parse(this).toDateOnly();
    final b = DateTime.parse(other).toDateOnly();
    return b.difference(a).inDays.abs();
  }
}

DateTime toDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
