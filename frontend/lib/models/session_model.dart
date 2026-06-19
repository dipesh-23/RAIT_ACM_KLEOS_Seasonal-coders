import 'triage_result.dart';

enum AgeGroup {
  infant('0 - 2 Years', '0 - 2 वर्षे', '0 - 2 वर्ष'),
  child('3 - 12 Years', '3 - 12 वर्षे', '3 - 12 वर्ष'),
  teen('13 - 19 Years', '13 - 19 वर्षे', '13 - 19 वर्ष'),
  adult('20 - 59 Years', '20 - 59 वर्षे', '20 - 59 वर्ष'),
  senior('60+ Years', '60+ वर्षे', '60+ वर्ष');

  final String labelEn;
  final String labelMr;
  final String labelHi;

  const AgeGroup(this.labelEn, this.labelMr, this.labelHi);

  String labelForLang(String langCode) {
    if (langCode == 'hi') return labelHi;
    if (langCode == 'mr') return labelMr;
    return labelEn;
  }
}

enum SymptomDuration {
  hours('Few Hours', 'काही तास', 'कुछ घंटे'),
  days1_3('1 - 3 Days', '1 - 3 दिवस', '1 - 3 दिन'),
  days4_7('4 - 7 Days', '4 - 7 दिवस', '4 - 7 दिन'),
  weeks('1 - 4 Weeks', '1 - 4 आठवडे', '1 - 4 सप्ताह'),
  months('More than a Month', 'एका महिन्याहून अधिक', 'एक महीने से अधिक');

  final String labelEn;
  final String labelMr;
  final String labelHi;

  const SymptomDuration(this.labelEn, this.labelMr, this.labelHi);

  String labelForLang(String langCode) {
    if (langCode == 'hi') return labelHi;
    if (langCode == 'mr') return labelMr;
    return labelEn;
  }
}

class SessionModel {
  final String id;
  final String sessionCode;
  final String ashaWorkerName;
  final String? patientName;
  final String? patientGender;
  final String? patientContact;
  final AgeGroup? patientAgeGroup;
  final SymptomDuration? symptomDuration;

  final String transcribedText;
  final List<String> confirmedConcepts;
  final String triageLevel;
  final DateTime startedAt;
  final bool isCompleted;
  final bool referralGenerated;

  final String? slipFilePath;

  SessionModel({
    String? id,
    String? sessionCode,
    required this.ashaWorkerName,
    this.patientName,
    this.patientGender,
    this.patientContact,
    this.patientAgeGroup,
    this.symptomDuration,
    this.transcribedText = '',
    this.confirmedConcepts = const [],
    this.triageLevel = 'GREEN',
    DateTime? startedAt,
    this.isCompleted = false,
    this.referralGenerated = false,
    this.slipFilePath,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        sessionCode = sessionCode ?? _generateCode(),
        startedAt = startedAt ?? DateTime.now();

  static String _generateCode() {
    final chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().microsecondsSinceEpoch.toString();
    return 'ASHA-${rand.substring(rand.length - 4)}';
  }

  SessionModel copyWith({
    String? ashaWorkerName,
    String? patientName,
    String? patientGender,
    String? patientContact,
    AgeGroup? patientAgeGroup,
    SymptomDuration? symptomDuration,
    String? transcribedText,
    List<String>? confirmedConcepts,
    String? triageLevel,
    bool? isCompleted,
    bool? referralGenerated,
    String? slipFilePath,
  }) {
    return SessionModel(
      id: id,
      sessionCode: sessionCode,
      ashaWorkerName: ashaWorkerName ?? this.ashaWorkerName,
      patientName: patientName ?? this.patientName,
      patientGender: patientGender ?? this.patientGender,
      patientContact: patientContact ?? this.patientContact,
      patientAgeGroup: patientAgeGroup ?? this.patientAgeGroup,
      symptomDuration: symptomDuration ?? this.symptomDuration,
      transcribedText: transcribedText ?? this.transcribedText,
      confirmedConcepts: confirmedConcepts ?? this.confirmedConcepts,
      triageLevel: triageLevel ?? this.triageLevel,
      startedAt: startedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      referralGenerated: referralGenerated ?? this.referralGenerated,
      slipFilePath: slipFilePath ?? this.slipFilePath,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_code': sessionCode,
    'asha_worker_name': ashaWorkerName,
    'patient_name': patientName,
    'patient_gender': patientGender,
    'patient_contact': patientContact,
    'patient_age_group': patientAgeGroup?.name,
    'symptom_duration': symptomDuration?.name,
    'transcribed_text': transcribedText,
    'confirmed_concepts': confirmedConcepts.join('||'),
    'triage_level': triageLevel,
    'started_at': startedAt.toIso8601String(),
    'is_completed': isCompleted ? 1 : 0,
    'referral_generated': referralGenerated ? 1 : 0,
    'slip_file_path': slipFilePath,
  };

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
    id: map['id'],
    sessionCode: map['session_code'],
    ashaWorkerName: map['asha_worker_name'],
    patientName: map['patient_name'],
    patientGender: map['patient_gender'],
    patientContact: map['patient_contact'],
    patientAgeGroup: map['patient_age_group'] != null
        ? AgeGroup.values.firstWhere((e) => e.name == map['patient_age_group'])
        : null,
    symptomDuration: map['symptom_duration'] != null
        ? SymptomDuration.values.firstWhere((e) => e.name == map['symptom_duration'])
        : null,
    transcribedText: map['transcribed_text'] ?? '',
    confirmedConcepts: (map['confirmed_concepts'] as String?)?.split('||').where((s) => s.isNotEmpty).toList() ?? [],
    triageLevel: map['triage_level'] ?? 'GREEN',
    startedAt: DateTime.parse(map['started_at']),
    isCompleted: map['is_completed'] == 1,
    referralGenerated: map['referral_generated'] == 1,
    slipFilePath: map['slip_file_path'],
  );
}
