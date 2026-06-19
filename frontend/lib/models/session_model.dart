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
  final String ashaWorkerName;
  final AgeGroup? patientAgeGroup;
  final SymptomDuration? symptomDuration;
  final String? transcribedText;
  final DateTime startedAt;
  final bool isCompleted;

  SessionModel({
    String? id,
    required this.ashaWorkerName,
    this.patientAgeGroup,
    this.symptomDuration,
    this.transcribedText,
    DateTime? startedAt,
    this.isCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        startedAt = startedAt ?? DateTime.now();

  SessionModel copyWith({
    String? ashaWorkerName,
    AgeGroup? patientAgeGroup,
    SymptomDuration? symptomDuration,
    String? transcribedText,
    bool? isCompleted,
  }) {
    return SessionModel(
      id: id,
      ashaWorkerName: ashaWorkerName ?? this.ashaWorkerName,
      patientAgeGroup: patientAgeGroup ?? this.patientAgeGroup,
      symptomDuration: symptomDuration ?? this.symptomDuration,
      transcribedText: transcribedText ?? this.transcribedText,
      startedAt: startedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'asha_worker_name': ashaWorkerName,
    'patient_age_group': patientAgeGroup?.name,
    'symptom_duration': symptomDuration?.name,
    'transcribed_text': transcribedText,
    'started_at': startedAt.toIso8601String(),
    'is_completed': isCompleted ? 1 : 0,
  };

  factory SessionModel.fromMap(Map<String, dynamic> map) => SessionModel(
    id: map['id'],
    ashaWorkerName: map['asha_worker_name'],
    patientAgeGroup: map['patient_age_group'] != null
        ? AgeGroup.values.firstWhere((e) => e.name == map['patient_age_group'])
        : null,
    symptomDuration: map['symptom_duration'] != null
        ? SymptomDuration.values.firstWhere((e) => e.name == map['symptom_duration'])
        : null,
    transcribedText: map['transcribed_text'],
    startedAt: DateTime.parse(map['started_at']),
    isCompleted: map['is_completed'] == 1,
  );
}
