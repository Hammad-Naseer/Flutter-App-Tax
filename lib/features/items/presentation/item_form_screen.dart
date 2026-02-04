// ─────────────────────────────────────────────────────────────────────────────
// lib/features/items/presentation/item_form_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_input_field.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/service_item_model.dart';
import '../controller/items_controller.dart';
import '../../../core/utils/snackbar_helper.dart';

class ItemFormScreen extends StatefulWidget {
  final ServiceItemModel? item;

  const ItemFormScreen({super.key, this.item});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.find<ItemsController>();

  // Form Controllers
  late TextEditingController _descriptionController;
  late TextEditingController _hsCodeController;
  late TextEditingController _priceController;
  late TextEditingController _taxRateController;
  late TextEditingController _uomController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final item = widget.item;
    _descriptionController = TextEditingController(text: item?.itemDescription ?? '');
    _hsCodeController = TextEditingController(text: item?.itemHsCode ?? '');
    _priceController = TextEditingController(
      text: item?.itemPrice != null ? item!.itemPrice.toString() : '',
    );
    _taxRateController = TextEditingController(text: item?.itemTaxRate ?? '');
    _uomController = TextEditingController(text: item?.itemUom ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _hsCodeController.dispose();
    _priceController.dispose();
    _taxRateController.dispose();
    _uomController.dispose();
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    bool success;
    if (widget.item == null) {
      // Creating new item
      success = await controller.createItem(
        itemDescription: _descriptionController.text,
        itemHsCode: _hsCodeController.text.isEmpty ? null : _hsCodeController.text,
        itemPrice: double.parse(_priceController.text),
        itemTaxRate: _taxRateController.text.isEmpty ? null : _taxRateController.text,
        itemUom: _uomController.text.isEmpty ? null : _uomController.text,
        silent: true,
      );

      if (success) {
        _showBottomSheetMessage(success: true, message: 'Item created successfully');
        // After successful create, close bottom sheet then go back to items list screen
        await Future.delayed(const Duration(milliseconds: 900));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close bottom sheet
        }
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close form
        }
      } else {
        _showBottomSheetMessage(success: false, message: 'Failed to create item');
      }
    } else {
      // Updating existing item
      success = await controller.updateItem(
        itemId: widget.item!.itemId,
        itemDescription: _descriptionController.text,
        itemHsCode: _hsCodeController.text.isEmpty ? null : _hsCodeController.text,
        itemPrice: double.parse(_priceController.text),
        itemTaxRate: _taxRateController.text.isEmpty ? null : _taxRateController.text,
        itemUom: _uomController.text.isEmpty ? null : _uomController.text,
        silent: true,
      );

      if (success) {
        _showBottomSheetMessage(success: true, message: 'Item updated successfully');
        // Close bottom sheet then form (go back to list)
        await Future.delayed(const Duration(milliseconds: 900));
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close bottom sheet
        }
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop(); // close form
        }
      } else {
        _showBottomSheetMessage(success: false, message: 'Failed to update item');
      }
    }
  }

  Future<void> _deleteItem() async {
    if (widget.item == null) return;
    final ok = await controller.deleteItem(widget.item!.itemId, silent: true);
    if (ok) {
      _showBottomSheetMessage(success: true, message: 'Item deleted successfully');
      await Future.delayed(const Duration(milliseconds: 900));
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // close bottom sheet
      }
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // close form
      }
    } else {
      _showBottomSheetMessage(success: false, message: 'Failed to delete item');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Add New Item / Service' : 'Edit Item / Service',
          style: const TextStyle(
            fontSize: 18,
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
            print('❌ Close button (X) pressed in Item Form');
            Navigator.of(ctx).maybePop();
          },
          ),
        ),
        actions: [
          if (widget.item != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Delete',
              onPressed: _deleteItem,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ───── Item/Service Description ─────
            Row(
              children: const [
                Text(
                  'Item/Service Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 4),
                Text('*', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter Item/Service Description',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
            ),
            const SizedBox(height: 20),

            // ───── HS Code ─────
            Row(
              children: const [
                Text(
                  'HS Code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 4),
                Text('*', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            AppInputField(
              controller: _hsCodeController,
              label: '',
              hint: 'Enter HS Code',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ───── Price & Tax Rate ─────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text('*', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppInputField(
                        controller: _priceController,
                        label: '',
                        hint: 'Enter Price',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (double.tryParse(value!) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            'Tax Rate in % (e.g. 16)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text('*', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppInputField(
                        controller: _taxRateController,
                        label: '',
                        hint: 'Enter Tax Rate',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (double.tryParse(value!) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ───── Unit of Measure ─────
            Row(
              children: const [
                Text(
                  'Unit of Measure (UOM)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(width: 4),
                Text('*', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            AppInputField(
              controller: _uomController,
              label: '',
              hint: 'Enter Unit of Measure',
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 4),
            const Text(
              'e.g., Per Month, Per Project, Per Unit',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            // ───── Action Buttons ─────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      print('❌ Cancel button pressed in Item Form');
                      Navigator.of(context).maybePop();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Obx(() => AppButton(
                        label: widget.item == null ? 'Save Item' : 'Update Item',
                        onPressed: _saveItem,
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
}

