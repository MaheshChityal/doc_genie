class ReportModel {
  const ReportModel({
    required this.stats,
    required this.documents,
  });

  final ReportStats stats;
  final List<ReportDoc> documents;

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        stats: ReportStats.fromJson(
          Map<String, dynamic>.from((json['stats'] as Map?) ?? {}),
        ),
        documents: (json['documents'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ReportDoc.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class ReportStats {
  const ReportStats({
    required this.total,
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.rtgs,
    required this.neft,
    required this.fundTransfer,
  });

  final int total;
  final int pending;
  final int approved;
  final int rejected;
  final int rtgs;
  final int neft;
  final int fundTransfer;

  factory ReportStats.fromJson(Map<String, dynamic> json) => ReportStats(
        total: (json['total'] as num? ?? 0).toInt(),
        pending: (json['pending'] as num? ?? 0).toInt(),
        approved: (json['approved'] as num? ?? 0).toInt(),
        rejected: (json['rejected'] as num? ?? 0).toInt(),
        rtgs: (json['rtgs'] as num? ?? 0).toInt(),
        neft: (json['neft'] as num? ?? 0).toInt(),
        fundTransfer: (json['fundTransfer'] as num? ?? 0).toInt(),
      );
}

class ReportDoc {
  const ReportDoc({
    required this.id,
    required this.referenceNumber,
    required this.transactionType,
    required this.status,
    required this.date,
    required this.submittedBy,
    required this.fileName,
  });

  final String id;
  final String referenceNumber;
  final String transactionType;
  final String status;
  final String date;
  final String submittedBy;
  final String fileName;

  factory ReportDoc.fromJson(Map<String, dynamic> json) => ReportDoc(
        id: (json['id'] ?? '').toString(),
        referenceNumber: (json['referenceNumber'] ?? '').toString(),
        transactionType: (json['transactionType'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
        submittedBy: (json['submittedBy'] ?? '').toString(),
        fileName: (json['fileName'] ?? '').toString(),
      );
}
