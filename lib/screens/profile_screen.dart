import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/addresses_model.dart';
import '../providers/auth_provider.dart';
import '../providers/carts_provider.dart';
import '../providers/addresses_provider.dart';
import '../utilities/constants.dart';
import '../widgets/header_widget.dart';
import '../widgets/footer_widget.dart';
import '../services/indonesia_region_service.dart';

// ---------------------------------------------------------------------------
// ProfileScreen
// ---------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedMenu = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<AddressesProvider>().loadAddresses(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn) {
      return const Scaffold(body: Center(child: Text('Please login first')));
    }

    return Scaffold(
      backgroundColor: kScaffoldBgColor,
      appBar: const HeaderWidget(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: kSpaceLG),
            _ProfileHeader(auth: auth),
            const SizedBox(height: kSpaceLG),
            _MenuSection(
              selectedMenu: _selectedMenu,
              onSelect: (i) => setState(() => _selectedMenu = i),
            ),
            const SizedBox(height: kSpaceLG),
            _buildContent(auth),
            const SizedBox(height: kSpaceLG),
            _AccountSettings(
              onLogout: () => _showLogoutDialog(context),
              onChangePassword: () =>
                  _showSheet(context, const _ChangePasswordSheet()),
            ),
            const SizedBox(height: kSpaceLG),
            const FooterWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AuthProvider auth) {
    switch (_selectedMenu) {
      case 1:
        return const _TransactionsCard();
      case 2:
        return const _AddressesCard();
      default:
        return _ProfileDetails(
          auth: auth,
          onEdit: () => _showSheet(context, _EditProfileSheet(auth: auth)),
        );
    }
  }

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kSpaceXL),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: kTextSecondaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.read<CartsProvider>().clearCart();
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusSM + 2),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared card shell
// ---------------------------------------------------------------------------

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
    padding: const EdgeInsets.all(kSpaceXL),
    decoration: BoxDecoration(
      color: kSurfaceColor,
      borderRadius: BorderRadius.circular(kRadiusLG),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// Profile header
// ---------------------------------------------------------------------------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.auth});
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
    padding: const EdgeInsets.all(kSpace2XL),
    decoration: BoxDecoration(
      color: kPrimaryColor,
      borderRadius: BorderRadius.circular(kRadiusXL),
    ),
    child: Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(kSpaceXL),
            border: Border.all(color: Colors.white, width: 3),
            image: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(auth.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
              ? null
              : const Icon(Icons.person, size: 40, color: kTextSecondaryColor),
        ),
        const SizedBox(width: kSpaceLG),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.full_name ?? 'Guest',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: kSpaceXS + 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceMD,
                  vertical: kSpaceXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(kSpaceXL),
                ),
                child: Text(
                  auth.role ?? 'Customer',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Menu section
// ---------------------------------------------------------------------------

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.selectedMenu, required this.onSelect});
  final int selectedMenu;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
    decoration: BoxDecoration(
      color: kSurfaceColor,
      borderRadius: BorderRadius.circular(kRadiusLG),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        _MenuItem(
          icon: Icons.person_outline,
          title: 'Profile',
          subtitle: 'View your personal information',
          isSelected: selectedMenu == 0,
          onTap: () => onSelect(0),
        ),
        Divider(height: 1, color: kBorderColor),
        _MenuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Transaction',
          subtitle: 'Items you ordered',
          isSelected: selectedMenu == 1,
          onTap: () => onSelect(1),
        ),
        Divider(height: 1, color: kBorderColor),
        _MenuItem(
          icon: Icons.location_on_outlined,
          title: 'Addresses',
          subtitle: 'Manage shipping addresses',
          isSelected: selectedMenu == 2,
          onTap: () => onSelect(2),
        ),
      ],
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: kSpaceXL,
      vertical: kSpaceSM,
    ),
    leading: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isSelected
            ? kPrimaryColor
            : kPrimaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(kRadiusMD - 2),
      ),
      child: Icon(
        icon,
        color: isSelected ? Colors.white : kPrimaryColor,
        size: 24,
      ),
    ),
    title: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: isSelected ? kPrimaryColor : kTextPrimaryColor,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
    ),
    trailing: Icon(
      Icons.chevron_right,
      color: isSelected ? kPrimaryColor : kBorderColor,
    ),
  );
}

// ---------------------------------------------------------------------------
// Profile details tab
// ---------------------------------------------------------------------------

class _ProfileDetails extends StatelessWidget {
  const _ProfileDetails({required this.auth, required this.onEdit});
  final AuthProvider auth;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => _CardShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Personal Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(onPressed: onEdit, child: const Text('Edit')),
          ],
        ),
        const SizedBox(height: kSpaceXL),
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Full Name',
          value: auth.full_name ?? '-',
        ),
        _DetailRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: auth.email ?? '-',
        ),
        _DetailRow(
          icon: Icons.phone_outlined,
          label: 'Phone Number',
          value: auth.phone ?? '-',
        ),
      ],
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: kSpaceLG),
    child: Row(
      children: [
        Icon(icon, size: 20, color: kTextSecondaryColor),
        const SizedBox(width: kSpaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
              ),
              const SizedBox(height: kSpaceXS),
              Text(value, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Transactions tab (placeholder)
// ---------------------------------------------------------------------------

class _TransactionsCard extends StatelessWidget {
  const _TransactionsCard();

  @override
  Widget build(BuildContext context) => _CardShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Transactions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: kSpaceXL),
        Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: kBorderColor,
              ),
              const SizedBox(height: kSpaceLG),
              Text(
                'No transactions yet',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: kTextSecondaryColor),
              ),
              const SizedBox(height: kSpaceSM),
              Text(
                'Start shopping to see your orders here',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Addresses tab
// ---------------------------------------------------------------------------

class _AddressesCard extends StatelessWidget {
  const _AddressesCard();

  void _showAddressSheet(BuildContext context, {Address? addr}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressFormSheet(address: addr),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: kErrorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final token = context.read<AuthProvider>().token!;
              await context.read<AddressesProvider>().deleteAddress(token, id);
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AddressesProvider>(
      builder: (context, prov, _) {
        if (prov.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        return _CardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Addresses',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddressSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: kSpaceLG),
              if (prov.addresses.isEmpty)
                const _EmptyAddresses()
              else
                Column(
                  children: prov.addresses
                      .map(
                        (addr) => _AddressCard(
                          addr: addr,
                          onEdit: () => _showAddressSheet(context, addr: addr),
                          onDelete: () => _confirmDelete(context, addr.id),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.addr,
    required this.onEdit,
    required this.onDelete,
  });
  final Address addr;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: kSpaceMD),
    padding: const EdgeInsets.all(kSpaceLG),
    decoration: BoxDecoration(
      color: kScaffoldBgColor,
      borderRadius: BorderRadius.circular(kRadiusMD - 2),
      border: Border.all(
        color: addr.isDefault ? kPrimaryColor : kBorderColor,
        width: addr.isDefault ? 2 : 1,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: kSpaceXS + 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        addr.receiverName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (addr.label.isNotEmpty)
                        _Badge(
                          label: addr.label,
                          bgColor: kScaffoldBgColor,
                          textColor: kTextSecondaryColor,
                        ),
                      if (addr.isDefault)
                        const _Badge(
                          label: 'Default',
                          bgColor: kPrimaryColor,
                          textColor: Colors.white,
                        ),
                    ],
                  ),
                  const SizedBox(height: kSpaceXS),
                  Text(
                    addr.phone,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
                color: kPrimaryColor,
                size: 20,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: kErrorColor,
                size: 20,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
        const SizedBox(height: kSpaceSM),
        Text(
          addr.fullAddress,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.bgColor,
    required this.textColor,
  });
  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: kSpaceSM, vertical: 2),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(kSpaceXS + 2),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: textColor,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        const SizedBox(height: kSpace2XL),
        const Icon(Icons.location_off_outlined, size: 80, color: kBorderColor),
        const SizedBox(height: kSpaceLG),
        Text(
          'No address yet',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: kTextSecondaryColor),
        ),
        const SizedBox(height: kSpaceSM),
        Text(
          'Add your shipping address',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
        ),
        const SizedBox(height: kSpace2XL),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Account settings row
// ---------------------------------------------------------------------------

class _AccountSettings extends StatelessWidget {
  const _AccountSettings({
    required this.onLogout,
    required this.onChangePassword,
  });
  final VoidCallback onLogout;
  final VoidCallback onChangePassword;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: kSpaceLG),
    decoration: BoxDecoration(
      color: kSurfaceColor,
      borderRadius: BorderRadius.circular(kRadiusLG),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        ListTile(
          onTap: onChangePassword,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: kSpaceXL,
            vertical: kSpaceXS,
          ),
          leading: const Icon(
            Icons.lock_outline,
            color: kPrimaryColor,
            size: 24,
          ),
          title: Text(
            'Change Password',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          trailing: const Icon(Icons.chevron_right, color: kBorderColor),
        ),
        Divider(height: 1, color: kBorderColor),
        ListTile(
          onTap: onLogout,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: kSpaceXL,
            vertical: kSpaceXS,
          ),
          leading: const Icon(Icons.logout, color: kErrorColor, size: 24),
          title: Text(
            'Logout',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: kErrorColor),
          ),
          trailing: const Icon(Icons.chevron_right, color: kBorderColor),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// _EditProfileSheet
// ---------------------------------------------------------------------------

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.auth});
  final AuthProvider auth;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.auth.full_name ?? '');
    _phoneController = TextEditingController(text: widget.auth.phone ?? '');
    _avatarController = TextEditingController(
      text: widget.auth.avatarUrl ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token!;
      final response = await http.put(
        Uri.parse('$kBaseUrl/api/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'full_name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'avatar_url': _avatarController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        context.read<AuthProvider>().updateProfile(
          full_name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          avatarUrl: _avatarController.text.trim(),
        );
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _error = data['message'] ?? 'Update failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: kScaffoldBgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kSpace2XL)),
        ),
        padding: EdgeInsets.only(
          left: kSpaceXL,
          right: kSpaceXL,
          top: kSpace2XL,
          bottom: MediaQuery.of(context).viewInsets.bottom + kSpace2XL,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: kScaffoldBgColor,
                        padding: const EdgeInsets.all(kSpaceSM),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpace2XL),
                if (_error != null) ...[
                  _ErrorBanner(
                    message: _error!,
                    onDismiss: () => setState(() => _error = null),
                  ),
                  const SizedBox(height: kSpaceLG),
                ],
                _SheetField(
                  label: 'Full Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Name is required' : null,
                ),
                _SheetField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Phone is required' : null,
                ),
                _SheetField(
                  label: 'Avatar URL (optional)',
                  controller: _avatarController,
                  icon: Icons.image_outlined,
                  required: false,
                ),
                const SizedBox(height: kSpaceSM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ChangePasswordSheet
// ---------------------------------------------------------------------------

class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newController.text != _confirmController.text) {
      setState(() => _error = 'New passwords do not match');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = context.read<AuthProvider>().token!;
      final response = await http.put(
        Uri.parse('$kBaseUrl/api/profile/password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': _currentController.text,
          'password': _newController.text,
          'password_confirmation': _confirmController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _error = data['message'] ?? 'Password update failed');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: kScaffoldBgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kSpace2XL)),
        ),
        padding: EdgeInsets.only(
          left: kSpaceXL,
          right: kSpaceXL,
          top: kSpace2XL,
          bottom: MediaQuery.of(context).viewInsets.bottom + kSpace2XL,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Change Password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: kScaffoldBgColor,
                        padding: const EdgeInsets.all(kSpaceSM),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: kSpace2XL),
                if (_error != null) ...[
                  _ErrorBanner(
                    message: _error!,
                    onDismiss: () => setState(() => _error = null),
                  ),
                  const SizedBox(height: kSpaceLG),
                ],
                _PasswordField(
                  label: 'Current Password',
                  controller: _currentController,
                  obscure: _obscureCurrent,
                  onToggle: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Current password is required'
                      : null,
                ),
                _PasswordField(
                  label: 'New Password',
                  controller: _newController,
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'New password is required';
                    }
                    if (v.length < 8) return 'Must be at least 8 characters';
                    return null;
                  },
                ),
                _PasswordField(
                  label: 'Confirm New Password',
                  controller: _confirmController,
                  obscure: _obscureConfirm,
                  onToggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please confirm your new password'
                      : null,
                ),
                const SizedBox(height: kSpaceSM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AddressFormSheet
// Cascading dropdowns: Province → City/Regency → District → Subdistrict
// Pre-selection strategy (edit mode):
//   1. Match by ID   (reliable if API returns IDs)
//   2. Match by name (fallback — handles addresses saved before IDs existed)
// ---------------------------------------------------------------------------

class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({super.key, this.address});
  final Address? address;

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _labelCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressLineCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _rtCtrl;
  late final TextEditingController _rwCtrl;

  List<RegionItem> _provinces = [];
  List<RegionItem> _cities = [];
  List<RegionItem> _districts = [];
  List<RegionItem> _subdistricts = [];

  RegionItem? _selectedProvince;
  RegionItem? _selectedCity;
  RegionItem? _selectedDistrict;
  RegionItem? _selectedSubdistrict;

  bool _loadingProvinces = false;
  bool _loadingCities = false;
  bool _loadingDistricts = false;
  bool _loadingSubdistricts = false;

  bool _isDefault = false;
  bool _submitting = false;
  String? _error;

  bool get _isEdit => widget.address != null;

  // ── Helpers for robust matching ───────────────────────────────────────────

  /// Finds the first item that matches by [id] (exact), then falls back to
  /// [name] (case-insensitive). Returns null if nothing matches.
  RegionItem? _match(
    List<RegionItem> items, {
    required String id,
    required String name,
  }) {
    if (id.isNotEmpty) {
      final byId = items.where((i) => i.id == id).firstOrNull;
      if (byId != null) return byId;
    }
    if (name.isNotEmpty) {
      final byName = items
          .where((i) => i.name.toLowerCase() == name.toLowerCase())
          .firstOrNull;
      return byName;
    }
    return null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _labelCtrl = TextEditingController(text: a?.label ?? '');
    _nameCtrl = TextEditingController(text: a?.receiverName ?? '');
    _phoneCtrl = TextEditingController(text: a?.phone ?? '');
    _addressLineCtrl = TextEditingController(text: a?.addressLine ?? '');
    _postalCtrl = TextEditingController(text: a?.postalCode ?? '');
    _rtCtrl = TextEditingController(text: a?.rt ?? '');
    _rwCtrl = TextEditingController(text: a?.rw ?? '');
    _isDefault = a?.isDefault ?? false;
    _loadProvinces();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressLineCtrl.dispose();
    _postalCtrl.dispose();
    _rtCtrl.dispose();
    _rwCtrl.dispose();
    super.dispose();
  }

  // ── Region loaders ────────────────────────────────────────────────────────

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    final items = await IndonesiaRegionService.fetchProvinces();
    if (!mounted) return;
    setState(() {
      _provinces = items;
      _loadingProvinces = false;
    });

    final a = widget.address;
    if (a == null) return;

    // FIX: match by ID first, then fall back to province name from API
    final match = _match(items, id: a.provinceId, name: a.province);
    if (match != null) {
      setState(() => _selectedProvince = match);
      await _loadCities(match, preselect: a);
    }
  }

  Future<void> _loadCities(RegionItem province, {Address? preselect}) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
      _districts = [];
      _subdistricts = [];
      if (preselect == null) {
        _selectedCity = null;
        _selectedDistrict = null;
        _selectedSubdistrict = null;
      }
    });
    final items = await IndonesiaRegionService.fetchRegencies(province.id);
    if (!mounted) return;
    setState(() {
      _cities = items;
      _loadingCities = false;
    });

    if (preselect == null) return;

    // FIX: match by ID first, then fall back to city name
    final match = _match(items, id: preselect.cityId, name: preselect.city);
    if (match != null) {
      setState(() => _selectedCity = match);
      await _loadDistricts(match, preselect: preselect);
    }
  }

  Future<void> _loadDistricts(RegionItem city, {Address? preselect}) async {
    setState(() {
      _loadingDistricts = true;
      _districts = [];
      _subdistricts = [];
      if (preselect == null) {
        _selectedDistrict = null;
        _selectedSubdistrict = null;
      }
    });
    final items = await IndonesiaRegionService.fetchDistricts(city.id);
    if (!mounted) return;
    setState(() {
      _districts = items;
      _loadingDistricts = false;
    });

    if (preselect == null) return;

    // FIX: match by ID first, then fall back to district name
    final match = _match(
      items,
      id: preselect.districtId,
      name: preselect.district,
    );
    if (match != null) {
      setState(() => _selectedDistrict = match);
      await _loadSubdistricts(match, preselect: preselect);
    }
  }

  Future<void> _loadSubdistricts(
    RegionItem district, {
    Address? preselect,
  }) async {
    setState(() {
      _loadingSubdistricts = true;
      _subdistricts = [];
      if (preselect == null) _selectedSubdistrict = null;
    });
    final items = await IndonesiaRegionService.fetchVillages(district.id);
    if (!mounted) return;
    setState(() {
      _subdistricts = items;
      _loadingSubdistricts = false;
    });

    if (preselect == null) return;

    // FIX: match by ID first, then fall back to subdistrict name
    final match = _match(
      items,
      id: preselect.subdistrictId,
      name: preselect.subdistrict,
    );
    if (match != null) setState(() => _selectedSubdistrict = match);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null ||
        _selectedCity == null ||
        _selectedDistrict == null ||
        _selectedSubdistrict == null) {
      setState(() => _error = 'Please complete the regional address fields.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final body = {
      'label': _labelCtrl.text.trim(),
      'receiver_name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address_line': _addressLineCtrl.text.trim(),
      'province': _selectedProvince!.name,
      'province_id': _selectedProvince!.id,
      'city': _selectedCity!.name,
      'city_id': _selectedCity!.id,
      'district': _selectedDistrict!.name,
      'district_id': _selectedDistrict!.id,
      'subdistrict': _selectedSubdistrict!.name,
      'subdistrict_id': _selectedSubdistrict!.id,
      'postal_code': _postalCtrl.text.trim(),
      'rt': _rtCtrl.text.trim(),
      'rw': _rwCtrl.text.trim(),
      'is_default': _isDefault,
    };

    final token = context.read<AuthProvider>().token!;
    final prov = context.read<AddressesProvider>();

    final bool success = _isEdit
        ? await prov.updateAddress(token, widget.address!.id, body)
        : await prov.addAddress(token, body);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Address updated successfully'
                : 'Address added successfully',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _error = 'Failed to save address. Please try again.');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: kScaffoldBgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(kSpace2XL)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.97,
          builder: (_, scrollController) => Column(
            children: [
              // drag handle
              Container(
                margin: const EdgeInsets.only(top: kSpaceMD, bottom: kSpaceSM),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: kBorderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // header
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kSpace2XL,
                  kSpaceSM,
                  kSpaceLG,
                  kSpaceLG,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEdit ? 'Edit Address' : 'Add Address',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: kSurfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kRadiusMD - 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // form
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      kSpace2XL,
                      0,
                      kSpace2XL,
                      kSpace3XL,
                    ),
                    children: [
                      // error banner
                      if (_error != null) ...[
                        _ErrorBanner(
                          message: _error!,
                          onDismiss: () => setState(() => _error = null),
                        ),
                        const SizedBox(height: kSpaceXL),
                      ],

                      // ── Recipient ──────────────────────────────────────
                      _SectionLabel(label: 'Recipient'),
                      const SizedBox(height: kSpaceMD),
                      _AddressField(
                        label: 'Label',
                        hint: 'e.g. Home, Office',
                        icon: Icons.label_outline,
                        controller: _labelCtrl,
                      ),
                      const SizedBox(height: kSpaceLG),
                      _AddressField(
                        label: 'Receiver Name',
                        hint: 'Full name',
                        icon: Icons.person_outline,
                        controller: _nameCtrl,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: kSpaceLG),
                      _AddressField(
                        label: 'Phone Number',
                        hint: '08xxxxxxxxxx',
                        icon: Icons.phone_outlined,
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.length < 9)
                            ? 'Enter a valid phone number'
                            : null,
                      ),

                      const SizedBox(height: kSpace2XL),
                      Divider(color: kBorderColor),
                      const SizedBox(height: kSpaceLG),

                      // ── Region ─────────────────────────────────────────
                      _SectionLabel(label: 'Region'),
                      const SizedBox(height: kSpaceMD),

                      _RegionDropdown(
                        label: 'Province',
                        items: _provinces,
                        selected: _selectedProvince,
                        isLoading: _loadingProvinces,
                        onChanged: (item) {
                          setState(() {
                            _selectedProvince = item;
                            // reset lower levels
                            _selectedCity = null;
                            _selectedDistrict = null;
                            _selectedSubdistrict = null;
                            _cities = [];
                            _districts = [];
                            _subdistricts = [];
                          });
                          if (item != null) _loadCities(item);
                        },
                      ),
                      const SizedBox(height: kSpaceLG),

                      _RegionDropdown(
                        label: 'City / Regency',
                        items: _cities,
                        selected: _selectedCity,
                        isLoading: _loadingCities,
                        enabled: _selectedProvince != null,
                        onChanged: (item) {
                          setState(() {
                            _selectedCity = item;
                            _selectedDistrict = null;
                            _selectedSubdistrict = null;
                            _districts = [];
                            _subdistricts = [];
                          });
                          if (item != null) _loadDistricts(item);
                        },
                      ),
                      const SizedBox(height: kSpaceLG),

                      _RegionDropdown(
                        label: 'District (Kecamatan)',
                        items: _districts,
                        selected: _selectedDistrict,
                        isLoading: _loadingDistricts,
                        enabled: _selectedCity != null,
                        onChanged: (item) {
                          setState(() {
                            _selectedDistrict = item;
                            _selectedSubdistrict = null;
                            _subdistricts = [];
                          });
                          if (item != null) _loadSubdistricts(item);
                        },
                      ),
                      const SizedBox(height: kSpaceLG),

                      _RegionDropdown(
                        label: 'Subdistrict (Kelurahan/Desa)',
                        items: _subdistricts,
                        selected: _selectedSubdistrict,
                        isLoading: _loadingSubdistricts,
                        enabled: _selectedDistrict != null,
                        onChanged: (item) =>
                            setState(() => _selectedSubdistrict = item),
                      ),

                      const SizedBox(height: kSpace2XL),
                      Divider(color: kBorderColor),
                      const SizedBox(height: kSpaceLG),

                      // ── Detail ─────────────────────────────────────────
                      _SectionLabel(label: 'Detail Address'),
                      const SizedBox(height: kSpaceMD),

                      Row(
                        children: [
                          Expanded(
                            child: _AddressField(
                              label: 'RT',
                              hint: '001',
                              icon: Icons.tag,
                              controller: _rtCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: kSpaceMD),
                          Expanded(
                            child: _AddressField(
                              label: 'RW',
                              hint: '001',
                              icon: Icons.tag,
                              controller: _rwCtrl,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: kSpaceLG),

                      _AddressField(
                        label: 'Address Line',
                        hint: 'Street name, house number, building name, etc.',
                        icon: Icons.home_outlined,
                        controller: _addressLineCtrl,
                        maxLines: 3,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: kSpaceLG),

                      _AddressField(
                        label: 'Postal Code',
                        hint: '12345',
                        icon: Icons.local_post_office_outlined,
                        controller: _postalCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) => (v == null || v.length < 5)
                            ? 'Enter a valid postal code'
                            : null,
                      ),

                      const SizedBox(height: kSpace2XL),

                      // ── Default toggle ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpaceLG,
                          vertical: kSpaceSM,
                        ),
                        decoration: BoxDecoration(
                          color: kSurfaceColor,
                          borderRadius: BorderRadius.circular(kRadiusMD),
                          border: Border.all(color: kBorderColor),
                        ),
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _isDefault,
                          onChanged: (v) => setState(() => _isDefault = v),
                          title: const Text('Set as default address'),
                          activeThumbColor: kPrimaryColor,
                        ),
                      ),

                      const SizedBox(height: kSpace2XL),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _isEdit ? 'Update Address' : 'Save Address',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared form widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: kTextPrimaryColor),
  );
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: kTextPrimaryColor,
        ),
      ),
      const SizedBox(height: kSpaceXS + 2),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: maxLines == 1 ? Icon(icon, size: 20) : null,
        ),
      ),
    ],
  );
}

class _RegionDropdown extends StatelessWidget {
  const _RegionDropdown({
    required this.label,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.isLoading = false,
    this.enabled = true,
  });
  final String label;
  final List<RegionItem> items;
  final RegionItem? selected;
  final void Function(RegionItem?) onChanged;
  final bool isLoading;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: enabled ? kTextPrimaryColor : kTextSecondaryColor,
        ),
      ),
      const SizedBox(height: kSpaceXS + 2),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: kSpaceLG),
        decoration: BoxDecoration(
          color: enabled ? null : kScaffoldBgColor,
          border: Border.all(
            color: enabled ? kBorderColor : kBorderColor.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(kRadiusMD - 2),
        ),
        child: isLoading
            ? const SizedBox(
                height: 52,
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: kSpaceMD),
                    Text('Loading...'),
                  ],
                ),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<RegionItem>(
                  value: selected,
                  isExpanded: true,
                  hint: Text(
                    enabled
                        ? 'Select $label'
                        : 'Select ${_parentLabel(label)} first',
                    style: TextStyle(color: kTextSecondaryColor, fontSize: 14),
                  ),
                  items: items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: enabled ? onChanged : null,
                ),
              ),
      ),
    ],
  );

  String _parentLabel(String label) {
    if (label.contains('City')) return 'Province';
    if (label.contains('District')) return 'City';
    if (label.contains('Subdistrict')) return 'District';
    return 'region';
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.validator,
    this.required = true,
  });
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool required;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: kSpaceLG),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: kSpaceSM),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            prefixIcon: Icon(icon, size: 22),
          ),
        ),
      ],
    ),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: kSpaceLG),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: kSpaceSM),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: label,
            prefixIcon: const Icon(Icons.lock_outline, size: 22),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 22,
                color: kTextSecondaryColor,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(kSpaceLG),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(kRadiusMD - 2),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: kErrorColor, size: 22),
        const SizedBox(width: kSpaceMD),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: kErrorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: kErrorColor, size: 20),
          onPressed: onDismiss,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    ),
  );
}
