/// Port of `INITIAL_AGE_TIPS` (frontend/src/data/mockData.ts).
/// The backend does not serve this — keep both copies in sync (see MOBILE_SYNC.md).
class AgeTip {
  const AgeTip({
    required this.ageGroup,
    required this.title,
    required this.foodChart,
    required this.tips,
    required this.medicalDisclaimer,
  });

  final String ageGroup;
  final String title;
  final List<String> foodChart;
  final List<String> tips;
  final String medicalDisclaimer;
}

const _disclaimer = 'নোট: এই তথ্যগুলো সাধারণ গাইডলাইন মাত্র। শিশুর যেকোনো শারীরিক সমস্যায় চিকিৎসকের পরামর্শ নিন।';

const Map<String, AgeTip> ageTips = {
  'under_6m': AgeTip(
    ageGroup: 'under_6m',
    title: '৬ মাসের কম বয়সী শিশুর পরিচর্যা',
    foodChart: [
      'শুধুমাত্র মায়ের বুকের দুধ (এক্সক্লুসিভ ব্রেস্টফিডিং)।',
      'ডাক্তারের পরামর্শ ছাড়া পানি বা অন্য কোনো খাবার দেওয়া নিষেধ।',
    ],
    tips: [
      'প্রতি ২-৩ ঘণ্টা পর পর দুধ দিন।',
      'বাচ্চাকে ঢেকুর তোলা নিশ্চিত করুন।',
      'ঘর ঠান্ডা ও আরামদায়ক রাখুন।',
    ],
    medicalDisclaimer: _disclaimer,
  ),
  '6_8m': AgeTip(
    ageGroup: '6_8m',
    title: '৬ থেকে ৮ মাসের শিশুর পুষ্টি',
    foodChart: [
      'নরম পিউরি ও চটকানো খাবার (চাল, ডাল, মিষ্টি কুমড়া, কলা, আপেল)।',
      'প্রতিদিন ২ থেকে ৩ চা চামচ দিয়ে শুরু করুন।',
    ],
    tips: [
      'নতুন খাবার দেওয়ার পর ৩ দিন পর্যবেক্ষণ করুন।',
      'চিনি বা অতিরিক্ত লবণ একদম দেবেন না।',
      'বুকের দুধের পাশাপাশি সম্পূরক খাবার চালু রাখুন।',
    ],
    medicalDisclaimer: _disclaimer,
  ),
  '9_12m': AgeTip(
    ageGroup: '9_12m',
    title: '৯ থেকে ১২ মাসের শিশুর পুষ্টি',
    foodChart: [
      'সবজি খিচুড়ি, ডিমের কুসুম, মাছের নরম টুকরো, সুজি, পায়েস।',
      'দিন ৩-৪ বার অল্প পরিমাণে খাবার।',
    ],
    tips: [
      'শিশুকে নিজে হাতে খাবার ধরার সুযোগ দিন (ফিঙ্গার ফুড)।',
      'খাবারে বেবি মসলা হার্বস ব্যবহার করে স্বাদ বাড়ান।',
      'খাওয়ার পর পানি পানের অভ্যাস করান।',
    ],
    medicalDisclaimer: _disclaimer,
  ),
  '1_2y': AgeTip(
    ageGroup: '1_2y',
    title: '১ থেকে ২ বছরের শিশুর পুষ্টি',
    foodChart: [
      'পরিবারের সবার খাবার (কম ঝাল ও মসলাযুক্ত), ফলমূল, ডিম, মাংসের নরম টুকরো।',
      'গরুর দুধ ও দুগ্ধজাত খাবার।',
    ],
    tips: [
      'খাবারে বৈচিত্র্য আনুন যাতে অরুচি না হয়।',
      'নিয়মিত ঘুমের রুটিন বজায় রাখুন।',
      'বাইরে খেলাধুলার সুযোগ দিন।',
    ],
    medicalDisclaimer: _disclaimer,
  ),
  '2y_plus': AgeTip(
    ageGroup: '2y_plus',
    title: '২ বছর ও তদূর্ধ্ব শিশুর পরিচর্যা',
    foodChart: [
      'সুষম খাবার ও পুষ্টিকর টিফিন (ডিম, দুধ, সবজি, মাছ, মাংস, ডাল)।',
      'দৈনিক ৩ বেলা মূল খাবার ও ২ বেলা হালকা নাস্তা।',
    ],
    tips: [
      'খাওয়ার সময় মোবাইল বা স্ক্রিন দেওয়া থেকে বিরত থাকুন।',
      'ব্যক্তিগত পরিচ্ছন্নতা ও হাত ধোয়ার অভ্যাস শেখান।',
    ],
    medicalDisclaimer: _disclaimer,
  ),
};

AgeTip ageTipFor(String ageGroup) => ageTips[ageGroup] ?? ageTips['9_12m']!;
