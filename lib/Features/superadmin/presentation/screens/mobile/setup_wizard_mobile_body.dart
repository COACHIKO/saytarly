part of '../setup_wizard.dart';

/// جسم معالج التهيئة — نسخة الموبايل (زي ما كانت بالظبط).
extension _SetupWizardMobileBody on _SetupWizardScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F1A), Color(0xFF1A2233)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildStepBody()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
     final steps = ['بيانات المكان', 'حساب الأدمن'.tr(), 'حساب الستاف'.tr(), 'أقسام المنتجات'.tr()];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (i) {
              final active = i <= _step;
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: active ? Colors.tealAccent : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? Colors.white : Colors.white38,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 0:
        return _buildBusinessStep();
      case 1:
        return _buildAccountStep(
          isAdmin: true,
          userCtl: _adminUserCtl,
          passCtl: _adminPassCtl,
        );
      case 2:
        return _buildAccountStep(
          isAdmin: false,
          userCtl: _staffUserCtl,
          passCtl: _staffPassCtl,
        );
      default:
        return _buildModulesStep();
    }
  }

  Widget _sectionTitle(String text, {String? subtitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ],
      const SizedBox(height: 18),
    ],
  );

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white70),
    prefixIcon: Icon(icon, color: Colors.white54),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white24),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
    ),
  );

  Widget _buildBusinessStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle(
          'أهلًا بيك في تهيئة النظام 👋'.tr(),
          subtitle:
              'من هنا بتظبط النظام يناسب مكانك: الاسم، النوع، وبعدها بتنشئ الحسابات والأقسام.'.tr(),
        ),
        TextField(
          controller: _nameCtl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('اسم المكان (زي: كافيه الجراند)'.tr(), Icons.storefront),
        ),
        const SizedBox(height: 22),
         Text(
          'نوع النشاط'.tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BusinessProfile.typeLabels.entries.map((e) {
            final selected = _businessType == e.key;
            return ChoiceChip(
              label: Text(e.value),
              selected: selected,
              onSelected: (_) {
                _refresh(() {
                  _businessType = e.key;
                  if (e.key == 'playstation_cafe') _playstation = true;
                });
              },
              labelStyle: TextStyle(
                color: selected ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
              selectedColor: Colors.tealAccent,
              backgroundColor: Colors.white10,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SwitchListTile(
          value: _playstation,
          onChanged: (v) => _refresh(() => _playstation = v),
          title:  Text(
            'النظام فيه بلايستيشن (أجهزة/شاشات)؟'.tr(),
            style: TextStyle(color: Colors.white),
          ),
          subtitle:  Text(
            'لو مفعّل هيظهر كروت إدارة الأجهزة وتقرير البلايستيشن في لوحة الأدمن'.tr(),
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          activeColor: Colors.tealAccent,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildAccountStep({
    required bool isAdmin,
    required TextEditingController userCtl,
    required TextEditingController passCtl,
  }) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle(
          isAdmin ? 'حساب الأدمن'.tr() : 'حساب الكاشير (اختياري)',
          subtitle: isAdmin
              ? 'الأدمن هو اللي هيدير المكان يوميًا: المشروبات، التقارير، المستخدمين.'.tr()
              : 'الكاشير هو مدير الصالة اللي بياخد الطلبات ويفتح الشيفت ويبدأ شغل موظفي الطلبات. تقدر تسيبه دلوقتي وتضيفه بعدين.',
        ),
        TextField(
          controller: userCtl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('اسم المستخدم'.tr(), Icons.person),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: passCtl,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDeco('كلمة المرور'.tr(), Icons.lock),
        ),
      ],
    );
  }

  Widget _buildModulesStep() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _sectionTitle(
          'أقسام منتجات المطبخ'.tr(),
          subtitle:
              'زي: مشروبات، ماكولات، حلويات... كل قسم هيطلع له تلقائي: إدارة + تقرير في لوحة الأدمن، وتقدر تضيف جواه قوائم فرعية (سخن/بارد/إلخ). الخامات مخزون مشترك لكل الأقسام.'.tr(),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _moduleCtl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDeco('اسم القسم (زي: مشروبات)'.tr(), Icons.category),
                onSubmitted: (_) => _addModuleFromField(),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: _addModuleFromField,
              icon: const Icon(Icons.add),
              label:  Text('إضافة'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_addedModules.isEmpty)
           Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لسه مفيش أقسام — تقدر تكمّل من غيرها وتضيفها بعدين من لوحة السوبر ادمن'.tr(),
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          )
        else
          ..._addedModules.map(
            (m) => Card(
              color: Colors.white10,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.tealAccent),
                title: Text(m, style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isLast = _step == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
              onPressed: _saving ? null : () => _refresh(() => _step--),
              child:  Text('السابق'.tr(), style: TextStyle(color: Colors.white70)),
            ),
           Spacer(),
          if (_step == 1)
            TextButton(
              onPressed:
                  _saving ? null : () => _refresh(() => _step = 2),
              child:  Text('مش دلوقتي'.tr(), style: TextStyle(color: Colors.white54)),
            ),
          if (_step == 2)
            TextButton(
              onPressed:
                  _saving ? null : () => _refresh(() => _step = 3),
              child:  Text('تخطي'.tr(), style: TextStyle(color: Colors.white54)),
            ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.tealAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            ),
            onPressed: _saving ? null : _goNext,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isLast ? 'ابدأ العمل 🚀'.tr() : 'التالي',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
