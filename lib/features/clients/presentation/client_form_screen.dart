// ─────────────────────────────────────────────────────────────────────────────
// lib/features/clients/presentation/client_form_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../data/models/client_model.dart';
import '../controller/clients_controller.dart';
import '../../../core/utils/snackbar_helper.dart';

class ClientFormScreen extends StatefulWidget {
  final ClientModel? client;

  const ClientFormScreen({super.key, this.client});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ClientsController>();

  // Form Controllers
  late TextEditingController _nameController;
  late TextEditingController _ntnCnicController;
  late TextEditingController _addressController;
  late TextEditingController _provinceController;
  late TextEditingController _contactNumController;
  late TextEditingController _contactPersonController;
  late TextEditingController _accountTitleController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ibanController;
  late TextEditingController _branchNameController;
  late TextEditingController _branchCodeController;
  late TextEditingController _regNumController;
  late TextEditingController _swiftCodeController;
  late TextEditingController _emailController;

  int _selectedType = 1; // 1 = Registered, 0 = Unregistered
  String _selectedIdType = 'NTN';
  String? _selectedProvince;
  File? _logoFile;
  String? _existingLogoUrl;

  // Province mapping between UI display and backend codes
  // Backend expects CAPITAL TERRITORY for Islamabad.
  String _toApiProvince(String v) {
    final value = v.trim();
    switch (value.toLowerCase()) {
      case 'islamabad capital territory':
      case 'capital territory':
      case 'ict':
        return 'CAPITAL TERRITORY';
      case 'punjab':
        return 'Punjab';
      case 'sindh':
        return 'Sindh';
      case 'kpk':
        return 'KPK';
      case 'balochistan':
        return 'Balochistan';
      case 'gilgit-baltistan':
        return 'Gilgit-Baltistan';
      case 'azad kashmir':
      case 'azad jammu and kashmir':
        return 'AZAD JAMMU AND KASHMIR';
      default:
        return value; // fallback to pass-through
    }
  }

  String _toDisplayProvince(String v) {
    final value = v.trim();
    switch (value.toUpperCase()) {
      case 'CAPITAL TERRITORY':
        return 'Islamabad Capital Territory';
      case 'AZAD JAMMU AND KASHMIR':
        return 'Azad Kashmir';
      default:
        return value; // other values are already display-friendly
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    // ✅ Automatically fetch full client data to populate all fields (like email) in edit mode
    if (widget.client != null) {
      _fetchClientData();
    }
  }

  void _initializeControllers() {
    final client = widget.client;
    _nameController = TextEditingController(text: client?.byrName ?? '');
    _ntnCnicController = TextEditingController(text: client?.byrNtnCnic ?? '');
    _addressController = TextEditingController(text: client?.byrAddress ?? '');
    _provinceController = TextEditingController(text: client?.byrProvince ?? '');
    _contactNumController = TextEditingController(text: client?.byrContactNum ?? '');
    _contactPersonController = TextEditingController(text: client?.byrContactPerson ?? '');
    _accountTitleController = TextEditingController(text: client?.byrAccountTitle ?? '');
    _accountNumberController = TextEditingController(text: client?.byrAccountNumber ?? '');
    _ibanController = TextEditingController(text: client?.byrIBAN ?? '');
    _branchNameController = TextEditingController(text: client?.byrAccBranchName ?? '');
    _branchCodeController = TextEditingController(text: client?.byrAccBranchCode ?? '');
    _regNumController = TextEditingController(text: client?.byrRegNum ?? '');
    _swiftCodeController = TextEditingController(text: client?.byrSwiftCode ?? '');
    _emailController = TextEditingController(text: client?.byrEmail ?? '');

    if (client != null) {
      _selectedType = client.byrType;
      _selectedIdType = client.byrIdType ?? 'NTN';
      _existingLogoUrl = client.byrLogoUrl;
      _normalizeProvince(client.byrProvince);
    }
  }

  void _normalizeProvince(String? province) {
    if (province == null || province.isEmpty) return;
    
    final provinces = <String>[
      'Punjab',
      'Sindh',
      'KPK',
      'Balochistan',
      'Islamabad Capital Territory',
      'Gilgit-Baltistan',
      'Azad Kashmir',
    ];
    
    final displayVal = _toDisplayProvince(province);
    final matched = provinces.firstWhere(
      (p) => p.toLowerCase() == displayVal.toLowerCase(),
      orElse: () => displayVal,
    );
    _selectedProvince = matched;
    _provinceController.text = matched;
  }

  // ✅ Fetch client data from API and populate ALL fields
  Future<void> _fetchClientData() async {
    if (widget.client == null) return;

    try {
      print('📝 Fetching full client data for byr_id: ${widget.client!.byrId}');
      await controller.fetchClient(widget.client!.byrId);

      if (controller.selectedClient.value != null) {
        final client = controller.selectedClient.value!;
        print('✅ Client data fetched: ${client.byrName}, email: ${client.byrEmail}');

        setState(() {
          _nameController.text = client.byrName;
          _emailController.text = client.byrEmail ?? '';
          _ntnCnicController.text = client.byrNtnCnic ?? '';
          _addressController.text = client.byrAddress ?? '';
          _contactNumController.text = client.byrContactNum ?? '';
          _contactPersonController.text = client.byrContactPerson ?? '';
          _accountTitleController.text = client.byrAccountTitle ?? '';
          _accountNumberController.text = client.byrAccountNumber ?? '';
          _ibanController.text = client.byrIBAN ?? '';
          _branchNameController.text = client.byrAccBranchName ?? '';
          _branchCodeController.text = client.byrAccBranchCode ?? '';
          _regNumController.text = client.byrRegNum ?? '';
          _swiftCodeController.text = client.byrSwiftCode ?? '';
          _selectedType = client.byrType;
          _selectedIdType = client.byrIdType ?? 'NTN';
          _existingLogoUrl = client.byrLogoUrl;
          _normalizeProvince(client.byrProvince);
        });
      }
    } catch (e) {
      print('❌ Error fetching client data: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ntnCnicController.dispose();
    _addressController.dispose();
    _provinceController.dispose();
    _contactNumController.dispose();
    _contactPersonController.dispose();
    _accountTitleController.dispose();
    _accountNumberController.dispose();
    _ibanController.dispose();
    _branchNameController.dispose();
    _branchCodeController.dispose();
    _regNumController.dispose();
    _swiftCodeController.dispose();
    _emailController.dispose();
    super.dispose();
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
  }

  Future<void> _pickImage() async {
    // Show dialog to choose between camera and gallery
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _logoFile = File(pickedFile.path);
        });
        SnackbarHelper.showSuccess('Image selected successfully');
      }
    } catch (e) {
      SnackbarHelper.showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) {
      _showBottomSheetMessage(success: false, message: 'Please fix the highlighted fields');
      return;
    }

    try {
      bool success;
      if (widget.client == null) {
        // Creating new client
        success = await controller.createClient(
          byrName: _nameController.text,
          byrType: _selectedType,
          byrIdType: _selectedIdType,
          byrNtnCnic: _ntnCnicController.text.isEmpty ? null : _ntnCnicController.text,
          byrAddress: _addressController.text.isEmpty ? null : _addressController.text,
          byrProvince: _toApiProvince((_selectedProvince ?? _provinceController.text)),
          byrContactNum: _contactNumController.text.isEmpty ? null : _contactNumController.text,
          byrContactPerson: _contactPersonController.text.isEmpty ? null : _contactPersonController.text,
          byrAccountTitle: _accountTitleController.text.isEmpty ? null : _accountTitleController.text,
          byrAccountNumber: _accountNumberController.text.isEmpty ? null : _accountNumberController.text,
          byrIBAN: _ibanController.text.isEmpty ? null : _ibanController.text,
          byrAccBranchName: _branchNameController.text.isEmpty ? null : _branchNameController.text,
          byrAccBranchCode: _branchCodeController.text.isEmpty ? null : _branchCodeController.text,
          byrSwiftCode: _swiftCodeController.text.isEmpty ? null : _swiftCodeController.text,
          byrRegNum: _regNumController.text.isEmpty ? null : _regNumController.text,
          byrEmail: _emailController.text.isEmpty ? null : _emailController.text,
          byrLogo: _logoFile,
        );
      } else {
        // Updating existing client
        success = await controller.updateClient(
          byrId: widget.client!.byrId,
          byrName: _nameController.text,
          byrType: _selectedType,
          byrIdType: _selectedIdType,
          byrNtnCnic: _ntnCnicController.text.isEmpty ? null : _ntnCnicController.text,
          byrAddress: _addressController.text.isEmpty ? null : _addressController.text,
          byrProvince: _toApiProvince((_selectedProvince ?? _provinceController.text)),
          byrContactNum: _contactNumController.text.isEmpty ? null : _contactNumController.text,
          byrContactPerson: _contactPersonController.text.isEmpty ? null : _contactPersonController.text,
          byrAccountTitle: _accountTitleController.text.isEmpty ? null : _accountTitleController.text,
          byrAccountNumber: _accountNumberController.text.isEmpty ? null : _accountNumberController.text,
          byrIBAN: _ibanController.text.isEmpty ? null : _ibanController.text,
          byrAccBranchName: _branchNameController.text.isEmpty ? null : _branchNameController.text,
          byrAccBranchCode: _branchCodeController.text.isEmpty ? null : _branchCodeController.text,
          byrSwiftCode: _swiftCodeController.text.isEmpty ? null : _swiftCodeController.text,
          byrRegNum: _regNumController.text.isEmpty ? null : _regNumController.text,
          byrEmail: _emailController.text.isEmpty ? null : _emailController.text,
          byrLogo: _logoFile,
        );
      }

      if (success) {
        final created = widget.client == null;
        _showBottomSheetMessage(success: true, message: created ? 'Client created successfully' : 'Client updated successfully');
        controller.fetchClients(refresh: true);
        await Future.delayed(const Duration(milliseconds: 900));
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close bottom sheet
        }
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close form
        }
      }
    } catch (e) {
      _showBottomSheetMessage(success: false, message: e.toString());
    }
  }

  Future<void> _deleteClient() async {
    if (widget.client == null) return;
    final ok = await controller.deleteClient(widget.client!.byrId, silent: true);
    if (ok) {
      _showBottomSheetMessage(success: true, message: 'Client deleted successfully');
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) Get.back();
    } else {
      _showBottomSheetMessage(success: false, message: 'Failed to delete client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.client == null ? 'Add Client' : 'Edit Client',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () {
              print('❌ Close button (X) pressed in Client Form');
              Navigator.of(ctx).maybePop();
            },
          ),
        ),
        actions: [
          if (widget.client != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: _deleteClient,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ───── Client Type ─────
            Row(
              children: const [
                Text(
                  'Client Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 4),
                Text('*', style: TextStyle(color: Colors.red)),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<int>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Registered',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 1,
                    groupValue: _selectedType,
                    onChanged: (value) => setState(() => _selectedType = value!),
                    activeColor: Colors.green,
                  ),
                ),
                Expanded(
                  child: RadioListTile<int>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Unregistered',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14),
                    ),
                    value: 0,
                    groupValue: _selectedType,
                    onChanged: (value) => setState(() => _selectedType = value!),
                    activeColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ───── Basic Info ─────
            _buildSectionTitle('Basic Information'),
            AppInputField(
              controller: _nameController,
              label: 'Client Name *',
              hint: 'Enter client name',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            AppInputField(
              controller: _emailController,
              label: 'Email Address *',
              hint: 'Enter email address',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email is required';
                if (!GetUtils.isEmail(value)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ───── ID Type & Number ─────
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedIdType,
                    decoration: const InputDecoration(labelText: 'ID Type'),
                    items: ['NTN', 'CNIC'].map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedIdType = value!);
                      // ✅ Fetch client data when ID Type changes in edit mode
                      if (widget.client != null) {
                        _fetchClientData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: AppInputField(
                    controller: _ntnCnicController,
                    label: '$_selectedIdType Number',
                    hint: 'Enter $_selectedIdType',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final v = value?.trim() ?? '';

                      // For registered clients, enforce NTN/CNIC rules
                      if (_selectedType == 1 && _selectedIdType == 'NTN') {
                        if (v.isEmpty) {
                          return 'NTN is required for registered client';
                        }
                        if (v.length != 7) {
                          return 'NTN must be 7 digits';
                        }
                      } else if (_selectedType == 1 && _selectedIdType == 'CNIC') {
                        if (v.isEmpty) {
                          return 'CNIC is required for registered client';
                        }
                        if (v.length != 13) {
                          return 'CNIC must be 13 digits';
                        }
                      }

                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            AppInputField(
              controller: _addressController,
              label: 'Address *',
              hint: 'Enter address',
              maxLines: 2,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Text(
                  'Province',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 4),
                Text('*', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            _provinceDropdown(),
            const SizedBox(height: 16),

            // ───── Contact Info ─────
            _buildSectionTitle('Contact Information'),
            AppInputField(
              controller: _contactPersonController,
              label: 'Contact Person',
              hint: 'Enter contact person name',
            ),
            const SizedBox(height: 16),

            AppInputField(
              controller: _contactNumController,
              label: 'Contact Number',
              hint: 'Enter contact number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),

            // ───── Bank Details ─────
            _buildSectionTitle('Bank Details'),
            Row(
              children: [
                Expanded(
                  child: AppInputField(
                    controller: _accountTitleController,
                    label: 'Account Title',
                    hint: 'Enter Account Title',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInputField(
                    controller: _accountNumberController,
                    label: 'Account Number',
                    hint: 'Enter Account Number',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppInputField(
              controller: _ibanController,
              label: 'IBAN',
              hint: 'Enter  IBAN',
            ),
            const SizedBox(height: 16),
            // SWIFT Code (single column)
            AppInputField(
              controller: _swiftCodeController,
              label: 'SWIFT Code',
              hint: 'Enter SWIFT Code',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppInputField(
                    controller: _branchNameController,
                    label: 'Branch Name',
                    hint: 'Enter Branch Name',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppInputField(
                    controller: _branchCodeController,
                    label: 'Branch Code',
                    hint: 'Enter Branch Code',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ───── Registration Number ─────
            _buildSectionTitle('Registration'),
            AppInputField(
              controller: _regNumController,
              label: 'Registration Number',
              hint: 'Enter Registration Number',
            ),
            const SizedBox(height: 16),

            // ───── Client Logo Upload ─────
            _buildSectionTitle('Client Logo'),

            // Show existing logo if available
            if (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty && _logoFile == null)
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
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        ImageUrlHelper.fixUrl(_existingLogoUrl!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Current Logo',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

            InkWell(
              onTap: _pickImage,
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
                            ? (_existingLogoUrl != null && _existingLogoUrl!.isNotEmpty ? 'Change logo' : 'Choose file')
                            : _logoFile!.path.split('/').last,
                        style: const TextStyle(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ───── Save Button ─────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      print('❌ Cancel button pressed in Client Form');
                      Navigator.of(context).maybePop();
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => AppButton(
                        label: widget.client == null ? 'Save Client' : 'Update Client',
                        onPressed: _saveClient,
                        isLoading: controller.isLoading.value,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _provinceDropdown() {
    final provinces = <String>[
      'Punjab',
      'Sindh',
      'KPK',
      'Balochistan',
      'Islamabad Capital Territory',
      'Gilgit-Baltistan',
      'Azad Kashmir',
    ];
    return DropdownButtonFormField<String>(
      value: _selectedProvince?.isNotEmpty == true ? _selectedProvince : null,
      isExpanded: true,
      decoration: InputDecoration(
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: provinces.map((p) => DropdownMenuItem<String>(value: p, child: Text(p))).toList(),
      onChanged: (v) => setState(() {
        _selectedProvince = v;
        _provinceController.text = v ?? '';
      }),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }
}

