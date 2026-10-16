import '../../core/utils/json.dart';

class ContestWinner {
  const ContestWinner({required this.name, required this.prize});
  final String name;
  final String prize;
  factory ContestWinner.fromJson(Json j) => ContestWinner(name: jStr(j, 'name'), prize: jStr(j, 'prize'));
}

class Contest {
  const Contest({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.eligibility,
    required this.startDate,
    required this.endDate,
    required this.prize,
    this.pointsReward,
    required this.status,
    this.winners = const [],
  });

  /// Default reward when a contest has no `pointsReward` (backend routes/rewards.js).
  static const defaultPointsReward = 50;

  final String id;
  final String title;
  final String type; // 'recipe_video' | 'review'
  final String description;
  final String eligibility; // 'all' | 'delivered_order'
  final String startDate;
  final String endDate;
  final String prize;
  final int? pointsReward;
  final String status; // 'active' | 'ended'
  final List<ContestWinner> winners;

  int get reward => pointsReward ?? defaultPointsReward;
  bool get needsDeliveredOrder => eligibility == 'delivered_order';

  factory Contest.fromJson(Json j) => Contest(
        id: jStr(j, 'id'),
        title: jStr(j, 'title'),
        type: jStr(j, 'type'),
        description: jStr(j, 'description'),
        eligibility: jStr(j, 'eligibility', 'all'),
        startDate: jStr(j, 'startDate'),
        endDate: jStr(j, 'endDate'),
        prize: jStr(j, 'prize'),
        pointsReward: jIntN(j, 'pointsReward'),
        status: jStr(j, 'status', 'active'),
        winners: jList(j, 'winners', ContestWinner.fromJson),
      );
}

class ContestSubmission {
  const ContestSubmission({
    required this.id,
    required this.contestId,
    required this.userName,
    required this.mediaUrl,
    required this.description,
    required this.status,
    required this.createdAt,
    this.orderId,
  });

  final String id;
  final String contestId;
  final String userName;
  final String mediaUrl;
  final String description;
  final String status; // pending | approved | rejected
  final String createdAt;
  final String? orderId;

  factory ContestSubmission.fromJson(Json j) => ContestSubmission(
        id: jStr(j, 'id'),
        contestId: jStr(j, 'contestId'),
        userName: jStr(j, 'userName'),
        mediaUrl: jStr(j, 'mediaUrl'),
        description: jStr(j, 'description'),
        status: jStr(j, 'status', 'pending'),
        createdAt: jStr(j, 'createdAt'),
        orderId: jStrN(j, 'orderId'),
      );
}
