// lib/Screens/admin/device_approval_screen.dart
//
// شاشة موافقة الأجهزة — تشتغل فعليًا بس لو الجهاز الحالي موجود في kMasterDevices
// (يعني موبايلك بالتحديد). كمان بتطلب تسجيل دخول Supabase Auth عشان الـ RLS
// بيسمح بالـ update بس للمستخدمين الـ authenticated.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:saytarly/core/desktop/desktop.dart';

import 'package:saytarly/Features/activation/data/device_activation_service.dart';
import 'package:saytarly/core/constants/master_devices.dart';
import 'package:saytarly/core/utils/DeviceFingerprint.dart' show DeviceFingerprint;
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/device_approval_screen_mobile_body.dart';
part 'desktop/device_approval_screen_windows_body.dart';

class DeviceApprovalScreen extends StatefulWidget {
  const DeviceApprovalScreen({super.key});

  @override
  State<DeviceApprovalScreen> createState() => _DeviceApprovalScreenState();
}

class _DeviceApprovalScreenState extends State<DeviceApprovalScreen> {
  bool _checkingDevice = true;
  bool _isMasterDevice = false;

  bool _loggedIn = false;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loginLoading = false;
  String? _loginError;

  bool _loadingRequests = false;
  List<Map<String, dynamic>> _requests = [];
  String? _loadError;

  final _blockHashCtrl = TextEditingController(); // 🆕 حظر بالكود مباشرة
  bool _blocking = false;

  @override
  void initState() {
    super.initState();
    _initDeviceCheck();
  }

  Future<void> _initDeviceCheck() async {
    final hash = await DeviceFingerprint.deviceId();
    setState(() {
      _isMasterDevice = kMasterDevices.contains(hash);
      _checkingDevice = false;
      _loggedIn = Supabase.instance.client.auth.currentSession != null;
    });
    if (_isMasterDevice && _loggedIn) {
      _loadRequests();
    }
  }

  Future<void> _login() async {
    setState(() {
      _loginLoading = true;
      _loginError = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      setState(() {
        _loggedIn = true;
        _loginLoading = false;
      });
      _loadRequests();
    } catch (e) {
      debugPrint('Login error: $e'); // 🆕 يطبع السبب الحقيقي في الكونسول
      setState(() {
        _loginError = 'فشل تسجيل الدخول: {e}'.tr({'e': e}); // 🆕 يظهر السبب على الشاشة كمان
        _loginLoading = false;
      });
    }
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loadingRequests = true;
      _loadError = null;
    });
    try {
      final rows = await DeviceActivationService.fetchAllRequests();
      setState(() {
        _requests = rows;
        _loadingRequests = false;
      });
    } catch (e) {
      debugPrint('Load requests error: $e'); // 🆕
      setState(() {
        _loadError = 'فشل تحميل الطلبات: {e}'.tr({'e': e}); // 🆕
        _loadingRequests = false;
      });
    }
  }

  Future<void> _approve(
    String hash, {
    String licenseType = 'lifetime',
    DateTime? expiresAt,
  }) async {
    await DeviceActivationService.approveDevice(
      hash,
      licenseType: licenseType,
      expiresAt: expiresAt,
    );
    _loadRequests();
  }

  Future<void> _showDemoApprovalDialog(String hash) async {
    int selectedDays = 7;
    final customDaysCtrl = TextEditingController(text: '7');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AppDialog(
            title:  Text('تفعيل تجريبي (ديمو)'.tr(), textAlign: TextAlign.right),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                 Text(
                  'حدد مدة التجربة بالإنترنت. بعد انتهاء المدة سيتم قفل السيستم تلقائياً:'.tr(),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [3, 7, 14, 30].map((d) {
                    final isSel = selectedDays == d;
                    return ChoiceChip(
                      label: Text('{d} أيام'.tr({'d': d})),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) {
                          setDialogState(() {
                            selectedDays = d;
                            customDaysCtrl.text = d.toString();
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: customDaysCtrl,
                  keyboardType: TextInputType.number,
                  decoration:  InputDecoration(
                    labelText: 'أو حدد عدد الأيام يدوياً'.tr(),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != null && parsed > 0) {
                      setDialogState(() => selectedDays = parsed);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child:  Text('إلغاء'.tr()),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: () {
                  final days = int.tryParse(customDaysCtrl.text) ?? selectedDays;
                  final expiresAt = DateTime.now().add(Duration(days: days));
                  Navigator.pop(ctx);
                  _approve(hash, licenseType: 'demo', expiresAt: expiresAt);
                },
                child: Text('تفعيل ({selectedDays} يوم)'.tr({'selectedDays': selectedDays})),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _reject(String hash) async {
    await DeviceActivationService.rejectDevice(hash);
    _loadRequests();
  }

  Future<void> _revoke(String hash) async {
    await DeviceActivationService.revokeDevice(hash);
    _loadRequests();
  }

  Future<void> _blockManually() async {
    final hash = _blockHashCtrl.text.trim();
    if (hash.isEmpty) return;
    setState(() => _blocking = true);
    try {
      await DeviceActivationService.blockDeviceByHash(hash);
      _blockHashCtrl.clear();
      await _loadRequests();
    } finally {
      setState(() => _blocking = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'مفعّل'.tr();
      case 'pending':
        return 'في الانتظار'.tr();
      case 'rejected':
        return 'مرفوض'.tr();
      case 'revoked':
        return 'مسحوب'.tr();
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    // نفس الشاشة ونفس المنطق — بس الجسم بيتبدّل حسب الجهاز.
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}

