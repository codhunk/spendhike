import 'package:flutter/material.dart';

enum AppLanguage { english, hindi }

class AppSettings extends ChangeNotifier {
  static final AppSettings instance = AppSettings._internal();
  AppSettings._internal();

  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.english;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppLanguage get language => _language;
  bool get isHindi => _language == AppLanguage.hindi;

  void setTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  void toggleLanguage() {
    _language = _language == AppLanguage.english ? AppLanguage.hindi : AppLanguage.english;
    notifyListeners();
  }

  /// Comprehensive Hindi (हिन्दी) translation lookup
  static final Map<String, String> _hindiDict = {
    // Navigation & General
    'Dashboard': 'डैशबोर्ड',
    'Groups': 'ग्रुप लेजर',
    'Reports': 'रिपोर्ट्स',
    'Profile': 'प्रोफ़ाइल',
    'New Transaction': 'नया लेन-देन',
    'Add Entry': 'प्रविष्टि जोड़ें',
    'Notifications': 'सूचनाएं',
    'Search': 'खोजें',

    // Dashboard
    'Total Balance': 'कुल शेष (Balance)',
    'Total Received': 'कुल प्राप्त आय',
    'Total Spent': 'कुल खर्च (Debit)',
    'Pending Credit': 'क्रेडिट / उधार',
    'Weekly Trend': 'साप्ताहिक रुझान',
    'Active Sites / Projects': 'सक्रिय साइट्स और प्रोजेक्ट',
    'Recent Activities': 'हाल की गतिविधियां',
    'View All': 'सभी देखें',
    'Add New Site': 'नयी साइट जोड़ें',
    'Labour': 'मज़दूरी',
    'Material': 'सामग्री',
    'Fuel': 'ईंधन',
    'Other': 'अन्य',

    // Groups & Ledgers
    'Project Ledgers': 'प्रोजेक्ट लेजर',
    'Create New Group Ledger': 'नया ग्रुप लेजर बनाएं',
    'Group / Site Name': 'ग्रुप / साइट का नाम',
    'Search Groups...': 'ग्रुप खोजें...',
    'Active Ledgers': 'सक्रिय लेजर',
    'Members': 'सदस्य',
    'Add Member': 'सदस्य जोड़ें',
    'Role': 'भूमिका',
    'Admin': 'एडमिन',
    'Editor': 'संपादक',
    'Viewer': 'दर्शक',
    'Send Invitation': 'निमंत्रण भेजें',
    'Confirm & Save': 'पुष्टि करें और सहेजें',

    // Reports
    'Financial Analytics & Reports': 'वित्तीय विश्लेषण और रिपोर्ट',
    'Income vs Expenses': 'आय बनाम खर्च',
    'Category Breakdown': 'श्रेणी वार विवरण',
    'Monthly Summary': 'मासिक सारांश',
    'Download PDF Report': 'पीडीएफ रिपोर्ट डाउनलोड करें',
    'Download Excel / CSV': 'एक्सेल / सीएसवी डाउनलोड करें',

    // Profile & Settings
    'Profile & Account': 'प्रोफ़ाइल और खाता',
    'Personal Details': 'व्यक्तिगत विवरण',
    'Business Details': 'व्यवसाय विवरण',
    'Security & Privacy': 'सुरक्षा और गोपनीयता',
    'App Settings': 'ऐप सेटिंग्स',
    'Data & Backup': 'डेटा और बैकअप',
    'Legal & Support': 'कानूनी और सहायता',
    'Dark Mode': 'डार्क मोड',
    'Language': 'भाषा',
    'Hindi (हिन्दी)': 'हिन्दी (Hindi)',
    'English (IN)': 'अंग्रेज़ी (English)',
    'Biometric Unlock': 'बायोमेट्रिक अनलॉक',
    'PIN Code Unlock': 'पिन कोड अनलॉक',
    'Set PIN Code': 'पिन कोड सेट करें',
    'Enter 4-digit PIN': '4 अंकों का पिन दर्ज करें',
    'Forgot / Change Password': 'पासवर्ड भूल गए / बदलें',
    'Current Password': 'वर्तमान पासवर्ड',
    'New Password': 'नया पासवर्ड',
    'Confirm New Password': 'नए पासवर्ड की पुष्टि करें',
    'Reset Password': 'पासवर्ड रीसेट करें',
    'Edit Profile Image': 'प्रोफ़ाइल चित्र बदलें',
    'Profile Image URL': 'प्रोफ़ाइल छवि यूआरएल',
    'Enter Image URL': 'छवि का यूआरएल दर्ज करें',
    'Name': 'नाम',
    'Email Address': 'ईमेल पता',
    'Mobile Number': 'मोबाइल नंबर',
    'Company Name': 'कंपनी का नाम',
    'GST Number': 'जीएसटी नंबर',
    'Business Address': 'व्यवसाय का पता',
    'Save Changes': 'बदलाव सहेजें',
    'Cancel': 'रद्द करें',
    'Log Out': 'लॉग आउट',
    'Are you sure you want to log out?': 'क्या आप सचमुच लॉग आउट करना चाहते हैं?',
    'Updated successfully!': 'सफलतापूर्वक अपडेट किया गया!',
    'Failed to update': 'अपडेट करने में विफल',
    'Password changed successfully!': 'पासवर्ड सफलतापूर्वक बदला गया!',
    'Passwords do not match': 'पासवर्ड मेल नहीं खाते',
    'Project Ledger': 'प्रोजेक्ट लेजर',
    'Sync Status': 'सिंक स्थिति',
    'Live Connected': 'लाइव कनेक्टेड',
    'Local Mode': 'लोकल मोड',
    'Privacy Policy': 'गोपनीयता नीति',
    'Terms of Service': 'सेवा की शर्तें',
    'Export Data (CSV/Excel)': 'डेटा निर्यात (CSV/Excel)',
    'Automatic Cloud Sync': 'स्वचालित क्लाउड सिंक',

    // Auth
    'Login': 'लॉगिन',
    'Sign Up': 'साइन अप',
    'FULL NAME': 'पूरा नाम',
    'EMAIL ADDRESS': 'ईमेल पता',
    'MOBILE NUMBER': 'मोबाइल नंबर',
    'PASSWORD': 'पासवर्ड',
    'Forgot Password?': 'पासवर्ड भूल गए?',
    'OR CONTINUE WITH': 'या इसके साथ जारी रखें',
  };

  /// Translate helper
  String tr(String text) {
    if (_language == AppLanguage.hindi) {
      return _hindiDict[text] ?? text;
    }
    return text;
  }
}
