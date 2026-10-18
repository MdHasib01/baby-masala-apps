import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/bn_digits.dart';
import '../../data/models/medical.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/net_image.dart';
import '../../state/app_data.dart';
import '../../state/app_data_controller.dart';

/// Port of components/doctor/AskDoctorScreen.tsx.
/// Questions are a client-owned list synced with `PUT /sync/doctorQuestions`.
class AskDoctorScreen extends ConsumerStatefulWidget {
  const AskDoctorScreen({super.key});

  @override
  ConsumerState<AskDoctorScreen> createState() => _AskDoctorScreenState();
}

class _AskDoctorScreenState extends ConsumerState<AskDoctorScreen> {
  String _tab = 'live';

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(dataProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('ডাক্তারকে জিজ্ঞেস করুন')),
      body: Column(children: [
        Container(
          color: Colors.white,
          child: Row(children: [
            _tabBtn('live', 'লাইভ ডাক্তার'),
            _tabBtn('leave_question', 'প্রশ্ন রেখে দিন (${toBnDigits(d.doctorQuestions.length)})'),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.maroon,
            onRefresh: () => ref.read(appDataProvider.notifier).refresh(),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              const InfoBox(
                'জরুরি চিকিৎসার জন্য এই সেবার অপেক্ষা করবেন না। যেকোনো জরুরি পরিস্থিতিতে অবিলম্বে নিকটস্থ হাসপাতালে যোগাযোগ করুন।',
                bg: AppColors.red50,
                fg: AppColors.red600,
              ),
              const SizedBox(height: 14),
              if (_tab == 'live') ..._live(d.doctors) else ..._questions(d),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _tabBtn(String id, String label) => Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: _tab == id ? AppColors.maroon : Colors.transparent, width: 3)),
            ),
            alignment: Alignment.center,
            child: Text(label, style: ts(12.5, weight: bold, color: _tab == id ? AppColors.maroon : AppColors.grey500)),
          ),
        ),
      );

  // --------------------------------------------------------------- live --
  List<Widget> _live(List<Doctor> doctors) => [
        Text('উপলব্ধ শিশু বিশেষজ্ঞগণ', style: ts(14, weight: bold, color: AppColors.maroon)),
        const SizedBox(height: 10),
        for (final doc in doctors)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Stack(children: [
                  AppAvatar(doc.avatar, size: 54),
                  if (doc.isAvailable)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: AppColors.green700, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      ),
                    ),
                ]),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doc.name, style: ts(13, weight: bold)),
                    Text(doc.specialty, style: ts(11.5, color: AppColors.olive, weight: semi)),
                    Text('${doc.experience} · ভাষা: ${doc.languages.join(', ')}', style: ts(10.5, color: AppColors.grey500)),
                  ]),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), textStyle: ts(11.5, weight: bold)),
                  onPressed: () => _book(doc),
                  child: const Text('কনসালটেশন'),
                ),
              ]),
            ),
          ),
      ];

  Future<void> _book(Doctor doc) async {
    final go = await showAppSheet<bool>(context, title: 'ডাক্তার কনসালটেশন', builder: (_) => _BookingFlow(doctor: doc));
    if (go != true || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => _WaitingRoom(doctor: doc)));
  }

  // ---------------------------------------------------------- questions --
  List<Widget> _questions(AppData d) => [
        const _QuestionForm(),
        const SizedBox(height: 16),
        Text('আমার প্রশ্ন ও উত্তরসমূহ', style: ts(14, weight: bold, color: AppColors.maroon)),
        const SizedBox(height: 10),
        if (d.doctorQuestions.isEmpty)
          Text('এখনো কোনো প্রশ্ন জমা দেওয়া হয়নি।', style: ts(12, color: AppColors.grey500)),
        for (final q in d.doctorQuestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(12),
              onTap: () => showAppSheet<void>(context, title: 'প্রশ্নের বিস্তারিত', builder: (_) => _QuestionDetail(questionId: q.id)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Tag(q.category, bg: AppColors.cream),
                  const Spacer(),
                  Tag(
                    q.status,
                    bg: q.status == dqAnswered ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
                    fg: q.status == dqAnswered ? const Color(0xFF166534) : const Color(0xFF854D0E),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(q.title, style: ts(13, weight: bold)),
                const SizedBox(height: 2),
                Text('${q.submissionDate} · ${q.childNameOrGeneral}', style: ts(10.5, color: AppColors.grey500)),
              ]),
            ),
          ),
      ];
}

class _QuestionForm extends ConsumerStatefulWidget {
  const _QuestionForm();

  @override
  ConsumerState<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends ConsumerState<_QuestionForm> {
  static const _categories = ['খাবার ও পুষ্টি', 'ঘুম ও রুটিন', 'বিকাশ ও স্বাস্থ্য'];
  late String _child = 'সাধারণ প্রশ্ন';
  String _category = _categories.first;
  final _title = TextEditingController();
  final _details = TextEditingController();
  bool _success = false;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _details.text.trim().isEmpty) {
      toast(context, 'শিরোনাম ও বিস্তারিত বিবরণ লিখুন।');
      return;
    }
    // Pull the latest list first so a question asked on the web isn't dropped.
    await ref.read(appDataProvider.notifier).refreshQuietly();
    final list = ref.read(dataProvider).doctorQuestions;
    ref.read(appDataProvider.notifier).setDoctorQuestions([
      DoctorQuestion(
        id: 'q-${DateTime.now().millisecondsSinceEpoch}',
        childNameOrGeneral: _child,
        category: _category,
        title: _title.text.trim(),
        detailedQuestion: _details.text.trim(),
        status: dqWaiting,
        submissionDate: 'আজ',
        isPrivate: true,
      ),
      ...list,
    ]);
    _title.clear();
    _details.clear();
    setState(() => _success = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _success = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(dataProvider.select((d) => d.children));
    final childOptions = ['সাধারণ প্রশ্ন', for (final c in children) '${c.name} (${c.dob})'];
    if (!childOptions.contains(_child)) _child = childOptions.first;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('নতুন প্রশ্ন লিখে পাঠান', style: ts(14, weight: bold, color: AppColors.maroon)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('সন্তান বা সাধারণ'),
              DropdownButtonFormField<String>(
                initialValue: _child,
                isExpanded: true,
                items: [
                  for (final o in childOptions)
                    DropdownMenuItem(value: o, child: Text(o.split(' (').first, style: ts(12.5), overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _child = v ?? _child),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const FieldLabel('বিভাগ'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c, style: ts(12.5)))],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        const FieldLabel('প্রশ্নের শিরোনাম'),
        TextField(controller: _title, maxLength: 300, decoration: const InputDecoration(hintText: 'সংক্ষেপে আপনার প্রশ্নটি লিখুন...', counterText: '')),
        const SizedBox(height: 8),
        const FieldLabel('বিস্তারিত বিবরণ'),
        TextField(
          controller: _details,
          minLines: 3,
          maxLines: 6,
          maxLength: 5000,
          decoration: const InputDecoration(hintText: 'বিস্তারিত লক্ষণ বা প্রশ্ন...', counterText: ''),
        ),
        if (_success) ...[
          const SizedBox(height: 10),
          const InfoBox('প্রশ্ন সফলভাবে জমা হয়েছে!', icon: LucideIcons.circleCheck, bg: AppColors.green50, fg: AppColors.green700),
        ],
        const SizedBox(height: 12),
        BusyButton(label: 'প্রশ্ন জমা দিন (গোপনীয়)', icon: LucideIcons.lock, onPressed: _submit),
      ]),
    );
  }
}

class _QuestionDetail extends ConsumerStatefulWidget {
  const _QuestionDetail({required this.questionId});
  final String questionId;

  @override
  ConsumerState<_QuestionDetail> createState() => _QuestionDetailState();
}

class _QuestionDetailState extends ConsumerState<_QuestionDetail> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final list = ref.read(dataProvider).doctorQuestions;
    ref.read(appDataProvider.notifier).setDoctorQuestions([
      for (final q in list)
        q.id == widget.questionId
            ? q.copyWith(followUpQuestions: [...q.followUpQuestions, FollowUp(sender: 'user', text: text, time: 'এইমাত্র')])
            : q,
    ]);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(dataProvider.select((d) => d.doctorQuestions.where((x) => x.id == widget.questionId).firstOrNull));
    if (q == null) return const SizedBox(height: 60);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(alignment: Alignment.centerLeft, child: Tag(q.category, bg: AppColors.cream)),
      const SizedBox(height: 8),
      Text(q.title, style: ts(15, weight: bold, color: AppColors.maroon)),
      const SizedBox(height: 6),
      Text(q.detailedQuestion, style: ts(12.5, height: 1.6)),
      const SizedBox(height: 6),
      Text('জমাদানের তারিখ: ${q.submissionDate}', style: ts(10.5, color: AppColors.grey500)),
      if (q.sampleReply != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${q.assignedDoctorName ?? 'ডাক্তার'}-এর উত্তর:', style: ts(11.5, weight: bold, color: AppColors.green700)),
            const SizedBox(height: 4),
            Text(q.sampleReply!, style: ts(12.5, height: 1.5)),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      for (final f in q.followUpQuestions)
        Align(
          alignment: f.sender == 'user' ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: f.sender == 'user' ? AppColors.maroon : AppColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.sender == 'user' ? 'আপনি' : 'ডাক্তার',
                  style: ts(10, weight: bold, color: f.sender == 'user' ? AppColors.sand : AppColors.olive)),
              Text(f.text, style: ts(12.5, color: f.sender == 'user' ? Colors.white : AppColors.ink)),
            ]),
          ),
        ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _text,
            onSubmitted: (_) => _send(),
            decoration: const InputDecoration(hintText: 'ফলো-আপ প্রশ্ন লিখুন...'),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: AppColors.maroon),
          onPressed: _send,
          icon: const Icon(LucideIcons.send, size: 18, color: Colors.white),
        ),
      ]),
    ]);
  }
}

/// profile → select_child → reason → confirmation (web booking modal).
/// Pops `true` when the user enters the waiting room.
class _BookingFlow extends ConsumerStatefulWidget {
  const _BookingFlow({required this.doctor});
  final Doctor doctor;

  @override
  ConsumerState<_BookingFlow> createState() => _BookingFlowState();
}

class _BookingFlowState extends ConsumerState<_BookingFlow> {
  String _step = 'profile';
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;
    final children = ref.watch(dataProvider.select((d) => d.children));
    switch (_step) {
      case 'profile':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            AppAvatar(doc.avatar, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(doc.name, style: ts(15, weight: bold)),
                Text(doc.specialty, style: ts(12, color: AppColors.olive, weight: semi)),
                Text(doc.experience, style: ts(11, color: AppColors.grey500)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('যোগ্যতা:', style: ts(11.5, weight: bold, color: AppColors.maroon)),
              Text(doc.demoQualifications, style: ts(12, height: 1.5)),
              const SizedBox(height: 8),
              Text('কনসালটেশন ফি:', style: ts(11.5, weight: bold, color: AppColors.maroon)),
              Text(doc.feePlaceholder, style: ts(12)),
            ]),
          ),
          const SizedBox(height: 14),
          BusyButton(label: 'তাৎক্ষণিক কনসালটেশন শুরু করুন', onPressed: () async => setState(() => _step = 'select_child')),
        ]);
      case 'select_child':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('কার জন্য পরামর্শ নিতে চান?', style: ts(14, weight: bold)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => setState(() => _step = 'reason'), child: const Text('সাধারণ প্রশ্ন / নিজের জন্য')),
          for (final c in children) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.baby, size: 16),
              onPressed: () => setState(() => _step = 'reason'),
              label: Text('সন্তান: ${c.name}'),
            ),
          ],
        ]);
      case 'reason':
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('কনসালটেশনের কারণ লিখুন', style: ts(14, weight: bold)),
          const SizedBox(height: 10),
          TextField(controller: _reason, minLines: 3, maxLines: 5, decoration: const InputDecoration(hintText: 'যেমন: জ্বর বা ঘুমের সমস্যা...')),
          const SizedBox(height: 12),
          BusyButton(
            label: 'পরবর্তী ধাপ',
            onPressed: () async {
              if (_reason.text.trim().isEmpty) return;
              setState(() => _step = 'confirmation');
            },
          ),
        ]);
      default:
        return Column(children: [
          const Icon(LucideIcons.circleCheck, size: 56, color: AppColors.green700),
          const SizedBox(height: 10),
          Text('কনসালটেশন বুকিং নিশ্চিত হয়েছে', style: ts(15, weight: bold, color: AppColors.maroon)),
          const SizedBox(height: 4),
          Text('${doc.name} এর সাথে সংযোগের জন্য প্রস্তুত।', textAlign: TextAlign.center, style: ts(12.5, color: AppColors.grey600)),
          const SizedBox(height: 14),
          BusyButton(label: 'ওয়েটিং রুমে প্রবেশ করুন', onPressed: () async => Navigator.pop(context, true)),
        ]);
    }
  }
}

class _WaitingRoom extends StatelessWidget {
  const _WaitingRoom({required this.doctor});
  final Doctor doctor;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                child: const Icon(LucideIcons.video, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text('ডাক্তার কনসালটেশন ওয়েটিং রুম', textAlign: TextAlign.center, style: ts(18, weight: bold, color: AppColors.maroon)),
              const SizedBox(height: 8),
              Text('${doctor.name}-এর সাথে আপনার ভিডিও কল সংযোগ স্থাপন করা হচ্ছে...',
                  textAlign: TextAlign.center, style: ts(13, color: AppColors.grey600)),
              const SizedBox(height: 16),
              const LinearProgressIndicator(color: AppColors.maroon, backgroundColor: AppColors.sand),
              const SizedBox(height: 16),
              Text('জরুরি চিকিৎসার জন্য এই সেবার অপেক্ষা করবেন না।', style: ts(11, color: AppColors.red600)),
              const SizedBox(height: 24),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('বাতিল')),
            ]),
          ),
        ),
      );
}
