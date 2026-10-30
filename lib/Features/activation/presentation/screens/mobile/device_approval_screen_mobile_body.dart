part of '../device_approval_screen.dart';

/// جسم شاشة موافقة الأجهزة — نسخة الموبايل (زي ما كانت بالظبط).
extension _DeviceApprovalScreenMobileBody on _DeviceApprovalScreenState {
  Widget _buildMobileBody(BuildContext context) {
    if (_checkingDevice) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isMasterDevice) {
      return Scaffold(
        appBar: AppBar(title: Text('غير مسموح'.tr())),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'هذه الصفحة متاحة فقط من جهاز المهندس المعتمد'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    if (!_loggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text('تسجيل دخول المهندس'.tr())),
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'الإيميل'.tr()),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _passCtrl,
                obscureText: true,
                decoration: InputDecoration(labelText: 'كلمة السر'.tr()),
              ),
              SizedBox(height: 16),
              if (_loginError != null)
                Text(_loginError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              _loginLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _login, child: Text('دخول'.tr())),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('طلبات تفعيل الأجهزة'.tr()),
        actions: [
          IconButton(onPressed: _loadRequests, icon: Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // 🆕 حظر جهاز بالكود مباشرة (حتى لو لسه ما طلبش تفعيل)
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _blockHashCtrl,
                    decoration: InputDecoration(
                      labelText: 'كود جهاز تحب تحظره'.tr(),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                _blocking
                    ? Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                    : ElevatedButton(
                      onPressed: _blockManually,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text('حظر'.tr()),
                    ),
              ],
            ),
          ),
          Divider(height: 20),
          Expanded(
            child:
                _loadingRequests
                    ? Center(child: CircularProgressIndicator())
                    : _loadError != null
                    ? Center(
                      child: Text(
                        _loadError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                    : _requests.isEmpty
                    ? Center(child: Text('لا توجد طلبات حاليًا'.tr()))
                    : ListView.builder(
                      itemCount: _requests.length,
                      itemBuilder: (context, index) {
                        final row = _requests[index];
                        final hash = row['device_hash'] as String;
                        final status = row['status'] as String;

                        return Card(
                          margin: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SelectableText(
                                  hash,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                          status,
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _statusLabel(status),
                                        style: TextStyle(
                                          color: _statusColor(status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      row['requested_at']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (status == 'approved') ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (row['license_type'] == 'demo'
                                                  ? Colors.amber
                                                  : Colors.blue)
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          row['license_type'] == 'demo'
                                              ? 'تجريبي (ديمو )'.tr()
                                              : 'دائم (مدى الحياة)'.tr(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                row['license_type'] == 'demo'
                                                    ? Colors.amber.shade800
                                                    : Colors.blue.shade800,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (status != 'approved') ...[
                                      ElevatedButton.icon(
                                        onPressed:
                                            () => _approve(
                                              hash,
                                              licenseType: 'lifetime',
                                            ),
                                        icon: const Icon(Icons.check, size: 18),
                                        label: Text('تفعيل دائم (شراء)'.tr()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed:
                                            () => _showDemoApprovalDialog(hash),
                                        icon: Icon(Icons.access_time, size: 18),
                                        label: Text('تفعيل تجريبي (ديمو)'.tr()),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade700,
                                        ),
                                      ),
                                    ] else ...[
                                      if (row['license_type'] == 'demo')
                                        ElevatedButton.icon(
                                          onPressed:
                                              () => _approve(
                                                hash,
                                                licenseType: 'lifetime',
                                              ),
                                          icon: const Icon(
                                            Icons.verified,
                                            size: 18,
                                          ),
                                          label: Text(
                                            'تحويل لدائم (شراء)'.tr(),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                      OutlinedButton.icon(
                                        onPressed:
                                            () => _showDemoApprovalDialog(hash),
                                        icon: const Icon(
                                          Icons.update,
                                          size: 18,
                                        ),
                                        label: Text('تعديل مدة التجربة'.tr()),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _revoke(hash),
                                        icon: Icon(Icons.block, size: 18),
                                        label: Text('إلغاء التفعيل'.tr()),
                                      ),
                                    ],
                                    if (status != 'rejected' &&
                                        status != 'approved')
                                      OutlinedButton.icon(
                                        onPressed: () => _reject(hash),
                                        icon: const Icon(Icons.close, size: 18),
                                        label: Text('رفض'.tr()),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
