class HomeModel {
  const HomeModel({
    this.stats = const [],
    this.recentActivity = const [],
  });

  final List<HomeStat> stats;
  final List<RecentActivity> recentActivity;

  factory HomeModel.fromJson(Map<String, dynamic> json) => HomeModel(
    stats: (json['stats'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => HomeStat.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    recentActivity: (json['recentActivity'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => RecentActivity.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );
}

class HomeStat {
  const HomeStat({
    required this.label,
    required this.value,
    required this.iconKey,
    required this.colorHex,
  });

  final String label;
  final String value;
  final String iconKey;
  final int colorHex;

  factory HomeStat.fromJson(Map<String, dynamic> json) => HomeStat(
    label: (json['label'] ?? '').toString(),
    value: (json['value'] ?? '').toString(),
    iconKey: (json['iconKey'] ?? '').toString(),
    colorHex: (json['colorHex'] ?? 0xFF183B5B) as int,
  );
}

class RecentActivity {
  const RecentActivity({
    required this.id,
    required this.referenceNumber,
    required this.transactionType,
    required this.status,
    required this.date,
  });

  final String id;
  final String referenceNumber;
  final String transactionType;
  final String status;
  final String date;

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
    id: (json['id'] ?? '').toString(),
    referenceNumber: (json['referenceNumber'] ?? '').toString(),
    transactionType: (json['transactionType'] ?? '').toString(),
    status: (json['status'] ?? '').toString(),
    date: (json['date'] ?? '').toString(),
  );
}
