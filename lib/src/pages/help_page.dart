import 'package:flutter/material.dart';
import 'package:garage_management_system/src/theme/app_theme.dart';
import 'package:garage_management_system/src/widgets/ui_components.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'സാരഥി ഗാരേജ് — ഉപയോഗിക്കുന്ന വിധം',
            subtitle: 'പ്രതിദിന വർക്ക്‌ഷോപ്പ് ജോലിക്കുള്ള ലളിതമായ ഗൈഡ്',
            icon: Icons.help_outline_rounded,
          ),
          SectionCard(
            title: 'പ്രതിദിന ജോലി — ചുരുക്കത്തിൽ',
            icon: Icons.route_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _flowStep(
                  number: '1',
                  title: 'പാർട്ടി + വാഹനം ചേർക്കുക',
                  body:
                      'പുതിയ ഉപഭോക്താവാണെങ്കിൽ പേര്, മൊബൈൽ, വിലാസം ചേർക്കുക. '
                      'അതിനുശേഷം വാഹന നമ്പർ, ബ്രാൻഡ്, മോഡൽ, വർഷം ചേർക്കുക (KM ഇവിടെ വേണ്ട).',
                  menu: 'Party',
                ),
                _flowArrow(),
                _flowStep(
                  number: '2',
                  title: 'ക്വിക്ക് ജോബ് കാർഡ്',
                  body:
                      'ഡാഷ്ബോർഡിൽ വാഹനം തിരഞ്ഞെടുത്ത് KM, മെക്കാനിക്, പരാതി നൽകി ജോബ് കാർഡ് തുറക്കുക. '
                      'സേവ് ചെയ്താൽ ജോബ് കാർഡ് പേജിലേക്ക് പോകും.',
                  menu: 'Dashboard',
                ),
                _flowArrow(),
                _flowStep(
                  number: '3',
                  title: 'എസ്റ്റിമേറ്റ് തയ്യാറാക്കുക',
                  body:
                      'ജോബ് കാർഡുകളിൽ **Create/Edit Estimate** അമർത്തുക. '
                      'ലേബർ, പാർട്സ് autocomplete ഉപയോഗിച്ച് ചേർത്ത് സേവ് ചെയ്യുക.',
                  menu: 'Job Cards',
                ),
                _flowArrow(),
                _flowStep(
                  number: '4',
                  title: 'എസ്റ്റിമേറ്റ് പ്രിന്റ് / എഡിറ്റ്',
                  body:
                      'എസ്റ്റിമേറ്റ് പേജിൽ പ്രിന്റ് ചെയ്ത് ഉപഭോക്താവിന് കാണിക്കുക. '
                      'വില മാറ്റണമെങ്കിൽ എഡിറ്റ് ചെയ്യാം.',
                  menu: 'Estimates',
                ),
                _flowArrow(),
                _flowStep(
                  number: '5',
                  title: 'ജോലി പൂർത്തിയാക്കുക',
                  body:
                      'ജോബ് കാർഡുകളിൽ **Mark Work Done** അമർത്തുക, '
                      'അല്ലെങ്കിൽ എസ്റ്റിമേറ്റ് പേജിൽ **Mark Job Done**.',
                  menu: 'Job Cards',
                ),
                _flowArrow(),
                _flowStep(
                  number: '6',
                  title: 'ഇൻവോയ്സാക്കി പണം വാങ്ങുക',
                  body:
                      'എസ്റ്റിമേറ്റ് പേജിൽ **Convert to Invoice** അമർത്തുക. '
                      'ഇൻവോയ്സ് പേജിൽ പ്രിന്റ് ചെയ്ത് പണം രേഖപ്പെടുത്തുക.',
                  menu: 'Invoices',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'മുകളിലെ സെർച്ച് ബാർ',
            icon: Icons.search_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'എല്ലാ പേജിലും മുകളിൽ വലതുവശത്ത് **വാഹന സെർച്ച്** ഉണ്ട്.',
                ),
                _HelpParagraph(
                  'വാഹന നമ്പർ, മൊബൈൽ, അല്ലെങ്കിൽ ഉടമയുടെ പേര് ടൈപ്പ് ചെയ്ത് ലിസ്റ്റിൽ നിന്ന് തിരഞ്ഞെടുക്കുക.',
                ),
                _HelpParagraph(
                  'തിരഞ്ഞെടുത്താൽ **History** പേജിലേക്ക് പോകും — ആ വാഹനത്തിന്റെ എല്ലാ ഇൻവോയ്സുകളും '
                  'ചെയ്ത ജോലികളുടെ വിവരങ്ങളും (ലേബർ, പാർട്സ്) കാണാം.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ഘട്ടം 1 — പാർട്ടി (ഉപഭോക്താവ്) + വാഹനം',
            icon: Icons.people_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'സൈഡ് മെനുവിൽ **Party** തുറക്കുക.',
                ),
                _HelpParagraph(
                  '**Add Party:** ഉടമയുടെ പേര്, 10 അക്ക മൊബൈൽ നമ്പർ, വിലാസം നൽകി **Add Party** അമർത്തുക.',
                ),
                _HelpParagraph(
                  '**Add Vehicle:** പാർട്ടി/ഉടമയുടെ പേര് autocomplete ഉപയോഗിച്ച് തിരഞ്ഞെടുക്കുക. '
                  'വാഹന നമ്പർ (ഉദാ: KL60K3139), ബ്രാൻഡ്, മോഡൽ, വർഷം നൽകി **Add Vehicle** അമർത്തുക.',
                ),
                _HelpTip(
                  'വാഹനം ചേർക്കുമ്പോൾ KM വേണ്ട — KM ഡാഷ്ബോർഡിലെ ക്വിക്ക് ജോബ് കാർഡിൽ നൽകാം.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ഘട്ടം 2 — ഡാഷ്ബോർഡ്',
            icon: Icons.dashboard_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  '**Quick Job Card:** വാഹന നമ്പർ autocomplete ഉപയോഗിച്ച് തിരഞ്ഞെടുക്കുക.',
                ),
                _HelpParagraph(
                  'KM, മെക്കാനിക് പേര്, പരാതി, ഫ്യൂവൽ ലെവൽ നൽകി ജോബ് കാർഡ് സൃഷ്ടിക്കുക.',
                ),
                _HelpParagraph(
                  'സേവ് ചെയ്താൽ സ്വയം **Job Cards** പേജിലേക്ക് പോകും.',
                ),
                _HelpParagraph(
                  'ഡാഷ്ബോർഡിൽ ഇന്നത്തെ വിൽപ്പന, മാസ വിൽപ്പന, തീർപ്പാക്കാത്ത പണം, '
                  'ലൈവ് ജോബ് കാർഡുകൾ, കുറഞ്ഞ സ്റ്റോക്ക്, ഓപ്പൺ എസ്റ്റിമേറ്റുകൾ എന്നിവ കാണാം.',
                ),
                _HelpParagraph(
                  '**Live Job Cards**, **Job Cards Today**, **Open Estimates** ടൈലുകൾ ക്ലിക്ക് ചെയ്താൽ '
                  'അനുയോജ്യമായ പേജിലേക്ക് പോകാം.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ഘട്ടം 3 — ജോബ് കാർഡുകൾ',
            icon: Icons.build_circle_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'ഇവിടെ **ലൈവ് (തുറന്ന) ജോബ് കാർഡുകൾ** മാത്രം കാണാം — പുതിയത് ഡാഷ്ബോർഡിൽ നിന്ന് തുറക്കുക.',
                ),
                _HelpParagraph(
                  'വാഹനം, ഉടമ, മൊബൈൽ, ജോബ് നമ്പർ എന്നിവ കൊണ്ട് സെർച്ച് ചെയ്യാം.',
                ),
                _HelpParagraph(
                  '**Create/Edit Estimate** — ലേബർ, പാർട്സ് autocomplete ഉപയോഗിച്ച് എസ്റ്റിമേറ്റ് തയ്യാറാക്കുക/മാറ്റുക.',
                ),
                _HelpParagraph(
                  '**Mark Work Done** — ജോലി പൂർത്തിയായാൽ സ്റ്റാറ്റസ് Completed ആക്കുക.',
                ),
                _HelpParagraph(
                  '**ജോബ് കാർഡ് സ്റ്റാറ്റസ്:**',
                ),
                _HelpBullet('Pending — ഇപ്പോൾ തുറന്നത്'),
                _HelpBullet('In Progress — ജോലി നടക്കുന്നു'),
                _HelpBullet('Completed — ജോലി പൂർത്തി, ബിൽ ചെയ്യാൻ തയ്യാർ'),
                _HelpBullet('Delivered — വാഹനം ഡെലിവർ / ഇൻവോയ്സ് ആയി'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ഘട്ടം 4 — ലേബർ കാറ്റലോഗ്',
            icon: Icons.handyman_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  '**Labour** പേജിൽ പെയിന്റിംഗ്, വെൽഡിംഗ് പോലുള്ള സാധാരണ ജോലികൾ ചേർക്കാം.',
                ),
                _HelpParagraph(
                  'ഓരോ ജോലിക്കും ഡിഫോൾട്ട് നിരക്ക് നൽകുക. എസ്റ്റിമേറ്റ് തയ്യാറാക്കുമ്പോൾ autocomplete ലിസ്റ്റിൽ കാണും.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ഘട്ടം 5 — എസ്റ്റിമേറ്റ്',
            icon: Icons.request_quote_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  '**Open Estimates** — ഇതുവരെ ബിൽ ചെയ്യാത്ത എസ്റ്റിമേറ്റുകൾ മാത്രം കാണാം.',
                ),
                _HelpParagraph(
                  'ഓരോ എസ്റ്റിമേറ്റിനും:',
                ),
                _HelpBullet('**Edit** — ലേബർ/പാർട്സ് മാറ്റുക'),
                _HelpBullet('**Print** — PDF പ്രിന്റ് / ഷെയർ'),
                _HelpBullet('**Mark Job Done** — ജോലി പൂർത്തിയായി എന്ന് അടയാളപ്പെടുത്തുക'),
                _HelpBullet('**Convert to Invoice** — ഉപഭോക്താവ് സമ്മതിച്ചാൽ ഇൻവോയ്സാക്കുക'),
                _HelpTip(
                  'ഇൻവോയ്സ് നേരിട്ട് ഇൻവോയ്സ് പേജിൽ സൃഷ്ടിക്കാനാവില്ല — എസ്റ്റിമേറ്റിൽ നിന്ന് Convert ചെയ്യുക.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ഘട്ടം 6 — സ്റ്റോക്ക് (പാർട്സ്)',
            icon: Icons.inventory_2_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  '**Stock** പേജിൽ പാർട്സ് പേര്, SKU, വില, അളവ് ചേർക്കുക.',
                ),
                _HelpParagraph(
                  'ഇൻവോയ്സ് സൃഷ്ടിക്കുമ്പോൾ പാർട്സ് സ്റ്റോക്ക് സ്വയം കുറയും. സ്റ്റോക്ക് കുറവാണെങ്കിൽ കൺവേർഷൻ പരാജയപ്പെടാം.',
                ),
                _HelpParagraph(
                  'ഡാഷ്ബോർഡിൽ കുറഞ്ഞ സ്റ്റോക്ക് അലേർട്ട് കാണാം.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'ഘട്ടം 7 — ഇൻവോയ്സ് (ബിൽ)',
            icon: Icons.receipt_long_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  'ഇൻവോയ്സ് പേജിൽ **എല്ലാ ബില്ലുകളുടെ ലിസ്റ്റ്** മാത്രം — പുതിയത് എസ്റ്റിമേറ്റിൽ നിന്ന് Convert ചെയ്യുക.',
                ),
                _HelpParagraph(
                  'ഓരോ ഇൻവോയ്സിനും:',
                ),
                _HelpBullet('**Print** — സാരഥി ഫോർമാറ്റ് PDF പ്രിന്റ്'),
                _HelpBullet('**Record Payment** — കിട്ടിയ തുക രേഖപ്പെടുത്തുക'),
                _HelpBullet('**Mark Paid** — മുഴുവൻ പണവും കിട്ടിയത് എന്ന് അടയാളപ്പെടുത്തുക'),
                _HelpParagraph(
                  'കൺവേർട്ട് ചെയ്താൽ എസ്റ്റിമേറ്റ് **Converted** ആകും, ജോബ് കാർഡ് **Delivered** ആകും.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'വാഹന ഹിസ്റ്ററി (History)',
            icon: Icons.history_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpParagraph(
                  '**History** പേജിൽ വാഹനം തിരഞ്ഞെടുത്താൽ ആ വാഹനത്തിന്റെ എല്ലാ ഇൻവോയ്സുകളും കാണാം.',
                ),
                _HelpParagraph(
                  'ഓരോ ബില്ലിലും താഴെ പറയുന്നവ കാണിക്കും:',
                ),
                _HelpBullet('തീയതി, KM, പേയ്മെന്റ് സ്റ്റാറ്റസ്, തുക'),
                _HelpBullet('മെക്കാനിക്, ഉപഭോക്താവിന്റെ പരാതി'),
                _HelpBullet('ചെയ്ത ലേബർ ജോലികൾ — ഓരോ വരിയും തുകയോടെ'),
                _HelpBullet('ഉപയോഗിച്ച പാർട്സ് — അളവ്, വില'),
                _HelpParagraph(
                  'മുകളിലെ ഗ്ലോബൽ സെർച്ചിൽ വാഹനം തിരഞ്ഞെടുത്താലും ഈ പേജിലേക്ക് നേരിട്ട് പോകാം.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'മറ്റ് സ്ക്രീനുകൾ',
            icon: Icons.apps_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpBullet(
                  '**Dashboard** — ക്വിക്ക് ജോബ് കാർഡ്, വിൽപ്പന, ജോബ് കാർഡുകൾ, സ്റ്റോക്ക് അലേർട്ട്',
                ),
                _HelpBullet(
                  '**Party** — ഉപഭോക്താവും വാഹനവും ചേർക്കുക',
                ),
                _HelpBullet(
                  '**History** — ഒരു വാഹനത്തിന്റെ മുഴുവൻ സർവീസ് ചരിത്രം',
                ),
                _HelpBullet(
                  '**Settings** — ഗാരേജ് പേര്, വിലാസം, ഫോൺ, ബിൽ നമ്പർ (അഡ്മിൻ)',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'പെട്ടെന്നുള്ള ടിപ്പുകൾ',
            icon: Icons.lightbulb_outline_rounded,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HelpTip(
                  'വാഹനം വന്ന ഉടനെ ഡാഷ്ബോർഡിൽ ക്വിക്ക് ജോബ് കാർഡ് തുറക്കുക.',
                ),
                _HelpTip(
                  'പഴയ ഉപഭോക്താവാണെങ്കിൽ മുകളിലെ സെർച്ച് ബാർ ഉപയോഗിക്കുക — ഏറ്റവും വേഗമുള്ള വഴി.',
                ),
                _HelpTip(
                  'വലിയ ജോലിക്ക് മുമ്പ് എസ്റ്റിമേറ്റ് പ്രിന്റ് ചെയ്ത് ഉപഭോക്താവിന് കാണിക്കുക.',
                ),
                _HelpTip(
                  'ജോലി പൂർത്തിയായാൽ Mark Work Done → പിന്നീട് Convert to Invoice.',
                ),
                _HelpTip(
                  'ലോഗിൻ ചെയ്ത ശേഷം ഡാറ്റ ഓൺലൈനിൽ സേവ് ആകും — റിഫ്രഷ് ചെയ്താലും നഷ്ടപ്പെടില്ല.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _flowStep extends StatelessWidget {
  const _flowStep({
    required this.number,
    required this.title,
    required this.body,
    required this.menu,
  });

  final String number;
  final String title;
  final String body;
  final String menu;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(menu),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _flowArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 15, top: 4, bottom: 4),
      child: Icon(Icons.arrow_downward_rounded, size: 18, color: AppColors.textMuted),
    );
  }
}

class _HelpParagraph extends StatelessWidget {
  const _HelpParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(
            color: AppColors.textPrimary,
            height: 1.5,
            fontSize: 14,
          ),
          children: _parseBold(text),
        ),
      ),
    );
  }

  static List<TextSpan> _parseBold(String input) {
    final spans = <TextSpan>[];
    final parts = input.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd
              ? const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)
              : null,
        ),
      );
    }
    return spans;
  }
}

class _HelpBullet extends StatelessWidget {
  const _HelpBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          Expanded(child: _HelpParagraph(text)),
        ],
      ),
    );
  }
}

class _HelpTip extends StatelessWidget {
  const _HelpTip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textPrimary, height: 1.45, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
