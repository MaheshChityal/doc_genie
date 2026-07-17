class CheckerDocModel {
  const CheckerDocModel({
    required this.id,
    required this.referenceNumber,
    required this.submittedBy,
    required this.transactionType,
    required this.status,
    required this.date,
    this.fileName = '',
    this.fields = const {},
  });

  final String id;
  final String referenceNumber;
  final String submittedBy;
  final String transactionType;
  final String status;
  final String date;
  final String fileName;
  final Map<String, String> fields;

  factory CheckerDocModel.fromJson(Map<String, dynamic> json) =>
      CheckerDocModel(
        id: (json['id'] ?? '').toString(),
        referenceNumber: (json['referenceNumber'] ?? '').toString(),
        submittedBy: (json['submittedBy'] ?? '').toString(),
        transactionType: (json['transactionType'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        date: (json['date'] ?? '').toString(),
        fileName: (json['fileName'] ?? '').toString(),
        fields: (json['fields'] is Map)
            ? Map<String, String>.from(
                (json['fields'] as Map).map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ),
              )
            : {},
      );

  CheckerDocModel copyWith({String? status}) => CheckerDocModel(
    id: id,
    referenceNumber: referenceNumber,
    submittedBy: submittedBy,
    transactionType: transactionType,
    status: status ?? this.status,
    date: date,
    fileName: fileName,
    fields: fields,
  );
}
