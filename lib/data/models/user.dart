import '../../core/utils/json.dart';

/// Mirrors `User` in frontend/src/types.ts and `serializeUser` in
/// backend/src/services/serializers.js.
class Address {
  const Address({
    required this.id,
    required this.title,
    required this.details,
    required this.phone,
    required this.isDefault,
  });

  final String id;
  final String title;
  final String details;
  final String phone;
  final bool isDefault;

  factory Address.fromJson(Json j) => Address(
        id: jStr(j, 'id'),
        title: jStr(j, 'title'),
        details: jStr(j, 'details'),
        phone: jStr(j, 'phone'),
        isDefault: jBool(j, 'isDefault'),
      );

  Json toJson() => {'id': id, 'title': title, 'details': details, 'phone': phone, 'isDefault': isDefault};

  Address copyWith({String? title, String? details, String? phone, bool? isDefault}) => Address(
        id: id,
        title: title ?? this.title,
        details: details ?? this.details,
        phone: phone ?? this.phone,
        isDefault: isDefault ?? this.isDefault,
      );

  /// One-line label used to pre-fill shipping / delivery addresses.
  String get fullText => [title, details, phone].where((s) => s.trim().isNotEmpty).join(', ');
}

class NotificationPrefs {
  const NotificationPrefs({this.push = true, this.sms = true, this.email = false, this.communityAlerts = true});

  final bool push;
  final bool sms;
  final bool email;
  final bool communityAlerts;

  factory NotificationPrefs.fromJson(Json j) => NotificationPrefs(
        push: jBool(j, 'push', true),
        sms: jBool(j, 'sms', true),
        email: jBool(j, 'email'),
        communityAlerts: jBool(j, 'communityAlerts', true),
      );

  Json toJson() => {'push': push, 'sms': sms, 'email': email, 'communityAlerts': communityAlerts};

  NotificationPrefs copyWith({bool? push, bool? sms, bool? email, bool? communityAlerts}) => NotificationPrefs(
        push: push ?? this.push,
        sms: sms ?? this.sms,
        email: email ?? this.email,
        communityAlerts: communityAlerts ?? this.communityAlerts,
      );
}

class PrivacySettings {
  const PrivacySettings({this.shareProfile = true, this.showChildrenInfo = true});

  final bool shareProfile;
  final bool showChildrenInfo;

  factory PrivacySettings.fromJson(Json j) => PrivacySettings(
        shareProfile: jBool(j, 'shareProfile', true),
        showChildrenInfo: jBool(j, 'showChildrenInfo', true),
      );

  Json toJson() => {'shareProfile': shareProfile, 'showChildrenInfo': showChildrenInfo};

  PrivacySettings copyWith({bool? shareProfile, bool? showChildrenInfo}) => PrivacySettings(
        shareProfile: shareProfile ?? this.shareProfile,
        showChildrenInfo: showChildrenInfo ?? this.showChildrenInfo,
      );
}

class User {
  const User({
    this.id,
    required this.name,
    required this.contact,
    this.contactMethod,
    this.role,
    this.isAdmin = false,
    this.bio,
    this.coverPhoto,
    this.earnedPoints = 0,
    this.spentPoints = 0,
    this.isVerified = false,
    this.isMember = false,
    this.membershipExpiry,
    this.couponUsed,
    this.avatar = '',
    this.addresses = const [],
    this.notificationPrefs = const NotificationPrefs(),
    this.privacySettings = const PrivacySettings(),
  });

  static const empty = User(name: '', contact: '');

  final String? id;
  final String name;
  final String contact;
  final String? contactMethod; // 'email' | 'whatsapp'
  final String? role; // 'member' | 'admin'
  final bool isAdmin;
  final String? bio;
  final String? coverPhoto;
  final int earnedPoints;
  final int spentPoints;
  final bool isVerified;
  final bool isMember;
  final String? membershipExpiry; // Bengali display string
  final String? couponUsed;
  final String avatar;
  final List<Address> addresses;
  final NotificationPrefs notificationPrefs;
  final PrivacySettings privacySettings;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
  Address? get defaultAddress =>
      addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;

  factory User.fromJson(Json j) => User(
        id: jStrN(j, 'id'),
        name: jStr(j, 'name'),
        contact: jStr(j, 'contact'),
        contactMethod: jStrN(j, 'contactMethod'),
        role: jStrN(j, 'role'),
        isAdmin: jBool(j, 'isAdmin') || j['role'] == 'admin',
        bio: jStrN(j, 'bio'),
        coverPhoto: jStrN(j, 'coverPhoto'),
        earnedPoints: jInt(j, 'earnedPoints'),
        spentPoints: jInt(j, 'spentPoints'),
        isVerified: jBool(j, 'isVerified'),
        isMember: jBool(j, 'isMember'),
        membershipExpiry: jStrN(j, 'membershipExpiry'),
        couponUsed: jStrN(j, 'couponUsed'),
        avatar: jStr(j, 'avatar'),
        addresses: jList(j, 'addresses', Address.fromJson),
        notificationPrefs: NotificationPrefs.fromJson(jMap(j, 'notificationPrefs')),
        privacySettings: PrivacySettings.fromJson(jMap(j, 'privacySettings')),
      );

  /// Body for `PATCH /api/me` — same fields as `babyCareService.updateProfile`.
  Json toProfilePatch() => compact({
        'name': name,
        'avatar': avatar,
        'bio': bio,
        'coverPhoto': coverPhoto,
        'addresses': addresses.map((a) => a.toJson()).toList(),
        'notificationPrefs': notificationPrefs.toJson(),
        'privacySettings': privacySettings.toJson(),
      });

  User copyWith({
    String? name,
    String? avatar,
    String? bio,
    String? coverPhoto,
    List<Address>? addresses,
    NotificationPrefs? notificationPrefs,
    PrivacySettings? privacySettings,
  }) =>
      User(
        id: id,
        name: name ?? this.name,
        contact: contact,
        contactMethod: contactMethod,
        role: role,
        isAdmin: isAdmin,
        bio: bio ?? this.bio,
        coverPhoto: coverPhoto ?? this.coverPhoto,
        earnedPoints: earnedPoints,
        spentPoints: spentPoints,
        isVerified: isVerified,
        isMember: isMember,
        membershipExpiry: membershipExpiry,
        couponUsed: couponUsed,
        avatar: avatar ?? this.avatar,
        addresses: addresses ?? this.addresses,
        notificationPrefs: notificationPrefs ?? this.notificationPrefs,
        privacySettings: privacySettings ?? this.privacySettings,
      );
}
