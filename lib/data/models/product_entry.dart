class ProductEntry {
  ProductEntry({
    required this.id,
    required this.productCategory,
    this.isEnabled = true,
  });

  final String id;
  final String productCategory;
  bool isEnabled;
}
