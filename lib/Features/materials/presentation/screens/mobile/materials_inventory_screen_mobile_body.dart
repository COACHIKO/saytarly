part of '../MaterialsInventoryScreen.dart';

/// جسم جرد الخامات — نسخة الموبايل (زي ما كانت بالظبط).
extension _MaterialsInventoryScreenMobileBody on _MaterialsInventoryScreenState {

  Widget _buildMobileBody(BuildContext context) {
    final shortageCount = reports.where((e) => e.isShortage).length;

    final excessCount = reports.where((e) => e.isExcess).length;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: printPdf,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: approveInventory,
          ),
          IconButton(
            icon: const Icon(Icons.all_inclusive_outlined),
            onPressed: loadReport,
          ),
        ],
        title:  Text('جرد الخامات'.tr()),
      ),
      body: Column(
        children: [
          _summary(shortageCount, excessCount),
          /*        _dateFilter(),*/
          Expanded(
            child: ListView.builder(
              itemCount: reports.length,
              itemBuilder: (_, index) {
                return _buildCard(reports[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(
    int shortageCount,
    int excessCount,
  ) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statCard(
            'الخامات'.tr(),
            reports.length.toString(),
            Icons.inventory_2,
          ),
          _statCard(
            'عجز'.tr(),
            shortageCount.toString(),
            Icons.trending_down,
          ),
          _statCard(
            'زيادة'.tr(),
            excessCount.toString(),
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Future<void> pickFromDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (d != null) {
      _refresh(() {
        fromDate = d;
      });
    }
  }

  Future<void> pickToDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (d != null) {
      _refresh(() {
        toDate = d;
      });
    }
  }

  Widget _dateFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      child: Row(
        children: [
/*          Expanded(
            child: OutlinedButton.icon(
              onPressed: pickFromDate,
              icon: const Icon(Icons.date_range),
              label: Text(
                fromDate == null ? "من" : fromDate!.toString().substring(0, 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: pickToDate,
              icon: const Icon(Icons.date_range),
              label: Text(
                toDate == null ? "إلى" : toDate!.toString().substring(0, 10),
              ),
            ),
          ),
          const SizedBox(width: 10),*/
          /*  ElevatedButton(
            onPressed: loadReport,
            child: const Text("عرض"),
          ),*/
        ],
      ),
    );
  }

  Widget _buildCard(
    InventoryReportModel report,
  ) {
    controllers.putIfAbsent(
      report.materialId,
      () => TextEditingController(
        text: report.actualQty.toString(),
      ),
    );

    final controller = controllers[report.materialId]!;
    Color varianceColor;

    if (report.variance == 0) {
      varianceColor = Colors.white;
    } else if (report.variance > 0) {
      varianceColor = Colors.green;
    } else {
      varianceColor = Colors.red;
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              report.materialName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _row(
              'رصيد أول الفترة'.tr(),
              "${report.openingQty} ${report.unit}",
            ),
            _row(
              'المضاف للمخزن'.tr(),
              "${report.purchasesQty} ${report.unit}",
            ),
            _row(
              'إجمالي المتاح'.tr(),
              "${report.openingQty + report.purchasesQty} ${report.unit}",
            ),
            _row(
              'الاستهلاك'.tr(),
              "${report.consumedQty} ${report.unit}",
            ),
            _row(
              'رصيد النظام'.tr(),
              "${report.systemQty} ${report.unit}",
            ),
            const SizedBox(height: 15),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: controller,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الرصيد الفعلي'.tr(),
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                  suffixText: report.unit,
                  suffixStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  filled: true,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.edit_note,
                    color: Colors.green,
                  ),
                ),
                onChanged: (v) {
                  report.actualQty = double.tryParse(v) ?? report.systemQty;

                  _refresh(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: varianceColor.withOpacity(.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                   Text('الفرق : '.tr()),
                  Text(
                    report.variance > 0
                        ? "+${report.variance}"
                        : report.variance.toString(),
                    style: TextStyle(
                      color: varianceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title),
      ],
    );
  }
}

