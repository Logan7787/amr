import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/app_constants.dart';
import '../core/localization_service.dart';
import 'dashboard.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final bool isFirstRun;

  const LanguageSelectionScreen({super.key, this.isFirstRun = false});

  @override
  Widget build(BuildContext context) {
    var localization = Provider.of<LocalizationService>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder or Icon
              Icon(
                Icons.language,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 32),
              Text(
                localization.translate('select_language'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 32),

              // Tamil Option
              _LanguageCard(
                title: 'தமிழ்',
                subtitle: 'Tamil',
                isSelected: localization.locale.languageCode == 'ta',
                onTap: () {
                  localization.changeLanguage(Locale('ta'));
                },
              ),
              SizedBox(height: 16),

              // English Option
              _LanguageCard(
                title: 'English',
                subtitle: 'English',
                isSelected: localization.locale.languageCode == 'en',
                onTap: () {
                  localization.changeLanguage(Locale('en'));
                },
              ),

              SizedBox(height: 48),

              if (isFirstRun)
                ElevatedButton(
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool(AppConstants.keyFirstRun, false);
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Dashboard(),
                      ),
                    );
                  },
                  child: Text('Continue / தொடரவும்'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
