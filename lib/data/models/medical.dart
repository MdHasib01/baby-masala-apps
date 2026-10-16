import '../../core/utils/json.dart';

/// Child — client-owned, synced with `PUT /api/sync/children`.
class Child {
  const Child({required this.id, required this.name, required this.dob, this.photo, this.allergies});

  final String id;
  final String name;
  final String dob; // YYYY-MM-DD
  final String? photo;
  final String? allergies;

  factory Child.fromJson(Json j) => Child(
        id: jStr(j, 'id'),
        name: jStr(j, 'name'),
        dob: jStr(j, 'dob'),
        photo: jStrN(j, 'photo'),
        allergies: jStrN(j, 'allergies'),
      );

  Json toJson() => compact({'id': id, 'name': name, 'dob': dob, 'photo': photo, 'allergies': allergies});
}

class Doctor {
  const Doctor({
    required this.id,
    required this.name,
    required this.avatar,
    required this.specialty,
    this.languages = const [],
    this.experience = '',
    this.feePlaceholder = '',
    this.demoTimeSlots = const [],
    this.demoQualifications = '',
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String avatar;
  final String specialty;
  final List<String> languages;
  final String experience;
  final String feePlaceholder;
  final List<String> demoTimeSlots;
  final String demoQualifications;
  final bool isAvailable;

  factory Doctor.fromJson(Json j) => Doctor(
        id: jStr(j, 'id'),
        name: jStr(j, 'name'),
        avatar: jStr(j, 'avatar'),
        specialty: jStr(j, 'specialty'),
        languages: jStrList(j, 'languages'),
        experience: jStr(j, 'experience'),
        feePlaceholder: jStr(j, 'feePlaceholder'),
        demoTimeSlots: jStrList(j, 'demoTimeSlots'),
        demoQualifications: jStr(j, 'demoQualifications'),
        isAvailable: jBool(j, 'isAvailable', true),
      );
}

class FollowUp {
  const FollowUp({required this.sender, required this.text, required this.time});
  final String sender; // 'user' | 'doctor'
  final String text;
  final String time;

  factory FollowUp.fromJson(Json j) => FollowUp(sender: jStr(j, 'sender'), text: jStr(j, 'text'), time: jStr(j, 'time'));
  Json toJson() => {'sender': sender, 'text': text, 'time': time};
}

/// Allowed statuses (backend enum, Bengali).
const dqSubmitted = 'জমা হয়েছে';
const dqWaiting = 'উত্তর অপেক্ষায়';
const dqAnswered = 'উত্তর এসেছে';
const dqClosed = 'বন্ধ হয়েছে';

/// DoctorQuestion — client-owned, synced with `PUT /api/sync/doctorQuestions`.
class DoctorQuestion {
  const DoctorQuestion({
    required this.id,
    required this.childNameOrGeneral,
    required this.category,
    required this.title,
    required this.detailedQuestion,
    this.attachmentUrl,
    required this.status,
    required this.submissionDate,
    this.assignedDoctorName,
    this.sampleReply,
    this.followUpQuestions = const [],
    this.isPrivate = true,
  });

  final String id;
  final String childNameOrGeneral;
  final String category;
  final String title;
  final String detailedQuestion;
  final String? attachmentUrl;
  final String status;
  final String submissionDate;
  final String? assignedDoctorName;
  final String? sampleReply;
  final List<FollowUp> followUpQuestions;
  final bool isPrivate;

  factory DoctorQuestion.fromJson(Json j) => DoctorQuestion(
        id: jStr(j, 'id'),
        childNameOrGeneral: jStr(j, 'childNameOrGeneral'),
        category: jStr(j, 'category'),
        title: jStr(j, 'title'),
        detailedQuestion: jStr(j, 'detailedQuestion'),
        attachmentUrl: jStrN(j, 'attachmentUrl'),
        status: jStr(j, 'status', dqSubmitted),
        submissionDate: jStr(j, 'submissionDate'),
        assignedDoctorName: jStrN(j, 'assignedDoctorName'),
        sampleReply: jStrN(j, 'sampleReply'),
        followUpQuestions: jList(j, 'followUpQuestions', FollowUp.fromJson),
        isPrivate: jBool(j, 'isPrivate', true),
      );

  Json toJson() => compact({
        'id': id,
        'childNameOrGeneral': childNameOrGeneral,
        'category': category,
        'title': title,
        'detailedQuestion': detailedQuestion,
        'attachmentUrl': attachmentUrl,
        'status': status,
        'submissionDate': submissionDate,
        'assignedDoctorName': assignedDoctorName,
        'sampleReply': sampleReply,
        'followUpQuestions': followUpQuestions.map((f) => f.toJson()).toList(),
        'isPrivate': isPrivate,
      });

  DoctorQuestion copyWith({List<FollowUp>? followUpQuestions, String? status}) => DoctorQuestion(
        id: id,
        childNameOrGeneral: childNameOrGeneral,
        category: category,
        title: title,
        detailedQuestion: detailedQuestion,
        attachmentUrl: attachmentUrl,
        status: status ?? this.status,
        submissionDate: submissionDate,
        assignedDoctorName: assignedDoctorName,
        sampleReply: sampleReply,
        followUpQuestions: followUpQuestions ?? this.followUpQuestions,
        isPrivate: isPrivate,
      );
}
