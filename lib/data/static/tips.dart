/// Port of `INITIAL_TIPS` (frontend/src/tabs/MyBabyTab.tsx) and the hard-coded
/// food chart meals. Not served by the backend — keep both copies in sync.
class TipItem {
  const TipItem({
    required this.id,
    required this.category,
    required this.title,
    required this.preview,
    required this.content,
    this.savedByDefault = false,
  });

  final String id;
  final String category; // খাবার | ঘুম | দৈনন্দিন যত্ন | বিকাশ
  final String title;
  final String preview;
  final String content;
  final bool savedByDefault;
}

const tipCategories = ['সব', 'খাবার', 'ঘুম', 'দৈনন্দিন যত্ন', 'বিকাশ'];

const tips = <TipItem>[
  TipItem(
    id: 'tip-1',
    category: 'খাবার',
    title: '৬ মাসের পর প্রথম কঠিন খাবার (সলিড ফুড) শুরু করার নিয়ম',
    preview: 'শিশুর ৬ মাস পূর্ণ হওয়ার পর বুকের দুধের পাশাপাশি নরম পিউরি ও চটকানো খাবার শুরু করুন...',
    content:
        'শিশুর ৬ মাস বয়স পূর্ণ হওয়ার পর মায়ের বুকের দুধের পাশাপাশি পুষ্টিকর সম্পূরক খাবার বা সলিড ফুড অত্যন্ত জরুরি। প্রথমে চালের সুজি, মিষ্টি কুমড়া সেদ্ধ বা ডালের পানি দিয়ে শুরু করতে পারেন। নতুন যেকোনো খাবার ৩ দিন পর্যন্ত একটানা খাইয়ে এলার্জি বা হজমের সমস্যা আছে কিনা তা পর্যবেক্ষণ করুন। চিনি ও লবণ এড়িয়ে চলুন।',
  ),
  TipItem(
    id: 'tip-2',
    category: 'ঘুম',
    title: 'শিশুর সুস্থ ঘুমের রুটিন তৈরি',
    preview: 'নিয়মিত ঘুমের সময় নির্ধারণ এবং রাতের ঘুমের পরিবেশ শান্ত রাখা শিশুর মস্তিষ্কের বিকাশে সাহায্য করে...',
    content:
        'নবজাতক ও শিশুদের সুস্থ বৃদ্ধির জন্য সঠিক ঘুম অপরিহার্য। প্রতিদিন একই সময়ে ঘুমানোর অভ্যাস করান এবং ঘুমানোর আগে ঘর অন্ধকার বা মৃদু আলো রাখুন। হালকা কুসুম গরম পানিতে গোসল বা মালিশ শিশুকে শান্ত করতে এবং দ্রুত ঘুমাতে সাহায্য করে।',
    savedByDefault: true,
  ),
  TipItem(
    id: 'tip-3',
    category: 'বিকাশ',
    title: 'বসা ও হামাগুড়ি দেওয়ার বয়সে শিশুর পরিচর্যা',
    preview: '৬ থেকে ৯ মাসের মধ্যে শিশুরা বসতে শেখে। এই সময়ে তাদের চারপাশের পরিবেশ নিরাপদ রাখা প্রয়োজন...',
    content:
        'শিশুরা যখন হামাগুড়ি দেওয়া শুরু করে, তখন ঘরের মেঝে পরিষ্কার রাখুন এবং ধারালো বস্তু দূরে রাখুন। তাদের সাথে খেলা করুন, কথা বলুন এবং বিভিন্ন রঙের খেলনা দিয়ে দৃষ্টি আকর্ষণ করুন যা তাদের মানসিক ও শারীরিক বিকাশকে ত্বরান্বিত করে।',
  ),
  TipItem(
    id: 'tip-4',
    category: 'দৈনন্দিন যত্ন',
    title: 'শিশুর ত্বক ও ডায়াপার র‌্যাশ রোধে করণীয়',
    preview: 'নরম শিশুর ত্বক খুব সংবেদনশীল। নিয়মিত ডায়াপার পরিবর্তন এবং বায়ু চলাচল নিশ্চিত করুন...',
    content:
        'ডায়াপার র‌্যাশ রোধ করতে প্রতি ৩-৪ ঘণ্টা পর পর ডায়াপার পরিবর্তন করুন এবং ত্বক পরিষ্কার করে ভালো মানের ময়েশ্চারাইজার বা পেট্রোলিয়াম জেলি ব্যবহার করুন। সম্ভব হলে কিছুক্ষণ ডায়াপার ছাড়া খোলা রাখুন যাতে বাতাস চলাচল করতে পারে।',
  ),
];

/// Food chart (MyBabyTab "foodChart" sub-view). Bangladesh week order.
const daysOfWeek = ['শনিবার', 'রবিবার', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার'];

class Meal {
  const Meal({required this.label, required this.time, required this.title, required this.note, required this.kind});
  final String label;
  final String time;
  final String title;
  final String note;
  final String kind; // breakfast | lunch | dinner
}

const foodChartMeals = <Meal>[
  Meal(
    kind: 'breakfast',
    label: 'সকালের নাস্তা',
    time: 'সকাল ৮:০০',
    title: 'চাল ও ডালের নরম সুজি / কলা চটকানো',
    note: 'পরিমাণ: ৩-৪ চা চামচ (হালকা উষ্ণ)',
  ),
  Meal(
    kind: 'lunch',
    label: 'দুপুরের খাবার',
    time: 'দুপুর ১:৩০',
    title: 'সবজি খিচুড়ি (মিষ্টি কুমড়া ও মুগ ডালসহ)',
    note: 'এক চিমটি বেবি বেসিল গুঁড়াসহ',
  ),
  Meal(
    kind: 'dinner',
    label: 'রাতের খাবার',
    time: 'রাত ৮:০০',
    title: 'নরম মিষ্টি আলুর পিউরি বা স্যুপ',
    note: 'সহজপাচ্য ও পুষ্টিকর',
  ),
];
