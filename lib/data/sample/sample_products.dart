import '../models/product_entry.dart';

/// In-memory product list used until a products API is wired up.
final sampleProducts = <ProductEntry>[
  ProductEntry(id: '1', productCategory: 'Health Insurance'),
  ProductEntry(id: '2', productCategory: 'Motor Insurance'),
  ProductEntry(
    id: '3',
    productCategory: 'Life Insurance',
    isEnabled: false,
  ),
];
