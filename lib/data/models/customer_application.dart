import '../../core/utils/json_utils.dart';

class CustomerApplicationDocument {
  const CustomerApplicationDocument({
    this.base64,
    this.contentType,
    this.documentId,
    this.documentType,
    this.downloadUrl,
    this.fileName,
    this.sizeBytes,
    this.verificationStatus,
  });

  final String? base64;
  final String? contentType;
  final String? documentId;
  final String? documentType;
  final String? downloadUrl;
  final String? fileName;
  final int? sizeBytes;
  final String? verificationStatus;

  bool get isUploaded {
    final value = base64?.trim();
    return value != null && value.isNotEmpty;
  }

  String get uploadLabel => isUploaded ? 'Uploaded' : 'Not uploaded';

  factory CustomerApplicationDocument.fromJson(Map<String, dynamic> json) {
    return CustomerApplicationDocument(
      base64: jsonNullableString(json['base64']),
      contentType: jsonNullableString(json['contentType']),
      documentId: jsonNullableString(json['documentId']),
      documentType: jsonNullableString(json['documentType']),
      downloadUrl: jsonNullableString(json['downloadUrl']),
      fileName: jsonNullableString(json['fileName']),
      sizeBytes: jsonNum(json['sizeBytes'])?.toInt(),
      verificationStatus: jsonNullableString(json['verificationStatus']),
    );
  }

  static CustomerApplicationDocument? maybeFrom(Object? raw) {
    if (raw is! Map) return null;
    return CustomerApplicationDocument.fromJson(
      Map<String, dynamic>.from(raw),
    );
  }
}

class CustomerApplicationBankDetails {
  const CustomerApplicationBankDetails({
    required this.accountHolderFullName,
    required this.accountNumber,
    required this.accountType,
    required this.bankName,
    required this.branchName,
    required this.ifscCode,
    this.cancelledChequeOrPassbook,
  });

  final String accountHolderFullName;
  final String accountNumber;
  final String accountType;
  final String bankName;
  final String branchName;
  final String ifscCode;
  final CustomerApplicationDocument? cancelledChequeOrPassbook;

  factory CustomerApplicationBankDetails.fromJson(Map<String, dynamic> json) {
    return CustomerApplicationBankDetails(
      accountHolderFullName: jsonString(json['accountHolderFullName']),
      accountNumber: jsonString(json['accountNumber']),
      accountType: jsonString(json['accountType']),
      bankName: jsonString(json['bankName']),
      branchName: jsonString(json['branchName']),
      ifscCode: jsonString(json['ifscCode']),
      cancelledChequeOrPassbook: CustomerApplicationDocument.maybeFrom(
        json['cancelledChequeOrPassbook'],
      ),
    );
  }
}

class CustomerApplicationLifestyle {
  const CustomerApplicationLifestyle({
    required this.alcohol,
    required this.cigarettes,
    required this.panMasala,
  });

  final bool alcohol;
  final bool cigarettes;
  final bool panMasala;

  factory CustomerApplicationLifestyle.fromJson(Map<String, dynamic> json) {
    return CustomerApplicationLifestyle(
      alcohol: json['alcohol'] == true,
      cigarettes: json['cigarettes'] == true,
      panMasala: json['panMasala'] == true,
    );
  }

  static const empty = CustomerApplicationLifestyle(
    alcohol: false,
    cigarettes: false,
    panMasala: false,
  );
}

class CustomerApplicationPregnancy {
  const CustomerApplicationPregnancy({required this.applicable});

  final bool applicable;

  factory CustomerApplicationPregnancy.fromJson(Map<String, dynamic> json) {
    return CustomerApplicationPregnancy(
      applicable: json['applicable'] == true,
    );
  }

  static const empty = CustomerApplicationPregnancy(applicable: false);
}

class CustomerApplicationMedicalCondition {
  const CustomerApplicationMedicalCondition({
    required this.conditionId,
    required this.disease,
    this.bpType,
    this.currentTreatment,
    this.diabetesType,
    this.diagnosedSince,
    this.exactDiagnosisDate,
    this.heartRelatedComplication,
    this.hospitalization,
    this.hospitalizationDueToAsthma,
    this.hospitalizationOrComplication,
    this.latestBpReading,
    this.latestHba1c,
    this.latestLipidProfile,
    this.medication,
    this.medicineAndDose,
    this.pastAsthmaAttack,
    this.reportsOrPrescription = const [],
    this.timing,
  });

  final String conditionId;
  final String disease;
  final String? bpType;
  final String? currentTreatment;
  final String? diabetesType;
  final String? diagnosedSince;
  final String? exactDiagnosisDate;
  final String? heartRelatedComplication;
  final bool? hospitalization;
  final bool? hospitalizationDueToAsthma;
  final bool? hospitalizationOrComplication;
  final String? latestBpReading;
  final String? latestHba1c;
  final String? latestLipidProfile;
  final String? medication;
  final String? medicineAndDose;
  final String? pastAsthmaAttack;
  final List<CustomerApplicationDocument> reportsOrPrescription;
  final String? timing;

  factory CustomerApplicationMedicalCondition.fromJson(
    Map<String, dynamic> json,
  ) {
    final reports = <CustomerApplicationDocument>[];
    final rawReports = json['reportsOrPrescription'];
    if (rawReports is List) {
      for (final item in rawReports) {
        final doc = CustomerApplicationDocument.maybeFrom(item);
        if (doc != null) reports.add(doc);
      }
    }

    return CustomerApplicationMedicalCondition(
      conditionId: jsonString(json['conditionId']),
      disease: jsonString(json['disease'], fallback: 'Condition'),
      bpType: jsonNullableString(json['bpType']),
      currentTreatment: jsonNullableString(json['currentTreatment']),
      diabetesType: jsonNullableString(json['diabetesType']),
      diagnosedSince: jsonNullableString(json['diagnosedSince']),
      exactDiagnosisDate: jsonNullableString(json['exactDiagnosisDate']),
      heartRelatedComplication: jsonNullableString(
        json['heartRelatedComplication'],
      ),
      hospitalization: json['hospitalization'] is bool
          ? json['hospitalization'] as bool
          : null,
      hospitalizationDueToAsthma: json['hospitalizationDueToAsthma'] is bool
          ? json['hospitalizationDueToAsthma'] as bool
          : null,
      hospitalizationOrComplication:
          json['hospitalizationOrComplication'] is bool
              ? json['hospitalizationOrComplication'] as bool
              : null,
      latestBpReading: jsonNullableString(json['latestBpReading']),
      latestHba1c: jsonNullableString(json['latestHba1c']),
      latestLipidProfile: jsonNullableString(json['latestLipidProfile']),
      medication: jsonNullableString(json['medication']),
      medicineAndDose: jsonNullableString(json['medicineAndDose']),
      pastAsthmaAttack: jsonNullableString(json['pastAsthmaAttack']),
      reportsOrPrescription: reports,
      timing: jsonNullableString(json['timing']),
    );
  }
}

class CustomerApplicationMemberDocuments {
  const CustomerApplicationMemberDocuments({
    this.aadhaarCard,
    this.panCard,
    this.medicalDocuments = const [],
  });

  final CustomerApplicationDocument? aadhaarCard;
  final CustomerApplicationDocument? panCard;
  final List<CustomerApplicationDocument> medicalDocuments;

  factory CustomerApplicationMemberDocuments.fromJson(
    Map<String, dynamic> json,
  ) {
    final medical = <CustomerApplicationDocument>[];
    final rawMedical = json['medicalDocuments'];
    if (rawMedical is List) {
      for (final item in rawMedical) {
        final doc = CustomerApplicationDocument.maybeFrom(item);
        if (doc != null) medical.add(doc);
      }
    }

    return CustomerApplicationMemberDocuments(
      aadhaarCard: CustomerApplicationDocument.maybeFrom(json['aadhaarCard']),
      panCard: CustomerApplicationDocument.maybeFrom(json['panCard']),
      medicalDocuments: medical,
    );
  }

  static const empty = CustomerApplicationMemberDocuments();
}

class CustomerApplicationInsuredMember {
  const CustomerApplicationInsuredMember({
    required this.fullName,
    required this.memberNumber,
    required this.memberType,
    required this.relationship,
    this.annualIncome,
    this.customerId,
    this.dateOfBirth,
    this.documents = CustomerApplicationMemberDocuments.empty,
    this.email,
    this.fullAddress,
    this.gender,
    this.height,
    this.lifestyle = CustomerApplicationLifestyle.empty,
    this.medicalConditions = const [],
    this.mobile,
    this.natureOfDuty,
    this.occupation,
    this.pregnancy = CustomerApplicationPregnancy.empty,
    this.sameAsProposerAddress = false,
    this.weightKg,
  });

  final String fullName;
  final int memberNumber;
  final String memberType;
  final String relationship;
  final String? annualIncome;
  final String? customerId;
  final String? dateOfBirth;
  final CustomerApplicationMemberDocuments documents;
  final String? email;
  final String? fullAddress;
  final String? gender;
  final String? height;
  final CustomerApplicationLifestyle lifestyle;
  final List<CustomerApplicationMedicalCondition> medicalConditions;
  final String? mobile;
  final String? natureOfDuty;
  final String? occupation;
  final CustomerApplicationPregnancy pregnancy;
  final bool sameAsProposerAddress;
  final String? weightKg;

  bool get hasMedicalHistory => medicalConditions.isNotEmpty;

  factory CustomerApplicationInsuredMember.fromJson(Map<String, dynamic> json) {
    final conditions = <CustomerApplicationMedicalCondition>[];
    final rawConditions = json['medicalConditions'];
    if (rawConditions is List) {
      for (final item in rawConditions) {
        if (item is Map) {
          conditions.add(
            CustomerApplicationMedicalCondition.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final lifestyleRaw = json['lifestyle'];
    final pregnancyRaw = json['pregnancy'];
    final documentsRaw = json['documents'];

    return CustomerApplicationInsuredMember(
      fullName: jsonString(json['fullName'], fallback: 'Insured Member'),
      memberNumber: jsonInt(json['memberNumber'], fallback: 1),
      memberType: jsonString(json['memberType']),
      relationship: jsonString(json['relationship']),
      annualIncome: jsonNullableString(json['annualIncome']),
      customerId: jsonNullableString(json['customerId']),
      dateOfBirth: jsonNullableString(json['dateOfBirth']),
      documents: documentsRaw is Map
          ? CustomerApplicationMemberDocuments.fromJson(
              Map<String, dynamic>.from(documentsRaw),
            )
          : CustomerApplicationMemberDocuments.empty,
      email: jsonNullableString(json['email']),
      fullAddress: jsonNullableString(json['fullAddress']),
      gender: jsonNullableString(json['gender']),
      height: jsonNullableString(json['height']),
      lifestyle: lifestyleRaw is Map
          ? CustomerApplicationLifestyle.fromJson(
              Map<String, dynamic>.from(lifestyleRaw),
            )
          : CustomerApplicationLifestyle.empty,
      medicalConditions: conditions,
      mobile: jsonNullableString(json['mobile']),
      natureOfDuty: jsonNullableString(json['natureOfDuty']),
      occupation: jsonNullableString(json['occupation']),
      pregnancy: pregnancyRaw is Map
          ? CustomerApplicationPregnancy.fromJson(
              Map<String, dynamic>.from(pregnancyRaw),
            )
          : CustomerApplicationPregnancy.empty,
      sameAsProposerAddress: json['sameAsProposerAddress'] == true,
      weightKg: jsonNullableString(json['weightKg']),
    );
  }
}

class CustomerApplicationNominee {
  const CustomerApplicationNominee({
    required this.fullName,
    required this.relationship,
    required this.isMinor,
    this.appointeeName,
    this.dateOfBirth,
  });

  final String fullName;
  final String relationship;
  final bool isMinor;
  final String? appointeeName;
  final String? dateOfBirth;

  factory CustomerApplicationNominee.fromJson(Map<String, dynamic> json) {
    return CustomerApplicationNominee(
      fullName: jsonString(json['fullName'], fallback: 'Nominee'),
      relationship: jsonString(json['relationship']),
      isMinor: json['isMinor'] == true,
      appointeeName: jsonNullableString(json['appointeeName']),
      dateOfBirth: jsonNullableString(json['dateOfBirth']),
    );
  }
}

class CustomerApplicationProposer {
  const CustomerApplicationProposer({
    required this.fullName,
    this.annualIncome,
    this.customerId,
    this.dateOfBirth,
    this.email,
    this.fullAddress,
    this.gender,
    this.height,
    this.mobile,
    this.motherFullName,
    this.natureOfDuty,
    this.occupation,
    this.weightKg,
  });

  final String fullName;
  final String? annualIncome;
  final String? customerId;
  final String? dateOfBirth;
  final String? email;
  final String? fullAddress;
  final String? gender;
  final String? height;
  final String? mobile;
  final String? motherFullName;
  final String? natureOfDuty;
  final String? occupation;
  final String? weightKg;

  factory CustomerApplicationProposer.fromJson(Map<String, dynamic> json) {
    return CustomerApplicationProposer(
      fullName: jsonString(json['fullName'], fallback: 'Proposer'),
      annualIncome: jsonNullableString(json['annualIncome']),
      customerId: jsonNullableString(json['customerId']),
      dateOfBirth: jsonNullableString(json['dateOfBirth']),
      email: jsonNullableString(json['email']),
      fullAddress: jsonNullableString(json['fullAddress']),
      gender: jsonNullableString(json['gender']),
      height: jsonNullableString(json['height']),
      mobile: jsonNullableString(json['mobile']),
      motherFullName: jsonNullableString(json['motherFullName']),
      natureOfDuty: jsonNullableString(json['natureOfDuty']),
      occupation: jsonNullableString(json['occupation']),
      weightKg: jsonNullableString(json['weightKg']),
    );
  }
}

class CustomerApplicationProposerDocuments {
  const CustomerApplicationProposerDocuments({
    this.aadhaarCard,
    this.digitalSignature,
    this.panCard,
    this.medicalDocuments = const [],
  });

  final CustomerApplicationDocument? aadhaarCard;
  final CustomerApplicationDocument? digitalSignature;
  final CustomerApplicationDocument? panCard;
  final List<CustomerApplicationDocument> medicalDocuments;

  factory CustomerApplicationProposerDocuments.fromJson(
    Map<String, dynamic> json,
  ) {
    final medical = <CustomerApplicationDocument>[];
    final rawMedical = json['medicalDocuments'];
    if (rawMedical is List) {
      for (final item in rawMedical) {
        final doc = CustomerApplicationDocument.maybeFrom(item);
        if (doc != null) medical.add(doc);
      }
    }

    return CustomerApplicationProposerDocuments(
      aadhaarCard: CustomerApplicationDocument.maybeFrom(json['aadhaarCard']),
      digitalSignature: CustomerApplicationDocument.maybeFrom(
        json['digitalSignature'],
      ),
      panCard: CustomerApplicationDocument.maybeFrom(json['panCard']),
      medicalDocuments: medical,
    );
  }

  static const empty = CustomerApplicationProposerDocuments();
}

class CustomerApplication {
  const CustomerApplication({
    required this.applicationId,
    required this.applicationNumber,
    required this.applicationType,
    required this.completionStatus,
    required this.processingStatus,
    required this.policyCategory,
    required this.proposer,
    this.bankDetails,
    this.createdAt,
    this.insuredMembers = const [],
    this.nominee,
    this.proposerDocuments = CustomerApplicationProposerDocuments.empty,
    this.submittedAt,
    this.updatedAt,
  });

  final String applicationId;
  final String applicationNumber;
  final String applicationType;
  final String completionStatus;
  final String processingStatus;
  final String policyCategory;
  final CustomerApplicationProposer proposer;
  final CustomerApplicationBankDetails? bankDetails;
  final String? createdAt;
  final List<CustomerApplicationInsuredMember> insuredMembers;
  final CustomerApplicationNominee? nominee;
  final CustomerApplicationProposerDocuments proposerDocuments;
  final String? submittedAt;
  final String? updatedAt;

  factory CustomerApplication.fromJson(Map<String, dynamic> json) {
    final members = <CustomerApplicationInsuredMember>[];
    final rawMembers = json['insuredMembers'];
    if (rawMembers is List) {
      for (final item in rawMembers) {
        if (item is Map) {
          members.add(
            CustomerApplicationInsuredMember.fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final bankRaw = json['bankDetails'];
    final nomineeRaw = json['nominee'];
    final proposerRaw = json['proposer'];
    final documentsRaw = json['proposerDocuments'];

    return CustomerApplication(
      applicationId: jsonString(json['applicationId']),
      applicationNumber: jsonString(
        json['applicationNumber'],
        fallback: '—',
      ),
      applicationType: jsonString(json['applicationType']),
      completionStatus: jsonString(json['completionStatus']),
      processingStatus: jsonString(json['processingStatus']),
      policyCategory: jsonString(json['policyCategory']),
      proposer: proposerRaw is Map
          ? CustomerApplicationProposer.fromJson(
              Map<String, dynamic>.from(proposerRaw),
            )
          : const CustomerApplicationProposer(fullName: 'Proposer'),
      bankDetails: bankRaw is Map
          ? CustomerApplicationBankDetails.fromJson(
              Map<String, dynamic>.from(bankRaw),
            )
          : null,
      createdAt: jsonNullableString(json['createdAt']),
      insuredMembers: members,
      nominee: nomineeRaw is Map
          ? CustomerApplicationNominee.fromJson(
              Map<String, dynamic>.from(nomineeRaw),
            )
          : null,
      proposerDocuments: documentsRaw is Map
          ? CustomerApplicationProposerDocuments.fromJson(
              Map<String, dynamic>.from(documentsRaw),
            )
          : CustomerApplicationProposerDocuments.empty,
      submittedAt: jsonNullableString(json['submittedAt']),
      updatedAt: jsonNullableString(json['updatedAt']),
    );
  }
}
