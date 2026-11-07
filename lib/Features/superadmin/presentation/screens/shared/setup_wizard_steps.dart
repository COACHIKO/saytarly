part of '../setup_wizard.dart';

// ============================ تعريف الخطوات ============================

class _WizStepInfo {
  const _WizStepInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

List<_WizStepInfo> get _wizSteps => [
  _WizStepInfo(
    title: 'البداية'.tr(),
    subtitle: 'نظرة سريعة على الرحلة'.tr(),
    icon: Icons.auto_awesome,
  ),
  _WizStepInfo(
    title: 'هوية المكان'.tr(),
    subtitle: 'الاسم • النوع • اللوجو'.tr(),
    icon: Icons.storefront_rounded,
  ),
  _WizStepInfo(
    title: 'الجو والفواتير'.tr(),
    subtitle: 'العملة وبيانات الإيصال'.tr(),
    icon: Icons.receipt_long_rounded,
  ),
  _WizStepInfo(
    title: 'حساب الأدمن'.tr(),
    subtitle: 'مفتاح التحكم الكامل'.tr(),
    icon: Icons.shield_outlined,
  ),
  _WizStepInfo(
    title: 'فريق العمل'.tr(),
    subtitle: 'شجرة الكاشير وموظفي الطلبات'.tr(),
    icon: Icons.groups_2_outlined,
  ),
  _WizStepInfo(
    title: 'أقسام المنيو'.tr(),
    subtitle: 'منيو جاهز في ضغطة'.tr(),
    icon: Icons.grid_view_rounded,
  ),
  _WizStepInfo(
    title: 'المراجعة'.tr(),
    subtitle: 'اطمن إن كل حاجة تمام'.tr(),
    icon: Icons.verified_outlined,
  ),
];

// ============================ بيانات مساعدة ============================

const Map<String, IconData> _typeIcons = {
  'cafe': Icons.local_cafe_rounded,
  'restaurant': Icons.restaurant_rounded,
  'restaurant_cafe': Icons.room_service_rounded,
  'playstation_cafe': Icons.sports_esports_rounded,
};

/// رموز العملة بيانات ثابتة — مش بتتترجم.
const Map<String, String> _currencyOptions = {
  'egp': 'ج.م',
  'sar': 'ر.س',
  'aed': 'د.إ',
  'kwd': 'د.ك',
  'usd': r'$',
};

String _staffRoleLabel(String role) {
  switch (role) {
    case 'cashier':
      return 'كاشير'.tr();
    case 'waiter':
      return 'موظف طلبات'.tr();
    case 'admin':
      return 'أدمن'.tr();
    default:
      return role;
  }
}

String _wizardTypeLabel(String type) {
  switch (type) {
    case 'cafe':
      return 'كافيه'.tr();
    case 'restaurant':
      return 'مطعم'.tr();
    case 'restaurant_cafe':
      return 'مطعم وكافيه'.tr();
    case 'playstation_cafe':
      return 'بلايستيشن كافيه'.tr();
    default:
      return BusinessProfile.typeLabel(type);
  }
}

String _typeBlurb(String type) {
  switch (type) {
    case 'cafe':
      return 'قهوة ومشروبات وحلويات — الجو الهادي'.tr();
    case 'restaurant':
      return 'أكل وشيف وطلبات طاولات'.tr();
    case 'restaurant_cafe':
      return 'مطعم وكافيه في نفس المكان'.tr();
    case 'playstation_cafe':
      return 'جلسات لعب + كافيه في تجربة واحدة'.tr();
    default:
      return '';
  }
}

/// أسماء الأقسام بتتخزن عربي (بيانات) وبتتعرض بلغة الواجهة.
/// المقترحات أقسام عامة بس — السخن والبارد وغيره بيتضافوا كقوائم فرعية
/// من إدارة الأقسام بعد التهيئة.
const Map<String, String> _moduleNames = {
  'foods': 'ماكولات',
  'drinks': 'مشروبات',
  'desserts': 'حلويات',
  'appetizers': 'مقبلات',
};

class _TeamDraft {
  const _TeamDraft({
    required this.username,
    required this.password,
    required this.role,
    this.id,
    this.supervisors = const [],
  });

  /// موجود في قاعدة البيانات (بيتعدل) — null يعني عضو جديد.
  final int? id;
  final String username;
  final String password;

  /// 'cashier' أو 'waiter'
  final String role;

  /// 🌿 المشرفين اللي العضو شغال تحتهم — موظف طلبات يقدر يكون تحت
  /// أكتر من كاشير. الأول في القائمة هو المشرف الأساسي.
  /// التفرّع ليه UI في إدارة المستخدمين بس.
  final List<String> supervisors;

  bool get isExisting => id != null;
}

class _ModulePreset {
  const _ModulePreset(
    this.nameId,
    this.iconKey,
    this.icon,
    this.colorValue,
  );

  final String nameId;
  final String iconKey;
  final IconData icon;
  final int colorValue;

  String get name => _moduleNames[nameId] ?? nameId;
  String get label => name.tr();
}

/// الأقسام المقترحة في رحلة التهيئة — أقسام عامة بس لكل أنواع الأنشطة.
/// مفيش اقتراح للسخن/البارد/غيره: دي قوائم فرعية بتتضاف من إدارة الأقسام.
const List<_ModulePreset> _modulePresets = [
  _ModulePreset('foods', 'restaurant', Icons.restaurant_rounded, 0xFFE07A5F),
  _ModulePreset('drinks', 'local_drink', Icons.local_drink_rounded, 0xFF3D9BE9),
  _ModulePreset('desserts', 'cake', Icons.cake_rounded, 0xFFD98BA7),
  _ModulePreset(
    'appetizers',
    'lunch_dining',
    Icons.lunch_dining_rounded,
    0xFF7BB661,
  ),
];

// ============================ سكين التصميم ============================

class _WizSkin {
  const _WizSkin({
    required this.bg,
    required this.bgDeep,
    required this.glass,
    required this.glassSoft,
    required this.border,
    required this.borderStrong,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentText,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
  });

  final Color bg;
  final Color bgDeep;
  final Color glass;
  final Color glassSoft;
  final Color border;
  final Color borderStrong;
  final Color text;
  final Color muted;
  final Color faint;
  final Color accent;
  final Color accentText;
  final Color accentSoft;
  final Color success;
  final Color warning;
  final Color danger;

  Color get onAccent =>
      accent.computeLuminance() > 0.45 ? const Color(0xFF0B1220) : Colors.white;

  static _WizSkin of(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final accent = Color.lerp(primary, Colors.white, 0.28)!;
    return _WizSkin(
      bg: const Color(0xFF05080F),
      bgDeep: const Color(0xFF0C1424),
      glass: Colors.white.withValues(alpha: 0.045),
      glassSoft: Colors.white.withValues(alpha: 0.075),
      border: Colors.white.withValues(alpha: 0.10),
      borderStrong: Colors.white.withValues(alpha: 0.22),
      text: Colors.white,
      muted: const Color(0xFFB4C0D8),
      faint: const Color(0xFF6C7A94),
      accent: accent,
      accentText: Color.lerp(primary, Colors.white, 0.45)!,
      accentSoft: accent.withValues(alpha: 0.16),
      success: const Color(0xFF4ADE80),
      warning: const Color(0xFFFBBF24),
      danger: const Color(0xFFF87171),
    );
  }
}

// ============================ الخطوات ============================

extension _SetupWizardSteps on _SetupWizardScreenState {
  Widget _wizStepBody(BuildContext context) {
    switch (_step) {
      case 0:
        return _wizIntroStep(context);
      case 1:
        return _wizIdentityStep(context);
      case 2:
        return _wizDetailsStep(context);
      case 3:
        return _wizAdminStep(context);
      case 4:
        return _wizTeamStep(context);
      case 5:
        return _wizModulesStep(context);
      default:
        return _wizReviewStep(context);
    }
  }

  // ---------------------------- 1) الترحيب ----------------------------

  Widget _wizIntroStep(BuildContext context) {
    final skin = _WizSkin.of(context);
    final savedName = _nameCtl.text.trim();
    final editing = _setupCompleted && savedName.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        const Center(child: _IntroEmblem()),
        const SizedBox(height: 24),
        Text(
          editing
              ? 'راجع بيانات «{savedName}» وعدّلها'.tr({'savedName': savedName})
              : 'خلّينا نجهّز مكانك في ٧ خطوات',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: skin.text,
            fontSize: 25,
            fontWeight: FontWeight.w900,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          editing
              ? 'كل البيانات الحالية محمّلة هنا — عدّل اللي تحبه وارجع للوحة، والباقي بيفضل زي ما هو.'.tr()
              : 'مش مجرد إعدادات — هتطلع من هنا بمكان كامل: هوية، فريق، منيو جاهز، وفواتير بتطبع باسمك.',
          textAlign: TextAlign.center,
          style: TextStyle(color: skin.muted, fontSize: 13, height: 1.7),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniTag(icon: Icons.palette_outlined, label: 'هوية بصرية'.tr()),
            _MiniTag(icon: Icons.groups_2_outlined, label: 'فريق كامل'.tr()),
            _MiniTag(icon: Icons.grid_view_rounded, label: 'منيو جاهز'.tr()),
            _MiniTag(icon: Icons.print_outlined, label: 'فواتير مطبوعة'.tr()),
            if (_resumedFromDraft)
              _MiniTag(
                icon: Icons.history_rounded,
                label: 'رجعت من مسودة محفوظة'.tr(),
                tone: _WizSkin.of(context).success,
              ),
            if (editing)
              _MiniTag(
                icon: Icons.edit_note_rounded,
                label: 'وضع التعديل'.tr(),
                tone: _WizSkin.of(context).warning,
              ),
          ],
        ),
        const SizedBox(height: 22),
        _GlassCard(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              _roadmapRow(
                skin,
                Icons.fingerprint_rounded,
                '1 · الهوية'.tr(),
                'الاسم، نوع النشاط، واللوجو'.tr(),
              ),
              _thinDivider(skin),
              _roadmapRow(
                skin,
                Icons.receipt_long_rounded,
                '2 · الفواتير'.tr(),
                'العملة وبيانات الإيصال'.tr(),
              ),
              _thinDivider(skin),
              _roadmapRow(
                skin,
                Icons.shield_outlined,
                '3 · الحسابات'.tr(),
                'الأدمن وفريق العمل'.tr(),
              ),
              _thinDivider(skin),
              _roadmapRow(
                skin,
                Icons.rocket_launch_rounded,
                '4 · الانطلاق'.tr(),
                'الأقسام والمراجعة'.tr(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '٧ خطوات · حوالي دقيقتين · تقدر ترجع لأي خطوة'.tr(),
            style: TextStyle(color: skin.faint, fontSize: 11.5),
          ),
        ),
      ],
    );
  }

  Widget _roadmapRow(
    _WizSkin skin,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: skin.accentSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: skin.accentText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: skin.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: skin.muted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------- 2) الهوية ----------------------------

  Widget _wizIdentityStep(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHero(
          icon: Icons.storefront_rounded,
          kicker: 'BRAND STUDIO',
          title: 'مكانك يستاهل هوية تليق بيه'.tr(),
          subtitle:
              'الاسم واللوجو ونوع النشاط — أول حاجة العميل بيشوفها، وأول حاجة بتطبع على الفاتورة.'.tr(),
        ),
        const SizedBox(height: 18),
        _brandPreviewCard(skin),
        const SizedBox(height: 14),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('اسم المكان'.tr()),
              const SizedBox(height: 8),
              _WizField(
                controller: _nameCtl,
                label: 'اسم المكان'.tr(),
                hint: 'كافيه الجراند'.tr(),
                icon: Icons.badge_outlined,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _refresh(() {}),
              ),
              const SizedBox(height: 18),
              _SectionLabel(
                'اللوجو'.tr(),
                trailing: Text(
                  _logoPath == null ? 'الافتراضي'.tr() : 'مخصوص',
                  style: TextStyle(
                    color: skin.faint,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _LogoMark(size: 54, path: _logoPath),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SoftButton(
                      label:
                          _pickingLogo
                              ? 'بنجهّز الصورة…'.tr()
                              : 'اختيار لوجو من الجهاز',
                      icon: Icons.upload_rounded,
                      onPressed: _pickingLogo ? null : _pickLogo,
                    ),
                  ),
                  if (_logoPath != null) ...[
                    const SizedBox(width: 8),
                    _SquareIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'إزالة اللوجو'.tr(),
                      onTap: _clearLogo,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel('نوع النشاط'.tr()),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCols = constraints.maxWidth > 430;
                  final width =
                      twoCols ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final entry in BusinessProfile.typeLabels.entries)
                        // البلايستيشن مش خيار في التهيئة — بيظهر بس لو
                        // المكان متسجل بيه بالفعل عشان ما يتغيرش بالغلط.
                        if (entry.key != 'playstation_cafe' ||
                            _businessType == 'playstation_cafe')
                        SizedBox(
                          width: width,
                          child: _TypeOptionCard(
                            label: _wizardTypeLabel(entry.key),
                            blurb: _typeBlurb(entry.key),
                            icon:
                                _typeIcons[entry.key] ??
                                Icons.storefront_rounded,
                            selected: _businessType == entry.key,
                            onTap: () => _refresh(
                              () => _businessType = entry.key,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              _SectionLabel('تشغيلات المكان'.tr()),
              const SizedBox(height: 4),
              Text(
                'مميزات مكانك بتنور من هنا — وكلها بتتفتح من التهيئة بس.'
                    .tr(),
                style: TextStyle(color: skin.faint, fontSize: 10.5, height: 1.5),
              ),
              const SizedBox(height: 10),
              _FeatureToggleTile(
                icon: Icons.sports_esports_rounded,
                color: const Color(0xFF38BDF8),
                title: 'بلايستيشن'.tr(),
                blurb: 'جلسات أجهزة وترابيزات بسعر الساعة أو الماتش'.tr(),
                value: _playstationEnabled,
                onChanged: (v) => _refresh(() => _playstationEnabled = v),
              ),
              _FeatureToggleTile(
                icon: Icons.blur_on_rounded,
                color: const Color(0xFF4ADE80),
                title: 'شيشة'.tr(),
                blurb: 'مكينة الشيشة وبنود بيع خاصة بيها'.tr(),
                value: _shishaEnabled,
                onChanged: (v) => _refresh(() => _shishaEnabled = v),
              ),
              _FeatureToggleTile(
                icon: Icons.smoking_rooms_outlined,
                color: const Color(0xFFFBBF24),
                title: 'سجاير'.tr(),
                blurb: 'دور السجاير والملحقات في شاشة البيع'.tr(),
                value: _cigarettesEnabled,
                onChanged: (v) => _refresh(() => _cigarettesEnabled = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'اللوجو ده اللي هيظهر في شاشة الكاشير، الفاتورة، وشاشة QR.'.tr(),
          style: TextStyle(color: skin.faint, fontSize: 11.5, height: 1.6),
        ),
      ],
    );
  }

  Widget _brandPreviewCard(_WizSkin skin) {
    final name =
        _nameCtl.text.trim().isEmpty ? 'اسم المكان هنا'.tr() : _nameCtl.text.trim();
    final type = _wizardTypeLabel(_businessType);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            skin.accent.withValues(alpha: 0.28),
            const Color(0xFF7C3AED).withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: skin.borderStrong),
      ),
      child: Row(
        children: [
          _LogoMark(size: 64, path: _logoPath),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LIVE PREVIEW',
                  style: TextStyle(
                    color: skin.accentText,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: skin.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniTag(
                      icon:
                          _typeIcons[_businessType] ??
                          Icons.storefront_rounded,
                      label: type,
                    ),
                    if (_phoneCtl.text.trim().isNotEmpty)
                      _MiniTag(
                        icon: Icons.phone_rounded,
                        label: _phoneCtl.text.trim(),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.auto_awesome,
            color: skin.text.withValues(alpha: 0.25),
            size: 18,
          ),
        ],
      ),
    );
  }

  // ---------------------------- 3) الفواتير ----------------------------

  Widget _wizDetailsStep(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHero(
          icon: Icons.receipt_long_rounded,
          kicker: 'RECEIPT STUDIO',
          title: 'فاتورتك… بشكل يليق بالبراند'.tr(),
          subtitle:
              'العملة وبيانات المكان بتظهر على الإيصال المطبوع. اكتبها مرة واحدة وخلاص.'.tr(),
        ),
        const SizedBox(height: 18),
        Center(
          child: _ReceiptPreview(
            name: _nameCtl.text.trim(),
            logoPath: _logoPath,
            currency: _currencyCtl.text.trim(),
            thanks: _thanksCtl.text.trim(),
            phone: _phoneCtl.text.trim(),
            address: _addressCtl.text.trim(),
            taxId: _taxCtl.text.trim(),
            paperMm: _paperMm,
          ),
        ),
        const SizedBox(height: 18),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('رمز العملة'.tr()),
              const SizedBox(height: 8),
              _WizField(
                controller: _currencyCtl,
                label: 'العملة'.tr(),
                hint: 'ج.م'.tr(),
                icon: Icons.payments_outlined,
                onChanged: (_) => _refresh(() {}),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final currency in _currencyOptions.values)
                    _ChoicePill(
                      label: currency,
                      selected: _currencyCtl.text.trim() == currency,
                      onTap: () => _refresh(() => _currencyCtl.text = currency),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionLabel('بيانات التواصل'.tr()),
              const SizedBox(height: 8),
              _WizField(
                controller: _phoneCtl,
                label: 'رقم التليفون'.tr(),
                hint: '0100 000 0000',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                onChanged: (_) => _refresh(() {}),
              ),
              const SizedBox(height: 10),
              _WizField(
                controller: _addressCtl,
                label: 'العنوان'.tr(),
                hint: 'المعادي · شارع 9'.tr(),
                icon: Icons.location_on_outlined,
                onChanged: (_) => _refresh(() {}),
              ),
              const SizedBox(height: 10),
              _WizField(
                controller: _taxCtl,
                label: 'الرقم الضريبي (اختياري)'.tr(),
                hint: '123-456-789',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 18),
              _SectionLabel('رسالة الشكر'.tr()),
              const SizedBox(height: 8),
              _WizField(
                controller: _thanksCtl,
                label: 'رسالة أسفل الفاتورة'.tr(),
                hint: 'شكراً لزيارتكم'.tr(),
                icon: Icons.favorite_outline_rounded,
                maxLines: 2,
                onChanged: (_) => _refresh(() {}),
              ),
              const SizedBox(height: 18),
              _SectionLabel('عرض ورق الفاتورة'.tr()),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mm in BusinessProfile.invoicePaperOptions)
                    _PaperOption(
                      mm: mm,
                      selected: _paperMm == mm,
                      onTap: () => _refresh(() => _paperMm = mm),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'اختار عرض الورق اللي طابعتك الحرارية بتدعمه — 75 و80 الأكثر شيوعًا.'.tr(),
                style: TextStyle(
                  color: skin.faint,
                  fontSize: 10.5,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'الإيصال بيتحفظ ببياناتك دي وبيرجع تلقائي مع كل فاتورة.'.tr(),
          style: TextStyle(color: skin.faint, fontSize: 11.5, height: 1.6),
        ),
      ],
    );
  }

  // ---------------------------- 4) الأدمن ----------------------------

  Widget _wizAdminStep(BuildContext context) {
    final skin = _WizSkin.of(context);
    final pass = _adminPassCtl.text;
    final score = _passwordScore(pass);
    final editingExisting = _isExistingAdmin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHero(
          icon: Icons.shield_moon_outlined,
          kicker: 'OWNER ACCESS',
          title: 'مفتاح المكان… بإيدك انت'.tr(),
          subtitle:
              'الأدمن هو اللي هيدير المشروبات والتقارير والمستخدمين يوميًا. حساب السوبر ادمن بيفضل منفصل وآمن.'.tr(),
        ),
        const SizedBox(height: 18),
        _AdminCardPreview(
          user: _adminUserCtl.text.trim(),
          password: pass,
          typeLabel: _wizardTypeLabel(_businessType),
        ),
        if (_existingAdmins.isNotEmpty) ...[
          const SizedBox(height: 14),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionLabel('حسابات الأدمن الموجودة'.tr()),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final admin in _existingAdmins)
                      _ChoicePill(
                        label: (admin['username'] ?? '').toString(),
                        selected:
                            editingExisting &&
                            ((admin['username'] ?? '') as String)
                                    .toLowerCase() ==
                                _adminUserCtl.text.trim().toLowerCase(),
                        onTap:
                            () => _selectExistingAdmin(
                              (admin['username'] ?? '').toString(),
                            ),
                      ),
                    _ChoicePill(
                      label: 'حساب جديد +'.tr(),
                      selected: !editingExisting,
                      onTap: _startNewAdmin,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  editingExisting
                      ? 'هتعدّل حساب «{u}» — سيب كلمة السر فاضية وهي هتفضل زي ما هي.'.tr({
                          'u': _adminUserCtl.text.trim(),
                        })
                      : 'هيتعمل حساب أدمن جديد — كلمة السر مطلوبة.'.tr(),
                  style: TextStyle(
                    color: skin.faint,
                    fontSize: 11.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('بيانات الدخول'.tr()),
              const SizedBox(height: 8),
              _WizField(
                controller: _adminUserCtl,
                label: 'اسم المستخدم'.tr(),
                hint: 'admin',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _refresh(() {}),
              ),
              const SizedBox(height: 10),
              _WizField(
                controller: _adminPassCtl,
                label:
                    editingExisting
                        ? 'كلمة مرور جديدة (اختياري)'.tr()
                        : 'كلمة المرور'.tr(),
                hint:
                    editingExisting
                        ? 'سيبها فاضية عشان تفضل زي ما هي'.tr()
                        : '••••••',
                icon: Icons.lock_outline_rounded,
                obscure: !_showAdminPass,
                onChanged: (_) => _refresh(() {}),
                suffix: IconButton(
                  onPressed:
                      () => _refresh(() => _showAdminPass = !_showAdminPass),
                  icon: Icon(
                    _showAdminPass
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: skin.faint,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _StrengthMeter(score: score),
              const SizedBox(height: 12),
              Row(
                children: [
                  _SoftButton(
                    label: 'اقترح كلمة سر قوية'.tr(),
                    icon: Icons.casino_outlined,
                    onPressed: _suggestPassword,
                  ),
                  const Spacer(),
                  Text(
                    editingExisting && pass.isEmpty
                        ? 'هتفضل زي ما هي'.tr()
                        : pass.isEmpty
                        ? 'محتاجة 4 حروف'.tr()
                        : (pass.length >= 4 ? 'تمام ✓'.tr() : 'لسه قصيرة'),
                    style: TextStyle(
                      color: pass.length >= 4 ? skin.success : skin.faint,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------- 5) الفريق — أعضاء وأدوار 🌿 ----------------------------

  Widget _wizTeamStep(BuildContext context) {
    final skin = _WizSkin.of(context);
    final editingMember =
        _editingMemberIndex == null ? null : _team[_editingMemberIndex!];
    final isWaiter = _draftRole == 'waiter';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHero(
          icon: Icons.group_add_rounded,
          kicker: 'TEAM BUILDER',
          title: 'فريق العمل'.tr(),
          subtitle:
              'ضيف الأعضاء وأدوارهم بس — الكاشير وموظف الطلبات. التفرّع بين الأعضاء بيتعمل من شاشة إدارة المستخدمين بعد التهيئة 🌿'
                  .tr(),
        ),
        const SizedBox(height: 18),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(
                editingMember == null
                    ? 'عضو جديد'.tr()
                    : 'تعديل «{u}»'.tr({'u': editingMember.username}),
                trailing:
                    editingMember == null
                        ? null
                        : TextButton(
                          onPressed: _saving ? null : _cancelMemberEdit,
                          style: TextButton.styleFrom(
                            foregroundColor: skin.faint,
                            minimumSize: const Size(0, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            textStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: Text('إلغاء التعديل'.tr()),
                        ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final role in const ['cashier', 'waiter'])
                    _ChoicePill(
                      label: _staffRoleLabel(role),
                      selected: _draftRole == role,
                      onTap: () => _refresh(() => _draftRole = role),
                    ),
                ],
              ),
              if (isWaiter) ...[
                const SizedBox(height: 6),
                Text(
                  'موظف الطلبات هيتفرّع تحت الكاشيرات من إدارة المستخدمين بعد التهيئة — هنا بتحدد بياناته بس 🌿'
                      .tr(),
                  style: TextStyle(
                    color: skin.faint,
                    fontSize: 10.5,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _WizField(
                controller: _staffUserCtl,
                label: 'اسم المستخدم'.tr(),
                hint: 'ahmed',
                icon: Icons.person_add_alt_rounded,
                textInputAction: TextInputAction.next,
                enabled: editingMember?.isExisting != true,
              ),
              const SizedBox(height: 10),
              _WizField(
                controller: _staffPassCtl,
                label: 'كلمة المرور'.tr(),
                hint: '••••••',
                icon: Icons.lock_outline_rounded,
                obscure: !_showStaffPass,
                suffix: IconButton(
                  onPressed:
                      () => _refresh(() => _showStaffPass = !_showStaffPass),
                  icon: Icon(
                    _showStaffPass
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                    color: skin.faint,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: _SoftButton(
                  label:
                      editingMember == null
                          ? 'إضافة العضو للفريق'.tr()
                          : 'حفظ تعديلات العضو'.tr(),
                  icon:
                      editingMember == null
                          ? Icons.person_add_alt_1_rounded
                          : Icons.save_rounded,
                  onPressed: _saveTeamMember,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionLabel(
          'أعضاء الفريق'.tr(),
          trailing: Text(
            '${_team.length}',
            style: TextStyle(
              color: skin.accentText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final member in _team)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: 8),
            child: _WizTeamMemberRow(
              member: member,
              onEdit: () => _startEditMember(_team.indexOf(member)),
              onRemove:
                  member.isExisting
                      ? null
                      : () => _refresh(() {
                        _team.removeAt(_team.indexOf(member));
                        if (_editingMemberIndex != null) _resetMemberForm();
                      }),
            ),
          ),
        if (_team.isEmpty)
          Text(
            'لسه مفيش أعضاء — ضيف كاشير أو موظف طلبات، والتفرّع بين الأعضاء بيتعمل من إدارة المستخدمين بعد التهيئة.'
                .tr(),
            style: TextStyle(color: skin.faint, fontSize: 11.5, height: 1.6),
          ),
        const SizedBox(height: 8),
        Text(
          'كل التعديلات بتتحفظ لما تخلص خطوات التهيئة — الأعضاء الموجودين بيتحدّثوا في مكانهم من غير تكرار.'
              .tr(),
          style: TextStyle(color: skin.faint, fontSize: 11.5, height: 1.6),
        ),
      ],
    );
  }

  // ---------------------------- 6) الأقسام ----------------------------

  Widget _wizModulesStep(BuildContext context) {
    final skin = _WizSkin.of(context);
    final presets = _modulePresets;
    final presetNames = presets.map((p) => p.name).toSet();
    final custom =
        _selectedModules.where((n) => !presetNames.contains(n)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHero(
          icon: Icons.grid_view_rounded,
          kicker: 'MENU BUILDER',
          title: 'منيو جاهز في ضغطة واحدة'.tr(),
          subtitle:
              'أقسام عامة تختار منها اللي يناسبك — السخن والبارد وغيره بتتضاف كقوائم فرعية من إدارة الأقسام. كل قسم بيفتح له تلقائي: إدارة + تقرير في لوحة الأدمن.'.tr(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'أقسام مقترحة'.tr(),
                style: TextStyle(
                  color: skin.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: _selectAllModules,
              style: TextButton.styleFrom(
                foregroundColor: skin.accentText,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text('اختيار الكل'.tr()),
            ),
            if (_selectedModules.isNotEmpty)
              TextButton(
                onPressed: _clearModules,
                style: TextButton.styleFrom(
                  foregroundColor: skin.faint,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text('مسح'.tr()),
              ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCols = constraints.maxWidth > 460;
            final width =
                twoCols ? (constraints.maxWidth - 10) / 2 : constraints.maxWidth;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final preset in presets)
                  SizedBox(
                    width: width,
                    child: _ModuleTile(
                      preset: preset,
                      selected: _selectedModules.contains(preset.name),
                      existing: _existingModules.contains(preset.name),
                      onTap: () => _toggleModule(preset.name),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel('قسم مخصوص؟'.tr()),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _WizField(
                      controller: _moduleCtl,
                      label: 'اسم القسم'.tr(),
                      hint: 'حلويات · آيس كريم · ...'.tr(),
                      icon: Icons.add_box_outlined,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addCustomModule(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SquareIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'إضافة قسم'.tr(),
                    filled: true,
                    onTap: _addCustomModule,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (custom.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionLabel('أقسامك المخصوصة'.tr()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in custom)
                _RemovableTag(
                  label: name,
                  onRemove: () => _refresh(() => _selectedModules.remove(name)),
                ),
            ],
          ),
        ],
        if (_existingModules.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionLabel('أقسام موجودة بالفعل'.tr()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in _existingModules)
                _MiniTag(
                  icon: Icons.verified_rounded,
                  label: name,
                  tone: skin.success,
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'الإجمالي بعد الحفظ: {_moduleCount} قسم'.tr({'_moduleCount': _moduleCount}),
          style: TextStyle(
            color: skin.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ---------------------------- 8) المراجعة ----------------------------

  Widget _wizReviewStep(BuildContext context) {
    final skin = _WizSkin.of(context);
    final type = _wizardTypeLabel(_businessType);
    final hasName = _nameCtl.text.trim().isNotEmpty;
    final adminReady = _adminFormReady;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHero(
          icon: Icons.verified_outlined,
          kicker: 'READY CHECK',
          title: 'نظرة أخيرة… وبعدها الانطلاق'.tr(),
          subtitle:
              'دي خلاصة اللي هيتبني. اضغط على أي سطر تعدّله، وكل حاجة قابلة للتغيير بعدين.'.tr(),
        ),
        const SizedBox(height: 18),
        Center(
          child: _ReadinessRing(
            percent: _readiness,
            accent: skin.accent,
            track: skin.border,
            label: _readinessLabel(_readiness),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniTag(icon: Icons.storefront_rounded, label: type),
            _MiniTag(icon: Icons.grid_view_rounded, label: '{_moduleCount} قسم'.tr({'_moduleCount': _moduleCount})),
            _MiniTag(icon: Icons.groups_2_outlined, label: '{_teamCount} عضو'.tr({'_teamCount': _teamCount})),
            _MiniTag(icon: Icons.receipt_long_rounded, label: '{_paperMm} مم'.tr({'_paperMm': _paperMm})),
          ],
        ),
        const SizedBox(height: 18),
        _GlassCard(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              _ReviewRow(
                icon: Icons.badge_outlined,
                title: 'اسم المكان'.tr(),
                subtitle: hasName ? _nameCtl.text.trim() : 'لسه مكتوبش',
                ok: hasName,
                onTap: () => _jumpTo(1),
              ),
              _thinDivider(skin),
              _ReviewRow(
                icon: Icons.palette_outlined,
                title: 'الهوية'.tr(),
                subtitle:
                    '{type} • {v2}'.tr({'type': type, 'v2': _logoPath == null ? 'لوجو افتراضي'.tr() : 'لوجو مخصوص'}),
                ok: true,
                onTap: () => _jumpTo(1),
              ),
              _thinDivider(skin),
              _ReviewRow(
                icon: Icons.receipt_long_rounded,
                title: 'الفاتورة'.tr(),
                subtitle: '{v1} • {_paperMm} مم'.tr({'v1': _receiptSummary(), '_paperMm': _paperMm}),
                ok: true,
                optional: true,
                onTap: () => _jumpTo(2),
              ),
              _thinDivider(skin),
              _ReviewRow(
                icon: Icons.shield_outlined,
                title: 'حساب الأدمن'.tr(),
                subtitle:
                    adminReady ? _adminUserCtl.text.trim() : 'ناقص بيانات',
                ok: adminReady,
                onTap: () => _jumpTo(3),
              ),
              _thinDivider(skin),
              _ReviewRow(
                icon: Icons.groups_2_outlined,
                title: 'فريق العمل'.tr(),
                subtitle: _teamCount == 0 ? 'لسه من غير فريق'.tr() : '$_teamCount عضو',
                ok: _teamCount > 0,
                optional: true,
                onTap: () => _jumpTo(4),
              ),
              _thinDivider(skin),
              _ReviewRow(
                icon: Icons.sports_esports_rounded,
                title: 'تشغيلات المكان'.tr(),
                subtitle: _featuresSummary(),
                ok: true,
                optional: true,
                onTap: () => _jumpTo(1),
              ),
              _thinDivider(skin),
              _ReviewRow(
                icon: Icons.grid_view_rounded,
                title: 'أقسام المنيو'.tr(),
                subtitle: _moduleCount == 0 ? 'لسه مفيش أقسام'.tr() : '$_moduleCount قسم جاهز',
                ok: _moduleCount > 0,
                onTap: () => _jumpTo(5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'كل الإعدادات دي بتتخزن محليًا في قاعدة البيانات، وتقدر تعدلها من لوحة السوبر ادمن في أي وقت.'.tr(),
          style: TextStyle(color: skin.faint, fontSize: 11.5, height: 1.6),
        ),
      ],
    );
  }

  String _readinessLabel(int percent) {
    if (percent >= 90) return 'جاهز للانطلاق'.tr();
    if (percent >= 65) return 'قريب جدًا'.tr();
    if (percent >= 40) return 'على الطريق'.tr();
    return 'لسه في الأول'.tr();
  }

  /// 🎛️ الملخص اللي بيظهر في المراجعة للتشغيلات المختارة.
  String _featuresSummary() {
    final enabled = <String>[];
    if (_playstationEnabled) enabled.add('بلايستيشن'.tr());
    if (_shishaEnabled) enabled.add('شيشة'.tr());
    if (_cigarettesEnabled) enabled.add('سجاير'.tr());
    return enabled.isEmpty ? 'كل التشغيلات مقفولة'.tr() : enabled.join(' • ');
  }

  String _receiptSummary() {
    final parts = <String>[];
    final currency = _currencyCtl.text.trim();
    parts.add(currency.isEmpty ? 'عملة افتراضية'.tr() : currency);
    if (_phoneCtl.text.trim().isNotEmpty) parts.add('تليفون'.tr());
    if (_addressCtl.text.trim().isNotEmpty) parts.add('عنوان'.tr());
    return parts.join(' • ');
  }

  // ---------------------------- التقدم والفوتر ----------------------------

  Widget _wizProgressBar(_WizSkin skin, {double height = 6}) {
    return Row(
      children: [
        for (var i = 0; i < _wizSteps.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                height: height,
                decoration: BoxDecoration(
                  color:
                      i < _step
                          ? skin.success
                          : (i == _step ? skin.accent : skin.border),
                  borderRadius: BorderRadius.circular(99),
                  boxShadow:
                      i == _step
                          ? [
                            BoxShadow(
                              color: skin.accent.withValues(alpha: 0.55),
                              blurRadius: 10,
                            ),
                          ]
                          : null,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _wizFooter(BuildContext context, _WizSkin skin) {
    final skippable = _step == 2 || _step == 4 || _step == 5;
    return Row(
      children: [
        if (_step > 0)
          _SoftButton(
            label: 'السابق'.tr(),
            icon: Icons.chevron_left_rounded,
            onPressed: _saving ? null : () => _refresh(() => _step--),
          ),
        const Spacer(),
        if (skippable)
          TextButton(
            onPressed: _saving ? null : _skipStep,
            style: TextButton.styleFrom(
              foregroundColor: skin.faint,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 40),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text('تخطي'.tr()),
          ),
        const SizedBox(width: 6),
        _wizPrimaryButton(skin),
      ],
    );
  }

  Widget _wizPrimaryButton(_WizSkin skin) {
    return FilledButton(
      onPressed: _saving ? null : _goNext,
      style: FilledButton.styleFrom(
        backgroundColor: skin.accent,
        foregroundColor: skin.onAccent,
        disabledBackgroundColor: skin.accent.withValues(alpha: 0.35),
        disabledForegroundColor: skin.onAccent.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
      ),
      child:
          _saving
              ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: skin.onAccent,
                ),
              )
              : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_nextLabel),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 17),
                ],
              ),
    );
  }

  // ---------------------------- التحميل والنجاح ----------------------------

  Widget _wizLoading(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Scaffold(
      backgroundColor: skin.bg,
      body: _Aurora(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LogoMark(size: 64),
              const SizedBox(height: 18),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: skin.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'بنجهّز استوديو التهيئة…'.tr(),
                style: TextStyle(color: skin.muted, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wizSuccessScreen(BuildContext context, {required bool isDesktop}) {
    final skin = _WizSkin.of(context);
    final name =
        _nameCtl.text.trim().isEmpty ? 'مكانك'.tr() : _nameCtl.text.trim();
    return Scaffold(
      backgroundColor: skin.bg,
      body: _Aurora(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 40 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _CelebrationEmblem()),
                    const SizedBox(height: 26),
                    Text(
                      'المكان جاهز للانطلاق 🎉'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: skin.text,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '«{name}» اتظبط بالكامل — الهوية، الفريق، والمنيو في انتظارك.'.tr({'name': name}),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: skin.muted,
                        fontSize: 13,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _GlassCard(
                      child: Row(
                        children: [
                          _statCell(skin, '$_moduleCount', 'قسم'.tr()),
                          _statDivider(skin),
                          _statCell(skin, '$_teamCount', 'عضو'.tr()),
                          _statDivider(skin),
                          _statCell(skin, '{_paperMm} مم'.tr({'_paperMm': _paperMm}), 'ورق'.tr()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GlassCard(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        children: [
                          _roadmapRow(
                            skin,
                            _typeIcons[_businessType] ??
                                Icons.storefront_rounded,
                            _wizardTypeLabel(_businessType),
                            'نوع النشاط'.tr(),
                          ),
                          _thinDivider(skin),
                          _roadmapRow(
                            skin,
                            Icons.point_of_sale_rounded,
                            _adminUserCtl.text.trim().isEmpty
                                ? 'admin'
                                : _adminUserCtl.text.trim(),
                            'حساب الأدمن'.tr(),
                          ),
                          _thinDivider(skin),
                          _roadmapRow(
                            skin,
                            Icons.receipt_long_rounded,
                            _paperMm == 0 ? '75 مم'.tr() : '$_paperMm مم',
                            'عرض ورق الفاتورة'.tr(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _leave,
                        style: FilledButton.styleFrom(
                          backgroundColor: skin.accent,
                          foregroundColor: skin.onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('ادخل للنظام'.tr()),
                            SizedBox(width: 8),
                            Icon(Icons.rocket_launch_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed:
                          () => _refresh(() {
                            _finished = false;
                            _step = 6;
                          }),
                      style: TextButton.styleFrom(
                        foregroundColor: skin.faint,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text('رجوع للمراجعة'.tr()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCell(_WizSkin skin, String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: skin.text,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(color: skin.muted, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statDivider(_WizSkin skin) =>
      Container(width: 1, height: 30, color: skin.border);

  Widget _thinDivider(_WizSkin skin) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: skin.border,
  );
}

// ============================ مكوّنات الواجهة ============================

/// خلفية أورورا متحركة — توهجات ناعمة + شبكة خفيفة.
class _Aurora extends StatefulWidget {
  const _Aurora({required this.child});

  final Widget child;

  @override
  State<_Aurora> createState() => _AuroraState();
}

class _AuroraState extends State<_Aurora>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skin.bg, skin.bgDeep],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final value = Curves.easeInOut.transform(_controller.value);
                return Stack(
                  children: [
                    _blob(
                      left: -140 + 40 * value,
                      top: -90 + 30 * value,
                      size: 400,
                      color: skin.accent.withValues(alpha: 0.22),
                    ),
                    _blob(
                      right: -150,
                      bottom: -110 + 44 * (1 - value),
                      size: 440,
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                    ),
                    _blob(
                      right: 40,
                      top: -130 + 24 * value,
                      size: 280,
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.13),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _GridPainter(
                  color: Colors.white.withValues(alpha: 0.022),
                ),
              ),
            ),
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }

  Widget _blob({
    double? left,
    double? top,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 48.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: skin.glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: skin.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _StepHero extends StatelessWidget {
  const _StepHero({
    required this.icon,
    required this.kicker,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String kicker;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                skin.accent.withValues(alpha: 0.35),
                const Color(0xFF7C3AED).withValues(alpha: 0.25),
              ],
            ),
            border: Border.all(color: skin.borderStrong),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 24, color: skin.text),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kicker,
                style: TextStyle(
                  color: skin.accentText,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: skin.text,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  color: skin.muted,
                  fontSize: 12,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WizField extends StatelessWidget {
  const _WizField({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.maxLines = 1,
    this.textInputAction,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: skin.border),
    );
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      cursorColor: skin.accent,
      style: TextStyle(
        color: skin.text,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: skin.muted, fontSize: 12.5),
        floatingLabelStyle: TextStyle(
          color: skin.accentText,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: skin.faint, fontSize: 13),
        prefixIcon: Icon(icon, size: 19, color: skin.faint),
        suffixIcon: suffix,
        filled: true,
        fillColor: skin.glass,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: skin.accent, width: 1.5),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Row(
      children: [
        Text(
          text,
          style: TextStyle(
            color: skin.text,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

class _SoftButton extends StatelessWidget {
  const _SoftButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: skin.text,
        backgroundColor: skin.glass,
        disabledForegroundColor: skin.faint,
        side: BorderSide(color: skin.border),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  const _SquareIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: filled ? skin.accent : skin.glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: filled ? Colors.transparent : skin.border,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: filled ? skin.onAccent : skin.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: skin.glass,
              border: Border.all(color: skin.border),
            ),
            child: Icon(icon, size: 18, color: skin.muted),
          ),
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.icon,
    required this.label,
    this.tone,
  });

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    final color = tone ?? skin.accentText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovableTag extends StatelessWidget {
  const _RemovableTag({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: skin.glassSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: skin.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: skin.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Icon(Icons.close_rounded, size: 13, color: skin.faint),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? skin.accentSoft : skin.glass,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color:
                  selected
                      ? skin.accent.withValues(alpha: 0.65)
                      : skin.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? skin.accentText : skin.muted,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeOptionCard extends StatelessWidget {
  const _TypeOptionCard({
    required this.label,
    required this.blurb,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String blurb;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? skin.accentSoft : skin.glassSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  selected
                      ? skin.accent.withValues(alpha: 0.7)
                      : skin.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      selected
                          ? skin.accent.withValues(alpha: 0.22)
                          : skin.glass,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 19,
                  color: selected ? skin.accentText : skin.muted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: skin.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: skin.muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: selected ? skin.accentText : skin.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminCardPreview extends StatelessWidget {
  const _AdminCardPreview({
    required this.user,
    required this.password,
    required this.typeLabel,
  });

  final String user;
  final String password;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    final name = user.isEmpty ? 'admin' : user;
    final length =
        password.isEmpty ? 8 : (password.length < 4 ? 4 : (password.length > 12 ? 12 : password.length));
    final masked = List.filled(length, '•').join();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            skin.accent.withValues(alpha: 0.26),
            const Color(0xFF7C3AED).withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: skin.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 16,
                color: skin.accentText,
              ),
              const SizedBox(width: 6),
              Text(
                'OWNER CARD',
                style: TextStyle(
                  color: skin.accentText,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                typeLabel,
                style: TextStyle(
                  color: skin.text.withValues(alpha: 0.7),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: skin.text,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            masked,
            style: TextStyle(
              color: skin.text.withValues(alpha: 0.65),
              fontSize: 13,
              letterSpacing: 4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniTag(
                icon: Icons.lock_outline_rounded,
                label: 'صلاحيات كاملة'.tr(),
              ),
              const SizedBox(width: 6),
              _MiniTag(
                icon: Icons.storefront_rounded,
                label: 'مدير المكان'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    late final labels = ['مش آمنة', 'ضعيفة'.tr(), 'مقبولة'.tr(), 'قوية'.tr(), 'قوية جدًا'.tr()];
    final color =
        score >= 4
            ? skin.success
            : (score == 3
                ? const Color(0xFF84CC16)
                : (score == 2 ? skin.warning : skin.danger));
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++)
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 5,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: i < score ? color : skin.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'قوة كلمة السر'.tr(),
              style: TextStyle(color: skin.faint, fontSize: 10.5),
            ),
            const Spacer(),
            Text(
              score == 0 ? '—' : labels[score],
              style: TextStyle(
                color: score == 0 ? skin.faint : color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 🎛️ بلاطة تشغيل — ميزة المكان كاملة في سطر واحد: أيقونة + عنوان
/// + وصف + مفتاح متحرك. بتتلمس كلها (البطاقة أو المفتاح).
class _FeatureToggleTile extends StatelessWidget {
  const _FeatureToggleTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.blurb,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String blurb;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsetsDirectional.only(bottom: 8),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: value
              ? color.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value
                ? color.withValues(alpha: 0.45)
                : skin.border,
          ),
          boxShadow:
              value
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color.withValues(alpha: value ? 0.2 : 0.08),
                border: Border.all(
                  color: color.withValues(alpha: value ? 0.5 : 0.18),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: value ? color : skin.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: skin.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: value ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(start: 6),
                          child: Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    blurb,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: skin.muted,
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: skin.onAccent,
              activeTrackColor: color.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🧱 صف عضو في خطوة الفريق — اسم ودور وأزرار سريعة. التفرّع بين الأعضاء
/// عالق من شاشة إدارة المستخدمين بعد التهيئة، فالصف هنا مبسّط عمدًا.
class _WizTeamMemberRow extends StatelessWidget {
  const _WizTeamMemberRow({
    required this.member,
    required this.onEdit,
    required this.onRemove,
  });

  final _TeamDraft member;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    final isCashier = member.role == 'cashier';
    final roleColor = isCashier ? skin.success : skin.warning;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(11, 9, 9, 9),
      decoration: BoxDecoration(
        color: skin.glass,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: roleColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withValues(alpha: 0.13),
              border: Border.all(color: roleColor.withValues(alpha: 0.45)),
            ),
            child: Icon(
              isCashier
                  ? Icons.point_of_sale_outlined
                  : Icons.room_service_outlined,
              size: 18,
              color: roleColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: skin.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MiniTag(
                      icon:
                          isCashier
                              ? Icons.point_of_sale_rounded
                              : Icons.room_service_rounded,
                      label: _staffRoleLabel(member.role),
                      tone: roleColor,
                    ),
                    if (member.isExisting)
                      _MiniTag(
                        icon: Icons.verified_rounded,
                        label: 'محفوظ'.tr(),
                        tone: skin.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
          _WizRoundIconBtn(
            icon: Icons.edit_rounded,
            tooltip: 'تعديل'.tr(),
            color: skin.accentText,
            onTap: onEdit,
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            _WizRoundIconBtn(
              icon: Icons.delete_outline_rounded,
              tooltip: 'حذف'.tr(),
              color: skin.danger,
              onTap: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}


/// زرار دائري صغير ملوّن — أزرار إجراءات مصغرة (تعديل/حذف).
class _WizRoundIconBtn extends StatelessWidget {
  const _WizRoundIconBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: onTap == null ? 0.08 : 0.16),
            border: Border.all(
              color: color.withValues(alpha: onTap == null ? 0.2 : 0.6),
            ),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.preset,
    required this.selected,
    required this.existing,
    required this.onTap,
  });

  final _ModulePreset preset;
  final bool selected;
  final bool existing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    final color = Color(preset.colorValue);
    final active = selected || existing;
    return GestureDetector(
      onTap: existing ? null : onTap,
      child: MouseRegion(
        cursor: existing ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color:
                active
                    ? color.withValues(alpha: 0.16)
                    : skin.glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  active
                      ? color.withValues(alpha: 0.65)
                      : skin.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  preset.icon,
                  size: 21,
                  color: Color.lerp(color, Colors.white, 0.2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preset.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: skin.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      existing
                          ? 'موجود بالفعل'.tr()
                          : (selected ? 'هيتضاف'.tr() : 'اضغط للإضافة'),
                      style: TextStyle(
                        color: existing ? skin.success : skin.faint,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                active
                    ? Icons.check_circle_rounded
                    : Icons.add_circle_outline_rounded,
                size: 19,
                color: active ? color : skin.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperOption extends StatelessWidget {
  const _PaperOption({
    required this.mm,
    required this.selected,
    required this.onTap,
  });

  final int mm;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? skin.accentSoft : skin.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? skin.accent.withValues(alpha: 0.65) : skin.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 42,
              child: Center(
                child: Container(
                  width: mm * 0.42 + 22,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected ? skin.text : skin.glassSoft,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: skin.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _paperLine(selected ? skin.bg : skin.faint),
                      const SizedBox(height: 4),
                      _paperLine(selected ? skin.bg : skin.faint),
                      const SizedBox(height: 4),
                      _paperLine(selected ? skin.bg : skin.faint),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '{mm} مم'.tr({'mm': mm}),
              style: TextStyle(
                color: selected ? skin.accentText : skin.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paperLine(Color color) => Container(
    width: 22,
    height: 1.4,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({
    required this.name,
    required this.logoPath,
    required this.currency,
    required this.thanks,
    required this.phone,
    required this.address,
    required this.taxId,
    required this.paperMm,
  });

  final String name;
  final String? logoPath;
  final String currency;
  final String thanks;
  final String phone;
  final String address;
  final String taxId;
  final int paperMm;

  static const _ink = Color(0xFF2C2418);
  static const _softInk = Color(0xFF6B5E4A);
  static const _paper = Color(0xFFF8F4E9);
  static const _dash = Color(0xFFDDD3BE);

  @override
  Widget build(BuildContext context) {
    final title = name.trim().isEmpty ? 'اسم المكان'.tr() : name.trim();
    final symbol = currency.trim().isEmpty ? 'ج.م'.tr() : currency.trim();
    final width = paperMm <= 58 ? 216.0 : (paperMm <= 75 ? 252.0 : 268.0);

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: _logoImage(logoPath, fallbackColor: _softInk),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'فاتورة تجريبية · {paperMm} مم'.tr({'paperMm': paperMm}),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A7C63),
              fontSize: 8.5,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          _dashLine(),
          const SizedBox(height: 8),
          _receiptLine('كافيه لاتيه'.tr(), '35', symbol),
          const SizedBox(height: 5),
          _receiptLine('كرواسون'.tr(), '30', symbol),
          const SizedBox(height: 8),
          _dashLine(),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'الإجمالي'.tr(),
                style: TextStyle(
                  color: _ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '65 $symbol',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _dashLine(),
          const SizedBox(height: 8),
          if (thanks.trim().isNotEmpty)
            Text(
              thanks.trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _softInk,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          if (phone.trim().isNotEmpty)
            _receiptMeta(phone.trim()),
          if (address.trim().isNotEmpty)
            _receiptMeta(address.trim()),
          if (taxId.trim().isNotEmpty) _receiptMeta('ر.ض: {v1}'.tr({'v1': taxId.trim()})),
          const SizedBox(height: 8),
          const Text(
            'POWERED BY SAYTARLY',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFA89A80),
              fontSize: 7,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptLine(String label, String value, String symbol) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: _softInk, fontSize: 10.5),
          ),
        ),
        Text(
          '$value $symbol',
          style: const TextStyle(
            color: _ink,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _receiptMeta(String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Color(0xFF8A7C63), fontSize: 8.5),
      ),
    );
  }

  Widget _dashLine() => SizedBox(
    height: 1,
    child: CustomPaint(painter: _DashedLinePainter(color: _dash)),
  );
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ReadinessRing extends StatelessWidget {
  const _ReadinessRing({
    required this.percent,
    required this.accent,
    required this.track,
    required this.label,
  });

  final int percent;
  final Color accent;
  final Color track;
  final String label;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return SizedBox(
      width: 134,
      height: 134,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: percent / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(134, 134),
                painter: _RingPainter(
                  progress: value,
                  color: accent,
                  track: track,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(value * 100).round()}%',
                    style: TextStyle(
                      color: skin.text,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: skin.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset(stroke / 2, stroke / 2) &
        Size(size.width - stroke, size.height - stroke);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.35), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.ok,
    required this.onTap,
    this.optional = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool ok;
  final VoidCallback onTap;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    final color = ok ? skin.success : skin.warning;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.14),
              ),
              alignment: Alignment.center,
              child: Icon(
                ok ? Icons.check_rounded : icon,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: skin.text,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (optional && !ok) ...[
                        const SizedBox(width: 6),
                        Text(
                          'اختياري'.tr(),
                          style: TextStyle(
                            color: skin.faint,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: skin.muted, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 15, color: skin.faint),
          ],
        ),
      ),
    );
  }
}

// ============================ اللوجو والأيقونات ============================

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size, this.path});

  final double size;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: skin.glassSoft,
        border: Border.all(color: skin.borderStrong),
      ),
      child: _logoImage(path, fallbackColor: skin.muted),
    );
  }
}

Widget _logoImage(String? path, {required Color fallbackColor}) {
  if (path != null && path.isNotEmpty && File(path).existsSync()) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => Icon(
            Icons.storefront_rounded,
            color: fallbackColor,
            size: 22,
          ),
    );
  }
  return Image.asset(
    BusinessProfile.defaultLogoAsset,
    fit: BoxFit.cover,
    errorBuilder:
        (_, __, ___) => Icon(
          Icons.storefront_rounded,
          color: fallbackColor,
          size: 22,
        ),
  );
}

class _IntroEmblem extends StatefulWidget {
  const _IntroEmblem();

  @override
  State<_IntroEmblem> createState() => _IntroEmblemState();
}

class _IntroEmblemState extends State<_IntroEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    return SizedBox(
      width: 152,
      height: 152,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotationTransition(
            turns: _controller,
            child: CustomPaint(
              size: const Size(152, 152),
              painter: _DashedRingPainter(color: skin.borderStrong),
            ),
          ),
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  skin.accent.withValues(alpha: 0.4),
                  const Color(0xFF7C3AED).withValues(alpha: 0.28),
                ],
              ),
              border: Border.all(color: skin.borderStrong),
            ),
            child: ClipOval(
              child: _logoImage(null, fallbackColor: skin.muted),
            ),
          ),
          Positioned(
            top: 8,
            right: 14,
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: skin.accentText,
            ),
          ),
          Positioned(
            bottom: 16,
            left: 10,
            child: Icon(
              Icons.local_cafe_rounded,
              size: 15,
              color: skin.success,
            ),
          ),
          Positioned(
            bottom: 22,
            right: 8,
            child: Icon(
              Icons.receipt_long_rounded,
              size: 14,
              color: skin.warning,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  _DashedRingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = color;
    const dashes = 44;
    for (var i = 0; i < dashes; i += 2) {
      final start = (i / dashes) * 2 * math.pi;
      final sweep = (2 * math.pi / dashes) * 0.72;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ============================ احتفال النهاية ============================

class _CelebrationEmblem extends StatefulWidget {
  const _CelebrationEmblem();

  @override
  State<_CelebrationEmblem> createState() => _CelebrationEmblemState();
}

class _CelebrationEmblemState extends State<_CelebrationEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = _WizSkin.of(context);
    final colors = [
      skin.accent,
      skin.success,
      skin.warning,
      const Color(0xFFF472B6),
      const Color(0xFF38BDF8),
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        final pop = Curves.elasticOut.transform(
          (progress / 0.55).clamp(0.0, 1.0),
        );
        return SizedBox(
          width: 210,
          height: 210,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(210, 210),
                painter: _BurstPainter(progress: progress, colors: colors),
              ),
              Transform.scale(
                scale: 0.5 + pop * 0.5,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        skin.accent,
                        const Color(0xFF7C3AED),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: skin.accent.withValues(alpha: 0.5),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    size: 40,
                    color: skin.onAccent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.colors});

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(progress);
    final fade = (1 - progress).clamp(0.0, 1.0);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = colors.first.withValues(alpha: fade * 0.5);
    canvas.drawCircle(center, 34 + 78 * eased, ringPaint);

    const count = 24;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final distance = 32 + (70 + (i % 4) * 10) * eased;
      final point = center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final dot = Paint()
        ..color = colors[i % colors.length].withValues(alpha: fade);
      canvas.drawCircle(point, 2.2 + (i % 3), dot);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
