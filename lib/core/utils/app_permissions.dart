enum AppPermission {
  crm,
  reporting,
  marketing,
  sales,
  inventory,
  activity,
  support,
  calendar,
  ivr,
  sms,
  unknown;

  static AppPermission fromString(String value) {
    switch (value.toLowerCase()) {
      case 'crm':
        return AppPermission.crm;
      case 'reporting':
        return AppPermission.reporting;
      case 'marketing':
        return AppPermission.marketing;
      case 'sales':
        return AppPermission.sales;
      case 'inventory':
        return AppPermission.inventory;
      case 'activity':
        return AppPermission.activity;
      case 'support':
        return AppPermission.support;
      case 'calendar':
        return AppPermission.calendar;
      case 'ivr':
        return AppPermission.ivr;
      case 'sms':
        return AppPermission.sms;
      default:
        return AppPermission.unknown;
    }
  }
}
