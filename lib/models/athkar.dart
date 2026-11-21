/// Minimal shim — backend compat لـ badge_engine / badge_provider.
/// TODO: احذف الملف ده بعد إزالة كل مرجع لـ AthkarItem.
class AthkarItem {
  final String id;
  final String categoryId;
  final int displayOrder;
  final String arabic;
  final String? transliteration;
  final String? translation;
  final int repeatCount;
  final String? reference;
  final String? virtue;

  const AthkarItem({
    required this.id,
    required this.categoryId,
    required this.displayOrder,
    required this.arabic,
    this.transliteration,
    this.translation,
    this.repeatCount = 1,
    this.reference,
    this.virtue,
  });
}