import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/utils/image_url_helper.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _ntnCnicCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _accountTitleCtrl;
  late final TextEditingController _accountNumberCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _ibanCtrl;
  late final TextEditingController _branchNameCtrl;
  late final TextEditingController _branchCodeCtrl;
  late final TextEditingController _registrationCtrl;
  late final TextEditingController _contactNumberCtrl;
  late final TextEditingController _contactPersonCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _swiftCodeCtrl;
  late final TextEditingController _fbrApiTokenSandboxCtrl;
  late final TextEditingController _fbrApiTokenProdCtrl;
  late final TextEditingController _fbrUsernameCtrl;
  late final TextEditingController _fbrPasswordCtrl;

  String _idType = 'NTN';
  String _fbrEnv = 'Sandbox';
  File? _logoFile;
  String? _logoUrl; // ✅ Store logo URL from API
  String? _logoFullUrl; // ✅ Full absolute URL from API (bus_logo_url)
  final Set<String> _selectedScenarios = <String>{};
  final List<String> _availableScenarios = <String>[];
  String? _selectedProvince;

  String? _normalizeProvince(String? incoming) {
    if (incoming == null || incoming.trim().isEmpty) return null;
    final provinces = <String>[
      'Punjab',
      'Sindh',
      'KPK',
      'Balochistan',
      'Islamabad Capital Territory',
      'Gilgit-Baltistan',
      'Azad Kashmir',
    ];
    final match = provinces.firstWhere(
      (p) => p.toLowerCase() == incoming.trim().toLowerCase(),
      orElse: () => provinces.first,
    );
    return match;
  }

  void _showBottomSheetMessage({required bool success, required String message}) {
    final context = this.context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(success ? Icons.check_circle : Icons.error_rounded, color: success ? Colors.green : Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });
  }

  Future<void> _fetchConfiguration() async {
    try {
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();

      // ✅ Use POST with form-data (as per API requirement)
      // Get bus_config_id from SharedPreferences (set at login)
      final prefs = await SharedPreferences.getInstance();
      final busConfigId = prefs.getString('bus_config_id') ?? prefs.getString('tenant_id') ?? '1';
      final res = await api.postFormData(
        ApiEndpoints.companyFetchConfiguration,
        fields: {'bus_config_id': busConfigId},
        requiresAuth: true,
      );

      if (res['success'] != true) {
        SnackbarHelper.showError(res['message']?.toString() ?? 'Failed to fetch configuration');
        return;
      }

      final data = res['data'] as Map<String, dynamic>?;
      if (data == null) return;

      final config = data['config'] as Map<String, dynamic>? ?? {};
      final scenarios = (data['scenarios'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final selectedScenarioIds = (data['selectedScenarios'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt())
          .toSet();

      // Map IDs to Codes for convenience
      final idToCode = <int, String>{
        for (final s in scenarios)
          if (s['scenario_id'] != null && s['scenario_code'] != null)
            (s['scenario_id'] as num).toInt(): s['scenario_code'].toString()
      };

      // Populate controllers
      setState(() {
        _companyNameCtrl.text = (config['bus_name'] ?? '').toString();
        _ntnCnicCtrl.text = (config['bus_ntn_cnic'] ?? '').toString();
        _addressCtrl.text = (config['bus_address'] ?? '').toString();
        _accountTitleCtrl.text = (config['bus_account_title'] ?? '').toString();
        _accountNumberCtrl.text = (config['bus_account_number'] ?? '').toString();
        _ibanCtrl.text = (config['bus_IBAN'] ?? '').toString();
        _branchNameCtrl.text = (config['bus_acc_branch_name'] ?? '').toString();
        _branchCodeCtrl.text = (config['bus_acc_branch_code'] ?? '').toString();
        _registrationCtrl.text = (config['bus_reg_num'] ?? '').toString();
        _contactNumberCtrl.text = (config['bus_contact_num'] ?? '').toString();
        _contactPersonCtrl.text = (config['bus_contact_person'] ?? '').toString();
        // Province normalization (API sends uppercase)
        final prov = (config['bus_province'] ?? '').toString();
        final norm = _normalizeProvince(prov);
        _selectedProvince = norm;
        if (norm != null) _provinceCtrl.text = norm;
        _swiftCodeCtrl.text = (config['bus_swift_code'] ?? '').toString();
        _fbrApiTokenSandboxCtrl.text = (config['fbr_api_token_sandbox'] ?? '').toString();
        _fbrApiTokenProdCtrl.text = (config['fbr_api_token_prod'] ?? '').toString();

        // ✅ Store logo URLs from API
        _logoUrl = config['bus_logo']?.toString();
        _logoFullUrl = config['bus_logo_url']?.toString();
        print('📸 Logo URL from API (relative): $_logoUrl');
        if (_logoFullUrl != null && _logoFullUrl!.isNotEmpty) {
          final lower = _logoFullUrl!.toLowerCase();
          // If API gives an SVG logo URL, Image.network can't render it. Prefer PNG/JPG from storage instead.
          if (lower.endsWith('.svg')) {
            print('⚠️ bus_logo_url is SVG, will prefer storage PNG/JPG path if available');
            _logoFullUrl = null;
          } else {
            print('📸 Full Logo URL (api): $_logoFullUrl');
          }
        }
        if ((_logoFullUrl == null || _logoFullUrl!.isEmpty) && _logoUrl != null && _logoUrl!.isNotEmpty) {
          final fullUrl = '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/storage/$_logoUrl';
          print('📸 Full Logo URL (constructed): $fullUrl');
        }

        // FBR Environment mapping
        final envRaw = (config['fbr_env'] ?? '').toString().toLowerCase();
        _fbrEnv = envRaw == 'production' ? 'Production' : 'Sandbox';

        // Scenarios lists
        _availableScenarios
          ..clear()
          ..addAll(scenarios.map((s) => s['scenario_code'].toString()).toList());

        _selectedScenarios
          ..clear()
          ..addAll(selectedScenarioIds.map((id) => idToCode[id]).whereType<String>());
      });
    } catch (e) {
      SnackbarHelper.showError(e.toString());
    }
  }

  bool _isValidProvince(String? v) {
    if (v == null || v.isEmpty) return false;
    const provinces = <String>[
      'Punjab',
      'Sindh',
      'KPK',
      'Balochistan',
      'Islamabad Capital Territory',
      'Gilgit-Baltistan',
      'Azad Kashmir',
    ];
    return provinces.contains(v);
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      _showBottomSheetMessage(success: false, message: 'Please fill all required fields');
      return;
    }

    try {
      final api = Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient();

      // Build form fields
      final fields = <String, String>{
        // Use same bus_config_id as fetch, defaulting to '1' only if nothing saved
        'bus_config_id': (await SharedPreferences.getInstance()).getString('bus_config_id') ??
            (await SharedPreferences.getInstance()).getString('tenant_id') ??
            '1',
        'id_type': _idType,
        'bus_ntn_cnic': _ntnCnicCtrl.text.trim(),
        'bus_name': _companyNameCtrl.text.trim(),
        'bus_address': _addressCtrl.text.trim(),
        'bus_province': _selectedProvince ?? 'Punjab',
        'bus_account_title': _accountTitleCtrl.text.trim(),
        'bus_account_number': _accountNumberCtrl.text.trim(),
        'bus_reg_num': _registrationCtrl.text.trim(),
        'bus_contact_num': _contactNumberCtrl.text.trim(),
        'bus_contact_person': _contactPersonCtrl.text.trim(),
        'bus_IBAN': _ibanCtrl.text.trim(),
        'bus_acc_branch_name': _branchNameCtrl.text.trim(),
        'bus_acc_branch_code': _branchCodeCtrl.text.trim(),
        'fbr_env': _fbrEnv.toLowerCase(),
        'fbr_api_token_sandbox': _fbrApiTokenSandboxCtrl.text.trim(),
        'fbr_api_token_prod': _fbrApiTokenProdCtrl.text.trim(),
      };

      // Add swift code if not empty
      if (_swiftCodeCtrl.text.trim().isNotEmpty) {
        fields['bus_swift_code'] = _swiftCodeCtrl.text.trim();
      }

      // Add scenario IDs
      if (_selectedScenarios.isNotEmpty) {
        // Convert scenario codes to IDs
        final scenarioIds = _selectedScenarios.map((code) {
          // Extract ID from code (e.g., "SN018" -> 18)
          final match = RegExp(r'SN0*(\d+)').firstMatch(code);
          return match?.group(1) ?? '';
        }).where((id) => id.isNotEmpty).toList();

        for (int i = 0; i < scenarioIds.length; i++) {
          fields['scenario_ids[$i]'] = scenarioIds[i];
        }
      }

      // Send request with logo file if selected
      final res = await api.postFormData(
        ApiEndpoints.companyUpdateConfiguration,
        fields: fields,
        files: _logoFile != null ? {'bus_logo': _logoFile!} : null,
        requiresAuth: true,
      );

      if (res['success'] == true) {
        _showBottomSheetMessage(success: true, message: 'Configuration updated successfully');
        // Refresh data
        await _fetchConfiguration();
      } else {
        _showBottomSheetMessage(success: false, message: res['message']?.toString() ?? 'Failed to update configuration');
      }
    } catch (e) {
      _showBottomSheetMessage(success: false, message: e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    _companyNameCtrl = TextEditingController(text: 'SecureISM Pvt Ltd');
    _ntnCnicCtrl = TextEditingController(text: '93521882');
    _addressCtrl = TextEditingController(text: '2nd Carrer of Technology, Zong Society, Islamabad Pakistan');
    _accountTitleCtrl = TextEditingController(text: 'SecureISM Pvt Ltd');
    _accountNumberCtrl = TextEditingController(text: '1234567891');
    _bankNameCtrl = TextEditingController();
    _ibanCtrl = TextEditingController();
    _branchNameCtrl = TextEditingController();
    _branchCodeCtrl = TextEditingController();
    _registrationCtrl = TextEditingController(text: '011999');
    _contactNumberCtrl = TextEditingController(text: '03001234567');
    _contactPersonCtrl = TextEditingController(text: 'John Doe');
    _provinceCtrl = TextEditingController(text: 'PUNJAB');
    _swiftCodeCtrl = TextEditingController();
    _fbrApiTokenSandboxCtrl = TextEditingController();
    _fbrApiTokenProdCtrl = TextEditingController();
    _fbrUsernameCtrl = TextEditingController();
    _fbrPasswordCtrl = TextEditingController();
    final normalized = _normalizeProvince(_provinceCtrl.text);
    _selectedProvince = normalized;
    if (normalized != null) _provinceCtrl.text = normalized;
    // Fetch real configuration from API
    Future.microtask(_fetchConfiguration);
  }

  void _showScenariosPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final temp = Set<String>.from(_selectedScenarios);
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Scenarios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: _availableScenarios.map((code) {
                          final selected = temp.contains(code);
                          return CheckboxListTile(
                            value: selected,
                            title: Text(code),
                            onChanged: (v) {
                              setModalState(() {
                                if (v == true) {
                                  temp.add(code);
                                } else {
                                  temp.remove(code);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedScenarios
                                  ..clear()
                                  ..addAll(temp);
                              });
                              Navigator.pop(context);
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _ntnCnicCtrl.dispose();
    _addressCtrl.dispose();
    _accountTitleCtrl.dispose();
    _accountNumberCtrl.dispose();
    _bankNameCtrl.dispose();
    _ibanCtrl.dispose();
    _branchNameCtrl.dispose();
    _branchCodeCtrl.dispose();
    _registrationCtrl.dispose();
    _contactNumberCtrl.dispose();
    _contactPersonCtrl.dispose();
    _provinceCtrl.dispose();
    _swiftCodeCtrl.dispose();
    _fbrApiTokenSandboxCtrl.dispose();
    _fbrApiTokenProdCtrl.dispose();
    _fbrUsernameCtrl.dispose();
    _fbrPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _logoFile = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Configuration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              children: [
                _sectionTitle('Company Details'),
                _card(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppInputField(
                        label: 'Company Name',
                        controller: _companyNameCtrl,
                        hint: 'Enter company name',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdownField(
                              label: 'Select NTN/CNIC',
                              value: _idType,
                              items: const ['NTN', 'CNIC'],
                              onChanged: (v) => setState(() => _idType = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppInputField(
                              label: 'NTN/CNIC',
                              controller: _ntnCnicCtrl,
                              hint: 'Enter NTN/CNIC',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppInputField(
                              label: 'Registration #',
                              controller: _registrationCtrl,
                              hint: 'Enter registration number',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppInputField(
                              label: 'Contact Number',
                              controller: _contactNumberCtrl,
                              hint: '03XXXXXXXXX',
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _isValidProvince(_selectedProvince) ? _selectedProvince : null,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Province',
                                hintText: '-- Select Province --',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  borderSide: BorderSide(color: Colors.green, width: 2),
                                ),
                                errorBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(8)),
                                  borderSide: BorderSide(color: Colors.red),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: const [
                                'Punjab',
                                'Sindh',
                                'KPK',
                                'Balochistan',
                                'Islamabad Capital Territory',
                                'Gilgit-Baltistan',
                                'Azad Kashmir',
                              ].map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedProvince = v;
                                  _provinceCtrl.text = v ?? '';
                                });
                              },
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppInputField(
                              label: 'Contact Person',
                              controller: _contactPersonCtrl,
                              hint: 'Enter contact person',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'Address',
                        controller: _addressCtrl,
                        hint: 'Enter address',
                        maxLines: 3,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Company Logo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ✅ Show current logo if exists (from API or storage)
                      if (_logoUrl != null && _logoUrl!.isNotEmpty && _logoFile == null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<String?>(
                                  future: (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : ApiClient()).getToken(),
                                  builder: (context, snap) {
                                    // Decide which URL to use
                                    String rawUrl;
                                    if (_logoFullUrl != null && _logoFullUrl!.isNotEmpty) {
                                      rawUrl = _logoFullUrl!;
                                    } else {
                                      rawUrl = '${ApiEndpoints.baseUrl.replaceAll('/api', '')}/storage/$_logoUrl';
                                    }

                                    // Fix only localhost/127.0.0.1 for emulator
                                    final needsFix = rawUrl.contains('127.0.0.1') || rawUrl.contains('localhost');
                                    final fullUrl = needsFix ? ImageUrlHelper.fixUrl(rawUrl) : rawUrl;

                                    if (snap.connectionState != ConnectionState.done) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        ),
                                      );
                                    }

                                    final token = snap.data;
                                    // Only send Authorization header for same-origin storage URLs; not needed for external S3 URLs
                                    final isExternal = fullUrl.startsWith('http') && !fullUrl.contains('taxbridge.pk');
                                    final headers = (!isExternal && token != null && token.isNotEmpty)
                                        ? {
                                            'Authorization': token.toLowerCase().startsWith('bearer ')
                                                ? token
                                                : 'Bearer $token',
                                            'Accept': 'image/*',
                                          }
                                        : <String, String>{};

                                    return Image.network(
                                      fullUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      headers: headers.isEmpty ? null : headers,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('❌ Logo load error: $error');
                                        print('❌ Logo URL: $fullUrl');
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Current Logo',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text('Change'),
                              ),
                            ],
                          ),
                        ),

                      // ✅ Show selected file or upload button
                      InkWell(
                        onTap: _pickLogo,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.upload_outlined, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _logoFile == null
                                      ? (_logoUrl != null && _logoUrl!.isNotEmpty ? 'Change logo' : 'Choose file')
                                      : _logoFile!.path.split('/').last,
                                  style: const TextStyle(color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                _sectionTitle('Bank Details'),
                _card(
                  Column(
                    children: [
                      AppInputField(
                        label: 'Account Title',
                        controller: _accountTitleCtrl,
                        hint: 'Enter account title',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppInputField(
                              label: 'Account Number',
                              controller: _accountNumberCtrl,
                              hint: 'Enter account number',
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppInputField(
                              label: 'Bank Name',
                              controller: _bankNameCtrl,
                              hint: 'Enter bank name',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'IBAN',
                        controller: _ibanCtrl,
                        hint: 'Enter IBAN',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'Swift Code',
                        controller: _swiftCodeCtrl,
                        hint: 'Enter Swift code',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppInputField(
                              label: 'Branch Name',
                              controller: _branchNameCtrl,
                              hint: 'Enter branch name',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppInputField(
                              label: 'Branch Code',
                              controller: _branchCodeCtrl,
                              hint: 'Enter branch code',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _sectionTitle('Configuration Settings'),
                _card(
                  Column(
                    children: [
                      _dropdownField(
                        label: 'FBR Environment',
                        value: _fbrEnv,
                        items: const ['Sandbox', 'Production'],
                        onChanged: (v) => setState(() => _fbrEnv = v!),
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'FBR API Token (Sandbox)',
                        controller: _fbrApiTokenSandboxCtrl,
                        hint: 'Enter API token (Sandbox)',
                      ),
                      const SizedBox(height: 12),
                      AppInputField(
                        label: 'FBR API Token (Production)',
                        controller: _fbrApiTokenProdCtrl,
                        hint: 'Enter API token (Production)',
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Scenarios',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showScenariosPicker,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            hintText: 'Select Scenarios',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: Colors.green, width: 2)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedScenarios.isEmpty
                                ? [const Text('-- Select Scenarios --', style: TextStyle(color: Colors.grey))]
                                : _selectedScenarios.map((e) => Chip(label: Text(e))).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                AppButton(
                  label: 'Save Configuration',
                  onPressed: _saveConfiguration,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _card(Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
