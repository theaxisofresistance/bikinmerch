typedef Json = Map<String, dynamic>;

Json object(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Json> rows(dynamic value) =>
    value is List ? value.map(object).toList() : [];
int number(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;
String textOf(dynamic value, [String fallback = '']) =>
    value?.toString() ?? fallback;
String money(dynamic value) {
  final digits = number(value).abs().toString();
  final formatted = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '${number(value) < 0 ? '-' : ''}Rp $formatted';
}

String dateLabel(dynamic value) {
  final date = DateTime.tryParse(textOf(value))?.toLocal();
  if (date == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
  factory AppUser.fromJson(Json json) => AppUser(
    id: textOf(json['id']),
    name: textOf(json['name']),
    email: textOf(json['email']),
    role: textOf(json['role']),
  );
  final String id, name, email, role;
}

class Product {
  Product.fromJson(Json json)
    : id = textOf(json['id']),
      name = textOf(json['name']),
      category = textOf(json['category']),
      description = textOf(json['description']),
      image = textOf(json['image']),
      printArea = textOf(json['printArea']),
      basePrice = number(json['basePrice']),
      variants = rows(json['variants']);
  final String id, name, category, description, image, printArea;
  final int basePrice;
  final List<Json> variants;
}

const productionSteps = [
  'QUEUED',
  'PRINTING',
  'QC',
  'PACKED',
  'SHIPPED',
  'DELIVERED',
];
const orderSteps = ['PAID', ...productionSteps];
