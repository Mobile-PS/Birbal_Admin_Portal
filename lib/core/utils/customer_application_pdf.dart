import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/models/customer_application.dart';
import '../constants/app_assets.dart';
import 'document_base64.dart';
import 'formatters.dart';

abstract final class CustomerApplicationPdf {
  static Future<Uint8List> build(CustomerApplication application) async {
    final logoBytes = await rootBundle.load(AppAssets.logo);
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final doc = pw.Document(
      title: 'Policy Login Details · ${application.applicationNumber}',
      author: 'Biirbal Advice',
    );

    final pages = _CustomerApplicationPdfBuilder(
      application: application,
      logo: logo,
    ).buildPages();

    for (final page in pages) {
      doc.addPage(page);
    }

    return doc.save();
  }
}

class _CustomerApplicationPdfBuilder {
  _CustomerApplicationPdfBuilder({
    required this.application,
    required this.logo,
  });

  final CustomerApplication application;
  final pw.MemoryImage logo;

  static const _navy = PdfColor.fromInt(0xFF0B3A5B);
  static const _teal = PdfColor.fromInt(0xFF49999A);
  static const _label = PdfColor.fromInt(0xFF6B7280);
  static const _value = PdfColor.fromInt(0xFF12202B);
  static const _line = PdfColor.fromInt(0xFFE2E8F0);
  static const _softTeal = PdfColor.fromInt(0xFFEEF6F6);
  static const _warn = PdfColor.fromInt(0xFFB54708);
  static const _ok = PdfColor.fromInt(0xFF027A48);
  static const _okBg = PdfColor.fromInt(0xFFECFDF3);

  List<pw.Page> buildPages() {
    final content = <pw.Widget>[
      _titleBlock(),
      pw.SizedBox(height: 14),
      _sectionTitle('Application Summary'),
      _kvTable(_summaryRows()),
      pw.SizedBox(height: 10),
      _statusBadges(),
      pw.SizedBox(height: 14),
      _sectionTitle('Proposer Details'),
      _kvTable(_proposerRows()),
      pw.SizedBox(height: 14),
      if (application.nominee != null) ...[
        _sectionTitle('Nominee Details'),
        _kvTable(_nomineeRows(application.nominee!)),
        pw.SizedBox(height: 14),
      ],
      if (application.bankDetails != null) ...[
        _sectionTitle('Proposer Bank Details'),
        _kvTable(_bankRows(application.bankDetails!)),
        pw.SizedBox(height: 14),
      ],
      _sectionTitle('Proposer Documents'),
      _kvTable(_proposerDocumentRows()),
      pw.SizedBox(height: 8),
      pw.Text(
        "Proposer's medical history and lifestyle are listed under Insured Member 1 (Self).",
        style: pw.TextStyle(
          color: _label,
          fontSize: 9,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
      pw.SizedBox(height: 16),
      for (final member in application.insuredMembers) ...[
        _memberBlock(member),
        pw.SizedBox(height: 16),
      ],
      _sectionTitle('Declaration & Confirmation'),
      _declarationBlock(),
      pw.SizedBox(height: 14),
      _sectionTitle('Document Checklist'),
      _checklistTable(),
      pw.SizedBox(height: 16),
      _sectionTitle('Attached Documents'),
      ..._attachmentWidgets(),
    ];

    return [
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 28),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        header: (context) => _header(context),
        footer: (context) => _footer(context),
        build: (context) => content,
      ),
    ];
  }

  pw.Widget _header(pw.Context context) {
    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 28,
                height: 28,
                decoration: const pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                padding: const pw.EdgeInsets.all(2),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'BIIRBAL ADVICE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              pw.Flexible(
                child: pw.Text(
                  'Policy Login Details · ${application.applicationNumber} · ${application.proposer.fullName}',
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(height: 2.2, color: _teal),
        pw.SizedBox(height: 12),
      ],
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Column(
      children: [
        pw.Container(height: 1, color: _line),
        pw.SizedBox(height: 6),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Confidential — contains personal, medical and bank details. For insurance processing only.',
                style: const pw.TextStyle(color: _label, fontSize: 8),
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber}',
              style: const pw.TextStyle(color: _label, fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _titleBlock() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'POLICY LOGIN DETAILS',
                style: pw.TextStyle(
                  color: _navy,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Prepared by Biirbal Advice for policy login · Generated ${_formatDateTime(DateTime.now().toIso8601String())}',
                style: const pw.TextStyle(color: _label, fontSize: 9),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Application ID',
              style: const pw.TextStyle(color: _label, fontSize: 8),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              application.applicationNumber,
              style: pw.TextStyle(
                color: _navy,
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<_Kv> _summaryRows() {
    final members = application.insuredMembers;
    CustomerApplicationInsuredMember? selfMember;
    for (final member in members) {
      final relationship = member.relationship.toUpperCase();
      final type = member.memberType.toUpperCase();
      if (relationship == 'SELF' || type == 'SELF') {
        selfMember = member;
        break;
      }
    }
    selfMember ??= members.isEmpty ? null : members.first;
    final memberSummary = members.isEmpty
        ? '—'
        : '${members.length} — ${members.map((m) => '${_firstName(m.fullName)} (${_titleCase(m.relationship)})').join(', ')}';

    return [
      _Kv('Proposer Name', application.proposer.fullName),
      _Kv('Proposer Mobile', _dash(application.proposer.mobile)),
      _Kv('Policy Category', _titleCase(application.policyCategory)),
      _Kv(
        'Proposer is also Insured',
        selfMember == null
            ? 'No'
            : 'Yes (Insured Member ${selfMember.memberNumber} — ${_titleCase(selfMember.relationship)})',
      ),
      _Kv('Total Insured Members', memberSummary),
      _Kv(
        'Submission Date & Time',
        _formatDateTime(application.submittedAt ?? application.createdAt),
      ),
      _Kv(
        'Customer Completion Status',
        _titleCase(application.completionStatus),
      ),
      _Kv(
        'Processing Status',
        _titleCase(application.processingStatus),
        valueColor: _ok,
        valueBackground: _okBg,
      ),
      _Kv('Application Type', _titleCase(application.applicationType)),
    ];
  }

  pw.Widget _statusBadges() {
    final members = application.insuredMembers;
    final medicalCount =
        members.where((m) => m.hasMedicalHistory).length;
    final alcohol = members
        .where((m) => m.lifestyle.alcohol)
        .map((m) => _firstName(m.fullName))
        .toList();
    final cigarettes = members
        .where((m) => m.lifestyle.cigarettes)
        .map((m) => _firstName(m.fullName))
        .toList();
    final lifestyleParts = <String>[];
    if (alcohol.isNotEmpty) {
      lifestyleParts.add('Alcohol: ${alcohol.join(', ')}');
    }
    if (cigarettes.isNotEmpty) {
      lifestyleParts.add('Cigarette: ${cigarettes.join(', ')}');
    }
    final lifestyleText =
        lifestyleParts.isEmpty ? 'None declared' : lifestyleParts.join(' · ');

    final minorMembers = members.where((m) {
      final age = _ageFromDob(m.dateOfBirth);
      return age != null && age < 18;
    }).toList();
    final minorText = minorMembers.isEmpty
        ? 'No'
        : minorMembers
            .map((m) {
              final age = _ageFromDob(m.dateOfBirth);
              return '${_firstName(m.fullName)}${age == null ? '' : ' ($age yrs)'}';
            })
            .join(', ');

    final nominee = application.nominee;
    final nomineeText = nominee == null
        ? '—'
        : nominee.isMinor
            ? 'Yes — ${nominee.fullName}'
            : 'No';

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _softTeal,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFD7E8E8)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _badge('MEDICAL HISTORY', '$medicalCount of ${members.length} members'),
          _badge('LIFESTYLE', lifestyleText),
          _badge('MINOR INSURED', minorText),
          _badge('MINOR NOMINEE', nomineeText, last: true),
        ],
      ),
    );
  }

  pw.Widget _badge(String title, String value, {bool last = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: pw.EdgeInsets.only(right: last ? 0 : 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: _navy,
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: const pw.TextStyle(color: _value, fontSize: 8.5),
            ),
          ],
        ),
      ),
    );
  }

  List<_Kv> _proposerRows() {
    final p = application.proposer;
    return [
      _Kv('Full Name', p.fullName),
      _Kv('Gender', _titleCase(p.gender)),
      _Kv('Date of Birth', _formatDob(p.dateOfBirth)),
      _Kv('Height', _dash(p.height)),
      _Kv('Weight', p.weightKg == null ? '—' : '${p.weightKg} kg'),
      _Kv('Email Address', _dash(p.email)),
      _Kv('Mobile Number', _dash(p.mobile)),
      _Kv('Occupation', _dash(p.occupation)),
      _Kv('Nature of Duty', _dash(p.natureOfDuty)),
      _Kv('Annual Income', _formatIncome(p.annualIncome)),
      _Kv('Full Address', _dash(p.fullAddress)),
      _Kv("Mother's Full Name", _dash(p.motherFullName)),
    ];
  }

  List<_Kv> _nomineeRows(CustomerApplicationNominee nominee) {
    return [
      _Kv('Nominee Full Name', nominee.fullName),
      _Kv('Relationship with Proposer', _titleCase(nominee.relationship)),
      _Kv('Date of Birth', _formatDob(nominee.dateOfBirth)),
      _Kv('Minor Nominee', nominee.isMinor ? 'Yes' : 'No'),
      _Kv(
        'Appointee',
        nominee.isMinor
            ? _dash(nominee.appointeeName)
            : 'Not required — nominee is an adult',
      ),
    ];
  }

  List<_Kv> _bankRows(CustomerApplicationBankDetails bank) {
    return [
      _Kv('Account Holder Full Name', bank.accountHolderFullName),
      _Kv('Bank Name', bank.bankName),
      _Kv('Account Number', bank.accountNumber),
      _Kv('Branch Name', bank.branchName),
      _Kv('IFSC Code', bank.ifscCode),
      _Kv('Account Type', _titleCase(bank.accountType)),
      _Kv(
        'Cancelled Cheque / Passbook',
        bank.cancelledChequeOrPassbook?.uploadLabel ?? 'Not uploaded',
      ),
    ];
  }

  List<_Kv> _proposerDocumentRows() {
    final docs = application.proposerDocuments;
    final medicalCount = docs.medicalDocuments.length;
    return [
      _Kv('PAN Card', docs.panCard?.uploadLabel ?? 'Not uploaded'),
      _Kv('Aadhaar Card', docs.aadhaarCard?.uploadLabel ?? 'Not uploaded'),
      _Kv(
        'Medical Documents',
        medicalCount == 0
            ? 'Not uploaded'
            : 'Uploaded — $medicalCount file${medicalCount == 1 ? '' : 's'}',
      ),
      _Kv(
        'Digital Signature',
        docs.digitalSignature?.uploadLabel ?? 'Not uploaded',
      ),
    ];
  }

  pw.Widget _memberBlock(CustomerApplicationInsuredMember member) {
    final isSelf = member.relationship.toUpperCase() == 'SELF' ||
        member.memberType.toUpperCase() == 'SELF';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: const pw.BoxDecoration(
            color: _navy,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  'INSURED MEMBER ${member.memberNumber} — ${member.fullName.toUpperCase()}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: _teal,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Text(
                  _titleCase(member.relationship).toUpperCase(),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        if (isSelf)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(
              'Same person as the Proposer — personal details above apply.',
              style: pw.TextStyle(
                color: _label,
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        _kvTable([
          if (!isSelf) _Kv('Full Name', member.fullName),
          _Kv('Gender', _titleCase(member.gender)),
          _Kv('Date of Birth / Age', _formatDob(member.dateOfBirth)),
          _Kv('Height', _dash(member.height)),
          _Kv(
            'Weight',
            member.weightKg == null ? '—' : '${member.weightKg} kg',
          ),
          if (!isSelf) ...[
            _Kv('Email Address', _dash(member.email)),
            _Kv('Mobile Number', _dash(member.mobile)),
            _Kv('Occupation', _dash(member.occupation)),
            _Kv('Nature of Duty', _dash(member.natureOfDuty)),
            _Kv('Annual Income', _formatIncome(member.annualIncome)),
          ],
          _Kv(
            'Contact & Address',
            member.sameAsProposerAddress
                ? 'Same as Proposer'
                : _dash(member.fullAddress),
          ),
          _Kv(
            'Medical History',
            member.hasMedicalHistory
                ? 'Yes (${member.medicalConditions.length} condition${member.medicalConditions.length == 1 ? '' : 's'})'
                : 'No',
          ),
        ]),
        if (!member.hasMedicalHistory)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 6),
            child: pw.Text(
              'No existing or past medical condition declared.',
              style: const pw.TextStyle(color: _label, fontSize: 9),
            ),
          ),
        for (final condition in member.medicalConditions) ...[
          pw.SizedBox(height: 8),
          _conditionBlock(condition),
        ],
        pw.SizedBox(height: 8),
        pw.Text(
          'Lifestyle',
          style: pw.TextStyle(
            color: _navy,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        _kvTable([
          _Kv('Alcohol', member.lifestyle.alcohol ? 'Yes' : 'No'),
          _Kv('Cigarettes', member.lifestyle.cigarettes ? 'Yes' : 'No'),
          _Kv('Pan Masala', member.lifestyle.panMasala ? 'Yes' : 'No'),
        ]),
        pw.SizedBox(height: 8),
        pw.Text(
          'Pregnancy',
          style: pw.TextStyle(
            color: _navy,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        _kvTable([
          _Kv(
            'Pregnancy Status',
            member.pregnancy.applicable ? 'Applicable' : 'Not applicable',
          ),
        ]),
        pw.SizedBox(height: 8),
        pw.Text(
          'Documents',
          style: pw.TextStyle(
            color: _navy,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        _kvTable([
          _Kv(
            'PAN Card',
            member.documents.panCard?.uploadLabel ?? 'Not uploaded',
          ),
          _Kv(
            'Aadhaar Card',
            member.documents.aadhaarCard?.uploadLabel ?? 'Not uploaded',
          ),
          _Kv(
            'Medical Documents',
            member.documents.medicalDocuments.isEmpty
                ? (member.hasMedicalHistory ? 'Not uploaded' : 'Not applicable')
                : 'Uploaded — ${member.documents.medicalDocuments.length} file(s)',
          ),
        ]),
      ],
    );
  }

  pw.Widget _conditionBlock(CustomerApplicationMedicalCondition condition) {
    final titleParts = <String>[_titleCase(condition.disease)];
    if (condition.diabetesType != null && condition.diabetesType!.isNotEmpty) {
      titleParts.add(_titleCase(condition.diabetesType));
    }
    if (condition.bpType != null && condition.bpType!.isNotEmpty) {
      titleParts.add(_titleCase(condition.bpType));
    }

    final rows = <_Kv>[
      if (condition.diagnosedSince != null)
        _Kv('Diagnosed Since', condition.diagnosedSince!),
      if (condition.exactDiagnosisDate != null)
        _Kv('Exact Diagnosis Date', condition.exactDiagnosisDate!),
      if (condition.currentTreatment != null)
        _Kv('Current Treatment', condition.currentTreatment!),
      if (condition.medicineAndDose != null)
        _Kv('Medicine & Dose', condition.medicineAndDose!),
      if (condition.timing != null) _Kv('Timing', condition.timing!),
      if (condition.medication != null) _Kv('Medication', condition.medication!),
      if (condition.latestHba1c != null)
        _Kv('Latest HbA1c', condition.latestHba1c!),
      if (condition.latestBpReading != null)
        _Kv('Latest BP Reading', condition.latestBpReading!),
      if (condition.latestLipidProfile != null)
        _Kv('Latest Lipid Profile', condition.latestLipidProfile!),
      if (condition.heartRelatedComplication != null)
        _Kv(
          'Heart-related Complication',
          condition.heartRelatedComplication!,
        ),
      if (condition.hospitalization != null)
        _Kv('Hospitalization', condition.hospitalization! ? 'Yes' : 'No'),
      if (condition.hospitalizationOrComplication != null)
        _Kv(
          'Hospitalization / Complication',
          condition.hospitalizationOrComplication! ? 'Yes' : 'No',
        ),
      if (condition.pastAsthmaAttack != null)
        _Kv('Past Asthma Attack', condition.pastAsthmaAttack!),
      if (condition.hospitalizationDueToAsthma != null)
        _Kv(
          'Hospitalization due to Asthma',
          condition.hospitalizationDueToAsthma! ? 'Yes' : 'No',
        ),
      _Kv(
        'Reports / Prescription',
        condition.reportsOrPrescription.isEmpty
            ? 'Not uploaded'
            : 'Uploaded — ${condition.reportsOrPrescription.length} file(s)',
      ),
    ];

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _line),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titleParts.join(' — '),
            style: pw.TextStyle(
              color: _navy,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          _kvTable(rows),
        ],
      ),
    );
  }

  pw.Widget _declarationBlock() {
    const body =
        'I confirm that the information and documents provided by me are true and complete to the best of my knowledge. I understand that this information will be used for processing and servicing my insurance policy proposal.\n\n'
        'I consent to Biirbal Advice collecting, processing and sharing the information and documents provided by me, including health-related information of all insured members, with authorised insurers, intermediaries and service personnel solely for policy processing and servicing. I confirm I am authorised to provide the details of the other insured members.\n\n'
        'I understand that if any information given by me, including medical history and lifestyle habits, is incorrect, incomplete or not disclosed, the insurance company may reject a claim or cancel the policy as per the policy terms and applicable law, and I alone will be responsible for the consequences. Biirbal Advice and its advisors shall not be held responsible for any such outcome arising from the information provided by me.';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFFF8FAFC),
            border: pw.Border.all(color: _line),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DECLARATION',
                style: pw.TextStyle(
                  color: _navy,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                body,
                style: const pw.TextStyle(
                  color: _value,
                  fontSize: 8.5,
                  lineSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        _kvTable([
          _Kv(
            'Original Declaration Accepted',
            application.submittedAt == null
                ? _titleCase(application.completionStatus)
                : 'Yes — ${_formatDateTime(application.submittedAt)}',
          ),
          _Kv('Confirmed By', application.proposer.fullName),
          _Kv(
            'Digital Signature',
            application.proposerDocuments.digitalSignature?.uploadLabel ??
                'Not uploaded',
          ),
        ]),
      ],
    );
  }

  pw.Widget _checklistTable() {
    final rows = <List<String>>[
      [
        'Person',
        'PAN',
        'Aadhaar',
        'Medical',
        'Other',
      ],
      [
        '${application.proposer.fullName} (Proposer / Self)',
        application.proposerDocuments.panCard?.uploadLabel ?? 'Not uploaded',
        application.proposerDocuments.aadhaarCard?.uploadLabel ??
            'Not uploaded',
        application.proposerDocuments.medicalDocuments.isEmpty
            ? '—'
            : '${application.proposerDocuments.medicalDocuments.length} files',
        [
          if (application.bankDetails?.cancelledChequeOrPassbook?.isUploaded ??
              false)
            'Bank proof',
          if (application.proposerDocuments.digitalSignature?.isUploaded ??
              false)
            'signature',
        ].join(', ').ifEmpty('—'),
      ],
      for (final member in application.insuredMembers.where(
        (m) =>
            m.relationship.toUpperCase() != 'SELF' &&
            m.memberType.toUpperCase() != 'SELF',
      ))
        [
          '${member.fullName} (${_titleCase(member.relationship)})',
          member.documents.panCard?.uploadLabel ?? 'Not uploaded',
          member.documents.aadhaarCard?.uploadLabel ?? 'Not uploaded',
          member.documents.medicalDocuments.isEmpty
              ? (member.hasMedicalHistory ? 'Not uploaded' : 'Not applicable')
              : 'Uploaded',
          '—',
        ],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.7),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.4),
        1: const pw.FlexColumnWidth(1.1),
        2: const pw.FlexColumnWidth(1.1),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.3),
      },
      children: [
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: i == 0
                ? const pw.BoxDecoration(color: _softTeal)
                : null,
            children: [
              for (final cell in rows[i])
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    cell,
                    style: pw.TextStyle(
                      color: _value,
                      fontSize: 8,
                      fontWeight:
                          i == 0 ? pw.FontWeight.bold : pw.FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  List<pw.Widget> _attachmentWidgets() {
    final items = <({String label, CustomerApplicationDocument doc})>[];

    void add(String label, CustomerApplicationDocument? doc) {
      if (doc?.isUploaded == true) {
        items.add((label: label, doc: doc!));
      }
    }

    add('Proposer PAN Card', application.proposerDocuments.panCard);
    add('Proposer Aadhaar Card', application.proposerDocuments.aadhaarCard);
    add(
      'Proposer Digital Signature',
      application.proposerDocuments.digitalSignature,
    );
    for (final doc in application.proposerDocuments.medicalDocuments) {
      add('Proposer Medical — ${_dash(doc.fileName)}', doc);
    }
    add(
      'Cancelled Cheque / Passbook',
      application.bankDetails?.cancelledChequeOrPassbook,
    );

    for (final member in application.insuredMembers) {
      add('${member.fullName} — PAN', member.documents.panCard);
      add('${member.fullName} — Aadhaar', member.documents.aadhaarCard);
      for (final doc in member.documents.medicalDocuments) {
        add('${member.fullName} — Medical (${_dash(doc.fileName)})', doc);
      }
      for (final condition in member.medicalConditions) {
        for (final doc in condition.reportsOrPrescription) {
          add(
            '${member.fullName} — ${_titleCase(condition.disease)} report (${_dash(doc.fileName)})',
            doc,
          );
        }
      }
    }

    if (items.isEmpty) {
      return [
        pw.Text(
          'No document images were included in the application payload.',
          style: const pw.TextStyle(color: _label, fontSize: 9),
        ),
      ];
    }

    return [
      for (final item in items) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          item.label,
          style: pw.TextStyle(
            color: _navy,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        _documentImage(item.doc),
      ],
    ];
  }

  pw.Widget _documentImage(CustomerApplicationDocument doc) {
    final decoded = decodeDataUri(
      DocumentBase64.normalize(
        doc.base64,
        contentType: doc.contentType,
        fileName: doc.fileName,
      ),
    );
    if (decoded == null || !decoded.isImage) {
      return pw.Text(
        'File attached: ${_dash(doc.fileName)} (${_dash(doc.contentType)})',
        style: const pw.TextStyle(color: _label, fontSize: 9),
      );
    }

    try {
      final image = pw.MemoryImage(decoded.bytes);
      return pw.Container(
        alignment: pw.Alignment.centerLeft,
        child: pw.Image(image, height: 180, fit: pw.BoxFit.contain),
      );
    } catch (_) {
      return pw.Text(
        'Unable to render ${_dash(doc.fileName)}',
        style: const pw.TextStyle(color: _warn, fontSize: 9),
      );
    }
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: _navy,
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _kvTable(List<_Kv> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.35),
        1: pw.FlexColumnWidth(2.2),
      },
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              pw.Container(
                color: const PdfColor.fromInt(0xFFF8FAFC),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: pw.Text(
                  row.label,
                  style: const pw.TextStyle(color: _label, fontSize: 8.5),
                ),
              ),
              pw.Container(
                color: row.valueBackground,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: pw.Text(
                  row.value,
                  style: pw.TextStyle(
                    color: row.valueColor ?? _value,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _Kv {
  const _Kv(
    this.label,
    this.value, {
    this.valueColor,
    this.valueBackground,
  });

  final String label;
  final String value;
  final PdfColor? valueColor;
  final PdfColor? valueBackground;
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

String _dash(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '—';
  return text;
}

String _titleCase(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '—';
  return text
      .toLowerCase()
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _firstName(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.isEmpty ? fullName : parts.first;
}

String _formatIncome(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '—';
  final parsed = num.tryParse(text.replaceAll(',', ''));
  if (parsed == null) return text;
  return formatInr(parsed);
}

String _formatDob(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '—';

  final age = _ageFromDob(text);
  final display = _normalizeDate(text) ?? text;
  if (age == null) return display;
  return '$display ($age yrs)';
}

String? _normalizeDate(String value) {
  final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(value);
  if (slash != null) {
    final day = int.parse(slash.group(1)!);
    final month = int.parse(slash.group(2)!);
    final year = int.parse(slash.group(3)!);
    return _prettyDate(DateTime(year, month, day));
  }

  final parsed = DateTime.tryParse(value);
  if (parsed != null) return _prettyDate(parsed);
  return null;
}

String _formatDateTime(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return '—';
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return text;
  final local = parsed.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${_prettyDate(local)}, ${hour.toString().padLeft(2, '0')}:$minute $period';
}

String _prettyDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

int? _ageFromDob(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;

  DateTime? dob;
  final slash = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
  if (slash != null) {
    dob = DateTime(
      int.parse(slash.group(3)!),
      int.parse(slash.group(2)!),
      int.parse(slash.group(1)!),
    );
  } else {
    dob = DateTime.tryParse(text);
  }
  if (dob == null) return null;

  final now = DateTime.now();
  var age = now.year - dob.year;
  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) {
    age -= 1;
  }
  return age < 0 ? null : age;
}
