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

  // ─── CONTENT SWITCHER ──────────────────────────────────────────────────────

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

  // ─── SHEET HELPER ──────────────────────────────────────────────────────────

  void _showSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }

  // ─── LOGOUT DIALOG ─────────────────────────────────────────────────────────

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
// Profile header banner
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
            // Menggunakan image decoration agar gambar rapi mengikuti bentuk kontainer
            image: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(auth.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          // Tampilkan Icon hanya jika avatarUrl kosong
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
                auth.name ?? 'Guest',
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
// Menu tab section
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
            TextButton(
              onPressed: onEdit, // ✅ wired
              child: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: kSpaceXL),
        _DetailRow(
          icon: Icons.person_outline,
          label: 'Full Name',
          value: auth.name ?? '-',
        ),
        // _DetailRow(
        //   icon: Icons.alternate_email,
        //   label: 'Username',
        //   value: auth.username ?? '-',
        // ),
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
                _EmptyAddresses()
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
          '${addr.addressLine}, ${addr.city}, ${addr.province} ${addr.postalCode}',
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
// Account settings row (logout + change password)
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
// _EditProfileSheet — PUT /api/profile  (full_name, phone, avatar_url)
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
  // late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _avatarController;

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.auth.name ?? '');
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
        // Update local auth state with new values
        context.read<AuthProvider>().updateProfile(
          name: _nameController.text.trim(),
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
                // Header
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

                // Error
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
                // _SheetField(
                //   label: 'Username',
                //   controller: _usernameController,
                //   icon: Icons.alternate_email,
                //   validator: (v) {
                //     if (v == null || v.isEmpty) {
                //       return 'Username is required';
                //     }
                //     if (v.length < 3) {
                //       return 'Username min 3 characters';
                //     }
                //     return null;
                //   },
                // ),
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

                // Submit
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
// _ChangePasswordSheet — PUT /api/profile/password  (password_hash)
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
                // Header
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

                // Error
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
// AddressFormSheet — public, also used from menu
// ---------------------------------------------------------------------------

class AddressFormSheet extends StatefulWidget {
  final Address? address;

  const AddressFormSheet({super.key, this.address});

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalController = TextEditingController();

  bool _isDefault = false;

  bool get _isEdit => widget.address != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final a = widget.address!;
      _nameController.text = a.receiverName;
      _phoneController.text = a.phone;
      _addressController.text = a.addressLine;
      _cityController.text = a.city;
      _provinceController.text = a.province;
      _postalController.text = a.postalCode;
      _isDefault = a.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _cityController.clear();
    _provinceController.clear();
    _postalController.clear();
    setState(() => _isDefault = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final token = context.read<AuthProvider>().token!;
    final addressProv = context.read<AddressesProvider>();

    final body = <String, dynamic>{
      'label': 'Home',
      'receiver_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address_line': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'province': _provinceController.text.trim(),
      'postal_code': _postalController.text.trim(),
      'is_default': _isDefault,
    };

    final success = _isEdit
        ? await addressProv.updateAddress(token, widget.address!.id, body)
        : await addressProv.addAddress(token, body);

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_isEdit
                    ? 'Address updated successfully'
                    : 'Address added successfully')
              : (_isEdit
                    ? 'Failed to update address'
                    : 'Failed to add address'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade700 : kErrorColor,
      ),
    );
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
                      _isEdit ? 'Edit Address' : 'Add New Address',
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

                _FormField(
                  label: 'Recipient Name',
                  controller: _nameController,
                  icon: Icons.person_outline,
                ),
                _FormField(
                  label: 'Phone',
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                _FormField(
                  label: 'Address Line',
                  controller: _addressController,
                  icon: Icons.home_outlined,
                  maxLines: 2,
                ),
                _FormField(
                  label: 'City',
                  controller: _cityController,
                  icon: Icons.location_city_outlined,
                ),
                _FormField(
                  label: 'Province',
                  controller: _provinceController,
                  icon: Icons.map_outlined,
                ),
                _FormField(
                  label: 'Postal Code',
                  controller: _postalController,
                  icon: Icons.markunread_mailbox_outlined,
                  keyboardType: TextInputType.number,
                ),

                _DefaultToggle(
                  isDefault: _isDefault,
                  onChanged: (val) => setState(() => _isDefault = val),
                ),
                const SizedBox(height: kSpace2XL),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearForm,
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: kSpaceLG),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(
                          _isEdit ? 'Update Address' : 'Save Address',
                        ),
                      ),
                    ),
                  ],
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
// Shared form field widgets
// ---------------------------------------------------------------------------

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

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

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
          maxLines: maxLines,
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Please enter $label' : null,
          decoration: InputDecoration(
            hintText: 'Enter $label',
            prefixIcon: Icon(icon, color: kTextSecondaryColor, size: 22),
          ),
        ),
      ],
    ),
  );
}

class _DefaultToggle extends StatelessWidget {
  const _DefaultToggle({required this.isDefault, required this.onChanged});

  final bool isDefault;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: kSpaceLG,
      vertical: kSpaceXS,
    ),
    decoration: BoxDecoration(
      color: kSurfaceColor,
      borderRadius: BorderRadius.circular(kRadiusMD - 2),
      border: Border.all(
        color: isDefault ? kPrimaryColor : kBorderColor,
        width: isDefault ? 2 : 1,
      ),
    ),
    child: Row(
      children: [
        Icon(
          Icons.star_outline,
          size: 22,
          color: isDefault ? kPrimaryColor : kTextSecondaryColor,
        ),
        const SizedBox(width: kSpaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set as Default Address',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDefault ? kPrimaryColor : kTextPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Used automatically at checkout',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: kTextSecondaryColor),
              ),
            ],
          ),
        ),
        Switch(
          value: isDefault,
          onChanged: onChanged,
          activeThumbColor: kPrimaryColor,
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Error banner (shared)
// ---------------------------------------------------------------------------

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
