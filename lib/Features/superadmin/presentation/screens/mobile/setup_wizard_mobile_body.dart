part of '../setup_wizard.dart';

/// جسم معالج التهيئة — نسخة الموبايل.
///
/// إطار غامر (Aurora) بهيدر خطوات مدمج، محتوى متحرك بين الخطوات،
/// وشريط تنقل سفلي ثابت.
extension _SetupWizardMobileBody on _SetupWizardScreenState {
  Widget _buildMobileBody(BuildContext context) {
    final skin = _WizSkin.of(context);
    if (_loading) return _wizLoading(context);
    if (_finished) return _wizSuccessScreen(context, isDesktop: false);

    final info = _wizSteps[_step];

    return Scaffold(
      backgroundColor: skin.bg,
      body: _Aurora(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _RoundIconButton(
                          icon:
                              _step == 0
                                  ? Icons.close_rounded
                                  : Icons.arrow_back_rounded,
                          tooltip: _step == 0 ? 'إغلاق'.tr() : 'السابق',
                          onTap:
                              _step == 0
                                  ? () => Navigator.maybePop(context)
                                  : () => _refresh(() => _step--),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SAYTARLY · SETUP STUDIO',
                                style: TextStyle(
                                  color: skin.accentText,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.8,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                info.title,
                                style: TextStyle(
                                  color: skin.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_step + 1} / ${_wizSteps.length}',
                          style: TextStyle(
                            color: skin.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _wizProgressBar(skin),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_step),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                      children: [_wizStepBody(context)],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                decoration: BoxDecoration(
                  color: skin.bg.withValues(alpha: 0.72),
                  border: Border(top: BorderSide(color: skin.border)),
                ),
                child: _wizFooter(context, skin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
