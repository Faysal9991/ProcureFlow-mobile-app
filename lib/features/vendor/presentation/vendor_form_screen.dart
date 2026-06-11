import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../auth/domain/permission_policy.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../domain/vendor_entity.dart';
import 'vendor_controller.dart';
import 'vendor_providers.dart';

class VendorFormScreen extends ConsumerStatefulWidget {
  const VendorFormScreen({
    super.key,
    this.vendorId,
    this.showBottomNavigation = true,
  });

  final String? vendorId;
  final bool showBottomNavigation;

  bool get isEditMode => vendorId != null;

  @override
  ConsumerState<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends ConsumerState<VendorFormScreen> {
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String _status = VendorStatus.active;
  bool _hydrated = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) {
      Future.microtask(
        () => ref
            .read(vendorControllerProvider.notifier)
            .loadDetail(widget.vendorId!),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(vendorControllerProvider, (previous, next) {
      final vendor = next.selectedVendor;
      if (widget.isEditMode && !_hydrated && vendor != null) {
        _hydrate(vendor);
      }
    });

    final state = ref.watch(vendorControllerProvider);
    final vendor = state.selectedVendor;
    if (widget.isEditMode && !_hydrated && vendor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_hydrated) {
          _hydrate(vendor);
        }
      });
    }

    return AppScaffold(
      title: widget.isEditMode ? 'Edit Vendor' : 'New Vendor',
      showBottomNavigation: widget.showBottomNavigation,
      child: Builder(
        builder: (context) {
          if (state.isLoading && widget.isEditMode && vendor == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.isEditMode &&
              vendor == null &&
              state.errorMessage != null) {
            return AppScreenListView(
              children: [AppEmptyCard(message: state.errorMessage!)],
            );
          }
          return _VendorFormBody(
            nameController: _nameController,
            contactPersonController: _contactPersonController,
            phoneController: _phoneController,
            emailController: _emailController,
            addressController: _addressController,
            status: _status,
            showValidation: _submitted,
            isMutating: state.isMutating,
            errorMessage: state.errorMessage,
            onStatusChanged: (value) {
              if (value != null) {
                setState(() => _status = value);
              }
            },
            onCancel: _cancel,
            onSave: _save,
          );
        },
      ),
    );
  }

  void _hydrate(VendorEntity vendor) {
    _nameController.text = vendor.name;
    _contactPersonController.text = vendor.contactPerson ?? '';
    _phoneController.text = vendor.phone ?? '';
    _emailController.text = vendor.email ?? '';
    _addressController.text = vendor.address ?? '';
    _status = vendor.normalizedStatus;
    _hydrated = true;
    _submitted = false;
    if (mounted) setState(() {});
  }

  VendorPayload _payload() {
    return VendorPayload(
      name: _nameController.text,
      contactPerson: _blankToNull(_contactPersonController.text),
      phone: _phoneController.text,
      email: _blankToNull(_emailController.text),
      address: _blankToNull(_addressController.text),
      status: _status,
    );
  }

  Future<void> _save() async {
    final session = ref.read(authControllerProvider).session;
    final allowed = widget.isEditMode
        ? PermissionPolicy.canManageVendors(session)
        : PermissionPolicy.canCreateVendor(session);
    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You do not have permission for this action.'),
        ),
      );
      return;
    }
    setState(() => _submitted = true);
    if (!_isValid) return;
    final controller = ref.read(vendorControllerProvider.notifier);
    final vendor = widget.vendorId == null
        ? await controller.create(_payload())
        : await controller.update(widget.vendorId!, _payload());
    if (!mounted || vendor == null) return;

    ref.invalidate(vendorsProvider);
    ref.invalidate(dashboardControllerProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Vendor saved.')));
    context.replace('/vendors/${vendor.localId}');
  }

  void _cancel() {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
    } else {
      context.go('/vendors');
    }
  }

  bool get _isValid {
    if (_nameController.text.trim().isEmpty) return false;
    if (_phoneController.text.trim().isEmpty) return false;
    if (_status.trim().isEmpty) return false;
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_emailPattern.hasMatch(email)) return false;
    return true;
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _VendorFormBody extends StatelessWidget {
  const _VendorFormBody({
    required this.nameController,
    required this.contactPersonController,
    required this.phoneController,
    required this.emailController,
    required this.addressController,
    required this.status,
    required this.showValidation,
    required this.isMutating,
    required this.errorMessage,
    required this.onStatusChanged,
    required this.onCancel,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController contactPersonController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final String status;
  final bool showValidation;
  final bool isMutating;
  final String? errorMessage;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final nameError = showValidation && nameController.text.trim().isEmpty
        ? 'Name is required'
        : null;
    final phoneError = showValidation && phoneController.text.trim().isEmpty
        ? 'Phone is required'
        : null;
    final email = emailController.text.trim();
    final emailError =
        showValidation && email.isNotEmpty && !_emailPattern.hasMatch(email)
        ? 'Enter a valid email address'
        : null;
    final statusError = showValidation && status.trim().isEmpty
        ? 'Status is required'
        : null;

    return AppScreenListView(
      children: [
        AppSectionCard(
          padding: AppInsets.cardLarge,
          child: Column(
            children: [
              TextField(
                key: const Key('vendorNameField'),
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(AppIcons.vendors),
                  errorText: nameError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('vendorContactPersonField'),
                controller: contactPersonController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Contact Person',
                  prefixIcon: Icon(AppIcons.user),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('vendorPhoneField'),
                controller: phoneController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: const Icon(AppIcons.profile),
                  errorText: phoneError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('vendorEmailField'),
                controller: emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(AppIcons.mail),
                  errorText: emailError,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('vendorAddressField'),
                controller: addressController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(AppIcons.department),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('vendorStatusField-$status'),
                initialValue: status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: const Icon(AppIcons.circleCheck),
                  errorText: statusError,
                ),
                items: const [
                  DropdownMenuItem(
                    value: VendorStatus.active,
                    child: Text('Active'),
                  ),
                  DropdownMenuItem(
                    value: VendorStatus.inactive,
                    child: Text('Inactive'),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ],
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          AppEmptyCard(message: errorMessage!),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('cancelVendorButton'),
                onPressed: isMutating ? null : onCancel,
                icon: const Icon(AppIcons.x),
                label: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const Key('saveVendorButton'),
                onPressed: isMutating ? null : onSave,
                icon: isMutating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(AppIcons.check),
                label: const Text('Save Vendor'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
