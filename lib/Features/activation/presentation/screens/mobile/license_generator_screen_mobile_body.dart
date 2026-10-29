part of '../license_generator_screen.dart';

/// جسم شاشة مولد أكواد التفعيل — نسخة الموبايل (زي ما كانت بالظبط).
extension _LicenseGeneratorScreenMobileBody on _LicenseGeneratorScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title:  Text('مولد أكواد التفعيل'.tr())),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 70),

                    const SizedBox(height: 20),

                     Text(
                      'مولد كود التفعيل'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                     Text(
                      'كود جهاز العميل'.tr(),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _deviceController,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.center,
                      decoration:  InputDecoration(
                        hintText: 'أدخل Device ID'.tr(),
                        prefixIcon: Icon(Icons.computer),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                     Text(
                      'مدة الترخيص'.tr(),
                      textAlign: TextAlign.right,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<int>(
                      value: _days,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: _durations.map((item) {
                        return DropdownMenuItem<int>(
                          value: item['days'] as int,
                          child: Text(item['label'] as String),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _refresh(() {
                            _days = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.key),
                        label:  Text(
                          'توليد كود التفعيل'.tr(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    if (_generatedCode.isNotEmpty) ...[
                      const SizedBox(height: 30),

                      const Divider(),

                      const SizedBox(height: 20),

                       Text(
                        'كود التفعيل للعميل'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: SelectableText(
                          _generatedCode,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      OutlinedButton.icon(
                        onPressed: _copyCode,
                        icon: const Icon(Icons.copy),
                        label:  Text('نسخ كود التفعيل'.tr()),
                      ),
                    ],
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
