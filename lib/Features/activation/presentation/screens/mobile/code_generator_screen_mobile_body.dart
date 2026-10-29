part of '../code_generator_screen.dart';

/// جسم شاشة مولّد أكواد التفعيل — نسخة الموبايل (زي ما كانت بالظبط).
extension _CodeGeneratorScreenMobileBody on _CodeGeneratorScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('مولّد أكواد التفعيل'.tr()),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _unlocked ? _buildGenerator() : _buildPasswordGate(),
          ),
        ),
      ),
    );
  }

  // ── شاشة كلمة السر ──
  Widget _buildPasswordGate() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings,
                size: 60, color: Colors.blueGrey),
            const SizedBox(height: 16),
             Text('هذه الصفحة للمهندس فقط'.tr(),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                labelText: 'كلمة سر المهندس'.tr(),
                border: const OutlineInputBorder(),
                errorText: _passError ? 'كلمة السر غير صحيحة'.tr() : null,
              ),
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _unlock,
                icon: const Icon(Icons.lock_open),
                label:  Text('دخول'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── شاشة الجنيريتور ──
  Widget _buildGenerator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── كود الجهاز الحالي (للمرجعية) ──
        if (_currentDeviceId.isNotEmpty)
          Card(
            color: Colors.blue[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('كود جهازك الحالي (مرجعية):'.tr(),
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentDeviceId,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      IconButton(
                        iconSize: 18,
                        icon: const Icon(Icons.copy),
                        onPressed: () => Clipboard.setData(
                            ClipboardData(text: _currentDeviceId)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // ── إدخال كود الجهاز المراد تفعيله ──
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('الخطوة 1: كود الجهاز (من العميل)'.tr(),
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: _deviceIdCtrl,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontFamily: 'monospace', letterSpacing: 1),
                  decoration: InputDecoration(
                    hintText: 'الصق كود الجهاز هنا...'.tr(),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.paste),
                          tooltip: 'لصق'.tr(),
                          onPressed: () async {
                            final d = await Clipboard.getData(
                                Clipboard.kTextPlain);
                            if (d?.text != null) {
                              _deviceIdCtrl.text = d!.text!.trim();
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'مسح'.tr(),
                          onPressed: () => _deviceIdCtrl.clear(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── اختيار المدة ──
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('الخطوة 2: مدة الترخيص'.tr(),
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // خيار مدى الحياة
                SwitchListTile(
                  title:  Text('دائم — مدى الحياة'.tr()),
                  subtitle:
                       Text('العميل اشترى السيستم نهائياً'.tr()),
                  value: _isLifetime,
                  onChanged: (val) => _refresh(() => _isLifetime = val),
                  contentPadding: EdgeInsets.zero,
                ),
                if (!_isLifetime) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                   Text('أو اختر مدة التجربة:'.tr(),
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  // Chips سريعة
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [3, 7, 14, 30, 60, 90, 180, 365].map((d) {
                      final label = d >= 365
                          ? '{v1} سنة'.tr({'v1': d ~/ 365})
                          : '$d يوم';
                      return ChoiceChip(
                        label: Text(label),
                        selected: _selectedDays == d,
                        onSelected: (sel) {
                          if (sel) {
                            _refresh(() {
                              _selectedDays = d;
                              _customDaysCtrl.text = d.toString();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  // إدخال يدوي
                  TextField(
                    controller: _customDaysCtrl,
                    keyboardType: TextInputType.number,
                    decoration:  InputDecoration(
                      labelText: 'أو أدخل عدد الأيام يدوياً'.tr(),
                      border: OutlineInputBorder(),
                      isDense: true,
                      suffixText: 'يوم'.tr(),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        _refresh(() => _selectedDays = parsed);
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
         SizedBox(height: 16),

        // ── زرار الجنيريت ──
        ElevatedButton.icon(
          onPressed: _generate,
          icon:  Icon(Icons.key_rounded, size: 22),
          label:  Text('توليد كود التفعيل'.tr(), style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            padding:  EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
         SizedBox(height: 20),

        // ── عرض الكود المولَّد ──
        if (_generatedCode != null) ...[
          Card(
            color: Colors.green[50],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   Text('كود التفعيل:'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  SelectableText(
                    _generatedCode!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 22,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        _isLifetime
                            ? 'ترخيص دائم مدى الحياة'.tr()
                            : 'صالح لمدة ${int.tryParse(_customDaysCtrl.text) ?? _selectedDays} يوم',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _copyCode,
                      icon: Icon(
                          _justCopied ? Icons.check : Icons.copy_rounded),
                      label: Text(_justCopied ? 'تم النسخ!'.tr() : 'نسخ الكود'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _justCopied ? Colors.green : Colors.blueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
