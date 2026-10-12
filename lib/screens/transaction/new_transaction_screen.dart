import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_theme.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../services/app_settings.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/spend_hike_logo.dart';
import '../../widgets/theme_switcher.dart';

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  String _transactionType = 'Received';
  String _selectedCategory = 'Labour';
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<String> _attachments = [];
  bool _isUploadingAttachment = false;

  List<GroupModel> _groups = [];
  String? _selectedGroupId;
  bool _isLoadingGroups = true;

  String _tr(String text) => AppSettings.instance.tr(text);

  Future<void> _handleAttachment(String source) async {
    if (_attachments.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tr('Maximum 5 bill attachments allowed.'))),
      );
      return;
    }

    final XFile? file = source == 'Camera'
        ? await CloudinaryService.pickFromCamera()
        : await CloudinaryService.pickFromGallery();

    if (file == null) return;

    setState(() {
      _isUploadingAttachment = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_tr('Uploading bill image to Cloudinary...')),
        duration: const Duration(seconds: 2),
      ),
    );

    final url = await CloudinaryService.uploadImage(file, folder: 'spendhike_bills');

    if (mounted) {
      setState(() {
        _isUploadingAttachment = false;
        if (url != null && url.isNotEmpty) {
          _attachments.add(url);
        }
      });
      if (url != null && url.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('Bill attached successfully!')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr('Failed to upload bill to Cloudinary.')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final groups = await ApiService.getGroups();
    if (mounted) {
      setState(() {
        _groups = groups;
        if (_groups.isNotEmpty) {
          _selectedGroupId = _groups.first.id;
        }
        _isLoadingGroups = false;
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings.instance,
      builder: (context, _) {
        final colors = AppTheme.of(context);
        return Scaffold(
          backgroundColor: colors.background,
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: colors.isDark ? 0.06 : 0.2,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuAyzLTGsiBA-vRcd7qT0r0KaIIV8Yx_JqZR7s_eeLYNLtkUdLZfXy-bYSQ4z8kblJvf_hhMgjMMnT5bdM7Qqedieu7s--_7bP8dC7e6hZtrj6FGgEbEZd9i70KOSl2gGJbRRS2HiL18W0oKAHda7xsbwwC_HRoR-20DWBIBnDOcgnsbv5hI1S0KB5dPzf_1iy7QNuVobsEABHqfDp_WSsgkiZggSF86g53YKowAmU_Cfn6i-vaVi6VZ'),
                          fit: BoxFit.contain,
                          alignment: Alignment.topRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAmountSection(),
                        const SizedBox(height: 24),
                        _buildSegmentedControl(),
                        const SizedBox(height: 24),
                        _buildFormFields(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              _buildSaveButton(),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final colors = AppTheme.of(context);
    return AppBar(
      backgroundColor: colors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: colors.border, height: 1.0),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _tr('New Transaction'),
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
      ),
      actions: [
        const ThemeSwitcherButton(),
        const LanguageSwitcherButton(),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SpendHikeIcon(
            size: 28,
            walletColor: colors.textPrimary,
            arrowColor: colors.primary,
          ),
        ),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: colors.textSecondary),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAmountSection() {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.surface : const Color(0xFF1A2B3C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.isDark ? colors.border : Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _tr('ENTER AMOUNT'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.isDark ? colors.textMuted : const Color(0xFF8192A7),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: colors.isDark ? colors.textMuted : const Color(0xFF8192A7),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: colors.isDark ? colors.textPrimary : Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: (colors.isDark ? colors.textMuted : const Color(0xFF8192A7)).withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    final colors = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _buildSegmentItem('Received'),
          _buildSegmentItem('Debit'),
          _buildSegmentItem('Credit'),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(String title) {
    final colors = AppTheme.of(context);
    final isSelected = _transactionType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _transactionType = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _tr(title),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    final isDesktop = MediaQuery.of(context).size.width > 700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop)
          Row(
            children: [
              Expanded(child: _buildDatePicker()),
              const SizedBox(width: 24),
              Expanded(child: _buildGroupDropdown()),
            ],
          )
        else ...[
          _buildDatePicker(),
          const SizedBox(height: 24),
          _buildGroupDropdown(),
        ],
        const SizedBox(height: 24),
        _buildCategoryPicker(),
        const SizedBox(height: 24),
        _buildPaymentMethod(),
        const SizedBox(height: 24),
        _buildNotes(),
        const SizedBox(height: 24),
        _buildAttachments(),
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildAttachmentList(),
        ],
      ],
    );
  }

  Widget _buildDatePicker() {
    final colors = AppTheme.of(context);
    final formattedDate = _selectedDate.toLocal().toString().split(' ')[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month, size: 16, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(_tr('Transaction Date'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate,
                    style: TextStyle(fontSize: 16, color: colors.textPrimary)),
                Icon(Icons.calendar_today, color: colors.textSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupDropdown() {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.folder_outlined, size: 16, color: colors.textSecondary),
            const SizedBox(width: 4),
            Text(_tr('Project / Group'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: _isLoadingGroups
                ? SizedBox(
                    height: 24,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                      ),
                    ),
                  )
                : DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGroupId,
                    dropdownColor: colors.surface,
                    hint: Text(_tr('Select Project Group'), style: TextStyle(color: colors.textMuted)),
                    style: TextStyle(fontSize: 16, color: colors.textPrimary),
                    icon: Icon(Icons.expand_more, color: colors.textSecondary),
                    items: _groups.isEmpty
                        ? [
                            DropdownMenuItem(value: null, child: Text(_tr('General Ledger'))),
                          ]
                        : _groups.map((g) {
                            return DropdownMenuItem<String>(
                              value: g.id,
                              child: Text(g.title),
                            );
                          }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedGroupId = v;
                      });
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr('Category'),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCategoryChip('Labour', Icons.engineering),
            _buildCategoryChip('Material', Icons.architecture),
            _buildCategoryChip('Fuel', Icons.local_gas_station),
            _buildCategoryChip('Travel', Icons.flight),
            _buildCategoryChip('Other', Icons.category),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String title, IconData icon) {
    final colors = AppTheme.of(context);
    final isSelected = _selectedCategory == title;
    final activeBg = colors.isDark ? colors.primary : const Color(0xFF041627);
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : colors.surface,
          border: Border.all(
              color: isSelected ? activeBg : colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24,
                color: isSelected ? Colors.white : colors.textSecondary),
            const SizedBox(height: 8),
            Text(
              _tr(title),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr('Payment Method'),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildPaymentButton('Cash', Icons.payments)),
            const SizedBox(width: 12),
            Expanded(child: _buildPaymentButton('UPI', Icons.account_balance_wallet)),
            const SizedBox(width: 12),
            Expanded(child: _buildPaymentButton('Bank', Icons.account_balance)),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentButton(String title, IconData icon) {
    final colors = AppTheme.of(context);
    final isSelected = _selectedPaymentMethod == title;
    final activeBg = colors.isDark ? colors.primary.withValues(alpha: 0.25) : const Color(0xFFDCE9FF);
    final activeColor = colors.isDark ? colors.primary : const Color(0xFF041627);
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : colors.surface,
          border: Border.all(
              color: isSelected ? colors.primary : colors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? activeColor : colors.textSecondary),
            const SizedBox(height: 8),
            Text(
              _tr(title),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? activeColor : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_tr('Notes'),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          style: TextStyle(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: _tr('Add details about the transaction...'),
            hintStyle: TextStyle(color: colors.textMuted),
            filled: true,
            fillColor: colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments() {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_tr('Attachments'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
            Row(
              children: [
                Text(
                  '${_attachments.length}/5',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.primary),
                ),
                const SizedBox(width: 8),
                Text(_tr('Max 5MB each'),
                    style: TextStyle(fontSize: 12, color: colors.textMuted)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAttachmentCard(
                _tr('Capture Bill'),
                _tr('Use Camera'),
                Icons.add_a_photo,
                onTap: () => _handleAttachment('Camera'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAttachmentCard(
                _tr('Gallery'),
                _tr('Upload File'),
                Icons.upload_file,
                onTap: () => _handleAttachment('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentCard(String title, String subtitle, IconData icon,
      {required VoidCallback onTap}) {
    final colors = AppTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.isDark ? colors.surfaceSubtle : const Color(0xFF1A2B3C),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.isDark ? colors.textPrimary : const Color(0xFF8192A7), size: 32),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary)),
            Text(subtitle,
                style: TextStyle(fontSize: 10, color: colors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentList() {
    final colors = AppTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_tr('Attached Bill Files'),
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary)),
            if (_isUploadingAttachment)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ..._attachments.map((fileUrl) {
          final isImage = fileUrl.startsWith('http://') || fileUrl.startsWith('https://');

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                if (isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fileUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 48,
                        height: 48,
                        color: colors.primary,
                        child: const Icon(Icons.receipt, color: Colors.white),
                      ),
                    ),
                  )
                else
                  Icon(Icons.attach_file, size: 24, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isImage ? _tr('Cloudinary Bill Attachment') : fileUrl,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => setState(() => _attachments.remove(fileUrl)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSaveButton() {
    final colors = AppTheme.of(context);
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              colors.background,
              colors.background.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ElevatedButton(
              onPressed: _showSaveConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.isDark ? colors.primary : const Color(0xFF041627),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle),
                  const SizedBox(width: 8),
                  Text(
                    _tr('SAVE TRANSACTION'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Handlers ────────────────────────────────────────────────────────────────

  void _showSaveConfirmation() {
    final colors = AppTheme.of(context);
    final amount = _amountController.text.isEmpty ? '0.00' : _amountController.text;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF10b981), size: 28),
            const SizedBox(width: 10),
            Text(_tr('Confirm Transaction'), style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: colors.textPrimary,
            )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfirmRow(_tr('Type'), _tr(_transactionType)),
            _buildConfirmRow(_tr('Amount'), '₹$amount'),
            _buildConfirmRow(_tr('Category'), _tr(_selectedCategory)),
            _buildConfirmRow(_tr('Payment'), _tr(_selectedPaymentMethod)),
            if (_attachments.isNotEmpty)
              _buildConfirmRow(_tr('Attachments'), '${_attachments.length} file(s)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_tr('Review'), style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await ApiService.saveTransaction(
                amount: amount,
                type: _transactionType,
                category: _selectedCategory,
                paymentMethod: _selectedPaymentMethod,
                notes: _notesController.text.trim(),
                attachments: _attachments,
                projectId: _selectedGroupId,
              );
              if (mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_tr(res['message'] ?? 'Transaction saved successfully!')),
                    backgroundColor: const Color(0xFF10b981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: Text(_tr('Confirm & Save')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    final colors = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: colors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
        ],
      ),
    );
  }
}
