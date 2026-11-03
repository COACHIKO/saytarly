part of '../setup_wizard.dart';

/// جسم معالج التهيئة — نسخة الويندوز.
///
/// تخطيط عمودين: ريل خطوات على الشمال (مع إمكانية القفز لأي خطوة)،
/// وكارت محتوى كبير على اليمين فيه الخطوة الحالية والفوتر.
extension _SetupWizardWindowsBody on _SetupWizardScreenState {
  Widget _buildWindowsBody(BuildContext context) {
    final skin = _WizSkin.of(context);
    if (_loading) return _wizLoading(context);
    if (_finished) return _wizSuccessScreen(context, isDesktop: true);

    return Scaffold(
      backgroundColor: skin.bg,
      body: _Aurora(
        child: SafeArea(
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                Navigator.maybePop(context);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _wizTopBar(context, skin),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _wizRail(context, skin),
                            const SizedBox(width: 16),
                            Expanded(child: _wizContent(context, skin)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _wizTopBar(BuildContext context, _WizSkin skin) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: skin.glass,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: skin.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 13, color: skin.accentText),
              const SizedBox(width: 6),
              Text(
                'SAYTARLY',
                style: TextStyle(
                  color: skin.text,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'بيانات المكان'.tr(),
          style: TextStyle(
            color: skin.text,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '· ${_wizSteps[_step].title}',
          style: TextStyle(color: skin.muted, fontSize: 12),
        ),
        const Spacer(),
        Text(
          '${_step + 1} / ${_wizSteps.length}',
          style: TextStyle(
            color: skin.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        _RoundIconButton(
          icon: Icons.close_rounded,
          tooltip: 'إغلاق'.tr(),
          onTap: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  Widget _wizRail(BuildContext context, _WizSkin skin) {
    return Container(
      width: 276,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: skin.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: skin.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رحلة التهيئة'.tr(),
                  style: TextStyle(
                    color: skin.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '٧ خطوات · حوالي دقيقتين'.tr(),
                  style: TextStyle(color: skin.faint, fontSize: 10.5),
                ),
                const SizedBox(height: 10),
                _wizProgressBar(skin, height: 5),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _wizSteps.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) => _wizRailItem(context, skin, i),
            ),
          ),
          Container(
            height: 1,
            color: skin.border,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: skin.faint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'حساب السوبر ادمن محمي'.tr(),
                    style: TextStyle(color: skin.faint, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _wizRailItem(BuildContext context, _WizSkin skin, int i) {
    final active = i == _step;
    final done = i < _step;
    final info = _wizSteps[i];

    return GestureDetector(
      onTap: () => _jumpTo(i),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: active ? skin.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  active
                      ? skin.accent.withValues(alpha: 0.5)
                      : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      active
                          ? skin.accent
                          : (done
                              ? skin.success.withValues(alpha: 0.18)
                              : skin.glass),
                  border: Border.all(
                    color:
                        active
                            ? skin.accent
                            : (done
                                ? skin.success.withValues(alpha: 0.5)
                                : skin.border),
                  ),
                ),
                alignment: Alignment.center,
                child:
                    done && !active
                        ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: skin.success,
                        )
                        : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: active ? skin.onAccent : skin.faint,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active || done ? skin.text : skin.muted,
                        fontSize: 12,
                        fontWeight:
                            active ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      info.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: skin.faint, fontSize: 9.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wizContent(BuildContext context, _WizSkin skin) {
    return Container(
      decoration: BoxDecoration(
        color: skin.glass,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: skin.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 26, 28, 12),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: _wizStepBody(context),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 18),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: skin.border)),
            ),
            child: _wizFooter(context, skin),
          ),
        ],
      ),
    );
  }
}
