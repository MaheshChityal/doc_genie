extension TextUtils on String {
  String capitalizeFirstLetter() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String capitalizeEachWord() {
    if (isEmpty) return this;
    return split(
      ' ',
    ).map((w) => w.isEmpty ? w : w.capitalizeFirstLetter()).join(' ');
  }

  bool get isValidEmail {
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return regex.hasMatch(trim());
  }
}
