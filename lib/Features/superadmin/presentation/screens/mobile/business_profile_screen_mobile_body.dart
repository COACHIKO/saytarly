part of '../business_profile_screen.dart';

/// جسم شاشة الملف التجاري — نسخة الموبايل (زي ما كانت بالظبط).
extension _BusinessProfileMobileBody on _BusinessProfileScreenState {
  Widget _buildMobileBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الملف التجاري'.tr())),
      body:
          _loading
              ? Center(child: CircularProgressIndicator())
              : ListView(
                padding: EdgeInsets.all(20),
                children: [
                  // ==================== 🖼️ لوجو البراند ====================
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.grey.shade200,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child:
                            _logoPath != null
                                ? Image.file(
                                  File(_logoPath!),
                                  fit: BoxFit.cover,
                                )
                                : Image.asset(
                                  BusinessProfile.defaultLogoAsset,
                                  fit: BoxFit.cover,
                                ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'لوجو البراند'.tr(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _logoPath == null
                                  ? 'اللوجو الافتراضي مستخدم — بيظهر في الفواتير وسايدبار الوندوز'
                                      .tr()
                                  : 'اللوجو المخصوص مستخدم — بيظهر في الفواتير وسايدبار الوندوز'
                                      .tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'اختيار صورة'.tr(),
                        onPressed: _pickingLogo ? null : _pickLogo,
                        icon: Icon(Icons.image_outlined),
                      ),
                      IconButton(
                        tooltip: 'إزالة اللوجو المخصوص'.tr(),
                        onPressed: _logoPath == null ? null : _clearLogo,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameCtl,
                    decoration: InputDecoration(
                      labelText: 'اسم المكان'.tr(),
                      prefixIcon: Icon(Icons.storefront),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'نوع النشاط'.tr(),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        BusinessProfile.typeLabels.entries.map((e) {
                          final selected = _type == e.key;
                          return ChoiceChip(
                            label: Text(e.value),
                            selected: selected,
                            onSelected:
                                (_) => _refresh(() {
                                  _type = e.key;
                                  if (e.key == 'playstation_cafe')
                                    _playstation = true;
                                }),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    value: _playstation,
                    onChanged: (v) => _refresh(() => _playstation = v),
                    title: Text('نظام البلايستيشن مفعّل'.tr()),
                    subtitle: Text(
                      'بيتحكم في ظهور كروت إدارة الأجهزة وتقرير البلايستيشن في لوحة الأدمن'
                          .tr(),
                      style: TextStyle(fontSize: 12),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text('حفظ'.tr()),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
    );
  }
}
