import 'package:uuid/uuid.dart';

enum AgeGroup { child, youth, adult, elderly }
enum SymptomDuration { today, twothreedays, fourplus }

extension AgeGroupLabel on AgeGroup {
  String labelForLang(String lang) {
    if (lang == 'hi') return hindi;
    if (lang == 'mr') {
      switch (this) {
        case AgeGroup.child:   return 'लहान मूल';
        case AgeGroup.youth:   return 'तरुण';
        case AgeGroup.adult:   return 'प्रौढ';
        case AgeGroup.elderly: return 'वृद्ध';
      }
    }
    switch (this) {
      case AgeGroup.child:   return 'Child';
      case AgeGroup.youth:   return 'Youth';
      case AgeGroup.adult:   return 'Adult';
      case AgeGroup.elderly: return 'Elderly';
    }
  }

  String get hindi {
    switch (this) {
      case AgeGroup.child:   return 'बच्चा';
      case AgeGroup.youth:   return 'युवा';
      case AgeGroup.adult:   return 'वयस्क';
      case AgeGroup.elderly: return 'बुजुर्ग';
    }
  }
}

extension SymptomDurationLabel on SymptomDuration {
  String labelForLang(String lang) {
    if (lang == 'hi') return hindi;
    if (lang == 'mr') {
      switch (this) {
        case SymptomDuration.today:        return 'आज';
        case SymptomDuration.twothreedays: return '२-३ दिवस';
        case SymptomDuration.fourplus:     return '४+ दिवस';
      }
    }
    switch (this) {
      case SymptomDuration.today:        return 'Today';
      case SymptomDuration.twothreedays: return '2-3 Days';
      case SymptomDuration.fourplus:     return '4+ Days';
    }
  }

  String get hindi {
    switch (this) {
      case SymptomDuration.today:        return 'आज';
      case SymptomDuration.twothreedays: return '2-3 दिन';
      case SymptomDuration.fourplus:     return '4+ दिन';
    }
  }
}

class SessionModel {
  final String id;
  final String sessionCode;
  final String ashaWorkerName;
  final AgeGroup? patientAgeGroup;
  final SymptomDuration? symptomDuration;
  final String? transcribedText;
  final String? confirmedConcepts;
  final String? triageLevel;
  final DateTime startedAt;
  final bool isCompleted;
  final bool referralGenerated;

  SessionModel({
    String? id,
    String? sessionCode,
    required this.ashaWorkerName,
    this.patientAgeGroup,
    this.symptomDuration,
    this.transcribedText,
    this.confirmedConcepts,
    this.triageLevel,
    DateTime? startedAt,
    this.isCompleted = false,
    this.referralGenerated = false,
  })  : id = id ?? const Uuid().v4(),
        sessionCode = sessionCode ?? _generateSessionCode(),
        startedAt = startedAt ?? DateTime.now();

  static String _generateSessionCode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final code = (now % 900000) + 100000;
    return code.toString();
  }

  SessionModel copyWith({
    String? ashaWorkerName,
    AgeGroup? patientAgeGroup,
    SymptomDuration? symptomDuration,
    String? transcribedText,
    String? confirmedConcepts,
    String? triageLevel,
    bool? isCompleted,
    bool? referralGenerated,
  }) {
    return SessionModel(
      id: id,
      sessionCode: sessionCode,
      ashaWorkerName: ashaWorkerName ?? this.ashaWorkerName,
      patientAgeGroup: patientAgeGroup ?? this.patientAgeGroup,
      symptomDuration: symptomDuration ?? this.symptomDuration,
      transcribedText: transcribedText ?? this.transcribedText,
      confirmedConcepts: confirmedConcepts ?? this.confirmedConcepts,
      triageLevel: triageLevel ?? this.triageLevel,
      startedAt: startedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      referralGenerated: referralGenerated ?? this.referralGenerated,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'session_code': sessionCode,
    'asha_worker_name': ashaWorkerName,
    'patient_age_group': patientAgeGroup?.name,
    'symptom_duration': symptomDuration?.name,
    'transcribed_text': transcribedText,
    'confirmed_concepts': confirmedConcepts,
    'triage_level': triageLevel,
    'started_at': startedAt.toIso8601String(),
    'is_completed': isCompleted ? 1 : 0,
    'referral_generated': referralGenerated ? 1 : 0,
  };

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
    id: map['id'],
    sessionCode: map['session_code'],
    ashaWorkerName: map['asha_worker_name'],
    patientAgeGroup: map['patient_age_group'] != null
        ? AgeGroup.values.firstWhere((e) => e.name == map['patient_age_group'])
        : null,
    symptomDuration: map['symptom_duration'] != null
        ? SymptomDuration.values.firstWhere((e) => e.name == map['symptom_duration'])
        : null,
    transcribedText: map['transcribed_text'],
    confirmedConcepts: map['confirmed_concepts'],
    triageLevel: map['triage_level'],
    startedAt: DateTime.parse(map['started_at']),
    isCompleted: map['is_completed'] == 1,
    referralGenerated: map['referral_generated'] == 1,
  );
}
