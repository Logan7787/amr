import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../core/app_constants.dart';
import '../core/localization_service.dart';
import '../core/security_service.dart';
import '../data/repository.dart';
import 'thermal_printer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _gstController = TextEditingController();
  final _prefixController = TextEditingController();
  final _taxController = TextEditingController();
  final _termsController = TextEditingController();
  final _upiIdController = TextEditingController();
  final _merchantNameController = TextEditingController();
  String? _logoPath;
  bool _isLockEnabled = false;
  bool _isLoading = true;
  final SecurityService _securityService = SecurityService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString(AppConstants.keyCompanyName) ?? '';
      _addressController.text =
          prefs.getString(AppConstants.keyCompanyAddress) ?? '';
      _mobileController.text =
          prefs.getString(AppConstants.keyCompanyMobile) ?? '';
      _gstController.text = prefs.getString(AppConstants.keyCompanyGst) ?? '';
      _prefixController.text =
          prefs.getString(AppConstants.keyInvoicePrefix) ?? 'INV';
      _taxController.text = prefs.getString(AppConstants.keyTaxRate) ?? '0';
      _termsController.text =
          prefs.getString(AppConstants.keyTermsConditions) ?? '';
      _logoPath = prefs.getString(AppConstants.keyLogoPath);
      _upiIdController.text = prefs.getString(AppConstants.keyUpiId) ?? '';
      _merchantNameController.text =
          prefs.getString(AppConstants.keyMerchantName) ?? '';
      _isLockEnabled = prefs.getBool(AppConstants.keyLockEnabled) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final repo = DataRepository();

    await prefs.setString(AppConstants.keyCompanyName, _nameController.text);
    await repo.updateSetting(AppConstants.keyCompanyName, _nameController.text);

    await prefs.setString(
      AppConstants.keyCompanyAddress,
      _addressController.text,
    );
    await repo.updateSetting(
      AppConstants.keyCompanyAddress,
      _addressController.text,
    );

    await prefs.setString(
      AppConstants.keyCompanyMobile,
      _mobileController.text,
    );
    await repo.updateSetting(
      AppConstants.keyCompanyMobile,
      _mobileController.text,
    );

    await prefs.setString(AppConstants.keyCompanyGst, _gstController.text);
    await repo.updateSetting(AppConstants.keyCompanyGst, _gstController.text);

    await prefs.setString(
      AppConstants.keyInvoicePrefix,
      _prefixController.text,
    );
    await repo.updateSetting(
      AppConstants.keyInvoicePrefix,
      _prefixController.text,
    );

    await prefs.setString(AppConstants.keyTaxRate, _taxController.text);
    await repo.updateSetting(AppConstants.keyTaxRate, _taxController.text);

    await prefs.setString(
      AppConstants.keyTermsConditions,
      _termsController.text,
    );
    await repo.updateSetting(
      AppConstants.keyTermsConditions,
      _termsController.text,
    );

    await prefs.setString(AppConstants.keyUpiId, _upiIdController.text);
    await repo.updateSetting(AppConstants.keyUpiId, _upiIdController.text);

    await prefs.setString(
      AppConstants.keyMerchantName,
      _merchantNameController.text,
    );
    await repo.updateSetting(
      AppConstants.keyMerchantName,
      _merchantNameController.text,
    );

    if (_logoPath != null) {
      await prefs.setString(AppConstants.keyLogoPath, _logoPath!);
      await repo.updateSetting(AppConstants.keyLogoPath, _logoPath!);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved & Synced Successfully')));
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('settings'))),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Company Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter company name' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _mobileController,
                      decoration: InputDecoration(
                        labelText: 'Mobile',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _gstController,
                      decoration: InputDecoration(
                        labelText: 'GST No (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prefixController,
                            decoration: InputDecoration(
                              labelText: 'Invoice Prefix',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _taxController,
                            decoration: InputDecoration(
                              labelText: 'Tax Rate (%)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _termsController,
                      decoration: InputDecoration(
                        labelText: loc.translate('terms_conditions'),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Payment Settings (UPI)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _upiIdController,
                      decoration: InputDecoration(
                        labelText: loc.translate('upi_id'),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. name@upi',
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _merchantNameController,
                      decoration: InputDecoration(
                        labelText: loc.translate('merchant_name'),
                        border: OutlineInputBorder(),
                        hintText: 'e.g. AMR Enterprises',
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(height: 16),
                    // Logo Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(loc.translate('company_logo')),
                      subtitle: Text(_logoPath ?? 'No Logo Selected'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(type: FileType.image);
                          if (result != null) {
                            setState(
                              () => _logoPath = result.files.single.path,
                            );
                          }
                        },
                        child: Text('Pick Logo'),
                      ),
                    ),
                    if (_logoPath != null) ...[
                      SizedBox(height: 8),
                      Image.file(File(_logoPath!), height: 100),
                    ],

                    ListTile(
                      leading: Icon(Icons.print_rounded),
                      title: Text('Thermal Printer'),
                      subtitle: Text('Setup Bluetooth thermal printer'),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ThermalPrinterScreen(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 32),
                    SwitchListTile(
                      title: Text('App Lock (Biometric/PIN)'),
                      subtitle: Text('Secure the app with your device lock'),
                      value: _isLockEnabled,
                      onChanged: (bool value) async {
                        if (value) {
                          // Try to authenticate before enabling
                          bool authenticated = await _securityService
                              .authenticate();
                          if (authenticated) {
                            setState(() => _isLockEnabled = value);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(
                              AppConstants.keyLockEnabled,
                              true,
                            );
                          }
                        } else {
                          setState(() => _isLockEnabled = value);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool(
                            AppConstants.keyLockEnabled,
                            false,
                          );
                        }
                      },
                    ),

                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        child: Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
