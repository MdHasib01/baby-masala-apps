import '../../core/utils/json.dart';

/// Category ids accepted by the API (`COMPLAINT_CATEGORIES` in the backend) → Bengali label.
const complaintCategories = {
  'order': 'অর্ডার ও ডেলিভারি',
  'product': 'প্রোডাক্টের মান',
  'payment': 'পেমেন্ট ও পয়েন্ট',
  'app': 'অ্যাপের সমস্যা',
  'community': 'কমিউনিটি / কোনো ইউজার',
  'other': 'অন্যান্য',
};

/// Status id → Bengali label.
const complaintStatuses = {
  'open': 'গ্রহণ করা হয়েছে',
  'in_progress': 'প্রক্রিয়াধীন',
  'resolved': 'সমাধান হয়েছে',
};

class Complaint {
  const Complaint({
    required this.id,
    required this.category,
    required this.details,
    required this.status,
    this.userName = '',
    this.userContact = '',
    this.attachmentUrl,
    this.adminReply = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  final String id;
  final String category;
  final String details;
  final String status; // open | in_progress | resolved
  final String userName;
  final String userContact;
  final String? attachmentUrl;
  final String adminReply;
  final String createdAt; // Bengali relative label
  final String updatedAt;

  String get categoryLabel => complaintCategories[category] ?? category;
  String get statusLabel => complaintStatuses[status] ?? status;

  factory Complaint.fromJson(Json j) => Complaint(
        id: jStr(j, 'id'),
        category: jStr(j, 'category', 'other'),
        details: jStr(j, 'details'),
        status: jStr(j, 'status', 'open'),
        userName: jStr(j, 'userName'),
        userContact: jStr(j, 'userContact'),
        attachmentUrl: jStrN(j, 'attachmentUrl'),
        adminReply: jStr(j, 'adminReply'),
        createdAt: jStr(j, 'createdAt'),
        updatedAt: jStr(j, 'updatedAt'),
      );
}
