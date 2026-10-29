part of '../activation_screen.dart';

/// جسم شاشة التفعيل — نسخة الموبايل (زي ما كانت بالظبط).
extension _ActivationScreenMobileBody on _ActivationScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final isExpired = widget.isExpired;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── أيقونة ──
                    Icon(
                      isExpired ? Icons.timer_off_rounded : Icons.lock_open_rounded,
                      size: 72,
                      color: isExpired ? Colors.orange : Colors.blueAccent,
                    ),
                    const SizedBox(height: 16),

                    // ── عنوان ──
                    Text(
                      isExpired ? 'انتهت مدة الترخيص'.tr() : 'تفعيل البرنامج',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isExpired ? Colors.orange : Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isExpired
                          ? 'تواصل مع المهندس للتجديد وأرسله كود الجهاز أدناه'.tr()
                          : 'أرسل كود الجهاز للمهندس وادخل كود التفعيل الذي سيرسله لك',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // ── كود الجهاز ──
                     Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'كود هذا الجهاز:'.tr(),
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _loadingId
                          ? const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : SelectableText(
                              _deviceId,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            Clipboard.setData(ClipboardData(text: _deviceId)),
                        icon: const Icon(Icons.copy, size: 16),
                        label:  Text('نسخ كود الجهاز'.tr()),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── حقل كود التفعيل ──
                     Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'كود التفعيل (من المهندس):'.tr(),
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _codeCtrl,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 16,
                        letterSpacing: 2,
                      ),
                      decoration: InputDecoration(
                        hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        errorText: _errorMsg,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste_rounded),
                          tooltip: 'لصق'.tr(),
                          onPressed: () async {
                            final data =
                                await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              _codeCtrl.text = data!.text!.trim();
                            }
                          },
                        ),
                      ),
                    ),
                     SizedBox(height: 16),

                    // ── رسالة نجاح ──
                    if (_successMsg != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_successMsg!,
                                  style:
                                      const TextStyle(color: Colors.green)),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // ── زرار التفعيل ──
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _activating ? null : _activate,
                        icon: _activating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.verified_rounded),
                        label: Text(
                          _activating ? 'جاري التفعيل...'.tr() : 'تفعيل البرنامج',
                          style: const TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── معلومات الاتصال ──
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Eng: Waled Mabrok',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.phone, size: 16, color: Colors.green),
                        SizedBox(width: 6),
                        Text('01032548232',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
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
}
