import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/app_models.dart';
import '../../services/api_service.dart';
import '../../services/cloudinary_service.dart';
import '../../widgets/spend_hike_logo.dart';

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

  Future<void> _handleAttachment(String source) async {
    if (_attachments.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 bill attachments allowed.')),
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
      const SnackBar(
        content: Text('Uploading bill image to Cloudinary...'),
        duration: Duration(seconds: 2),
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
          const SnackBar(
            content: Text('Bill attached successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload bill to Cloudinary.'),
            backgroundColor: Color(0xFFEF4444),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.2,
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
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FF),
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFFC4C6CD), height: 1.0),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF44474C)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'New Transaction',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF041627)),
      ),
      actions: [
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: SpendHikeIcon(
            size: 28,
            walletColor: Color(0xFF041627),
            arrowColor: Color(0xFF0066FF),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF44474C)),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAmountSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B3C),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'ENTER AMOUNT',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8192A7),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '₹',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8192A7),
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
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      color: const Color(0xFF8192A7).withOpacity(0.5),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(12),
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
    final isSelected = _transactionType == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _transactionType = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF356EE7) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFFFEFCFF) : const Color(0xFF44474C),
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
    final formattedDate = _selectedDate.toLocal().toString().split(' ')[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.calendar_month, size: 16, color: Color(0xFF44474C)),
            SizedBox(width: 4),
            Text('Transaction Date',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF44474C))),
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
              color: Colors.white,
              border: Border.all(color: const Color(0xFFC4C6CD)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formattedDate,
                    style: const TextStyle(fontSize: 16, color: Color(0xFF0B1C30))),
                const Icon(Icons.calendar_today, color: Color(0xFF44474C), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.folder_outlined, size: 16, color: Color(0xFF44474C)),
            SizedBox(width: 4),
            Text('Project / Group',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF44474C))),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC4C6CD)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: _isLoadingGroups
                ? const SizedBox(
                    height: 24,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0453CD)),
                      ),
                    ),
                  )
                : DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedGroupId,
                    hint: const Text('Select Project Group'),
                    style: const TextStyle(fontSize: 16, color: Color(0xFF0B1C30)),
                    icon: const Icon(Icons.expand_more, color: Color(0xFF44474C)),
                    items: _groups.isEmpty
                        ? const [
                            DropdownMenuItem(value: null, child: Text('General Ledger')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF44474C))),
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
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF041627) : Colors.transparent,
          border: Border.all(
              color: isSelected ? const Color(0xFF041627) : const Color(0xFFC4C6CD)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24,
                color: isSelected ? Colors.white : const Color(0xFF44474C)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF44474C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF44474C))),
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
    final isSelected = _selectedPaymentMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDCE9FF) : Colors.white,
          border: Border.all(
              color: isSelected ? const Color(0xFF041627) : const Color(0xFFC4C6CD)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected ? const Color(0xFF041627) : const Color(0xFF44474C)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF041627) : const Color(0xFF44474C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notes',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF44474C))),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add details about the transaction...',
            hintStyle: const TextStyle(color: Color(0xFF74777D)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC4C6CD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFC4C6CD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF041627)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Attachments',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF44474C))),
            Row(
              children: [
                Text(
                  '${_attachments.length}/5',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0453CD)),
                ),
                const SizedBox(width: 8),
                const Text('Max 5MB each',
                    style: TextStyle(fontSize: 12, color: Color(0xFF44474C))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAttachmentCard(
                'Capture Bill',
                'Use Camera',
                Icons.add_a_photo,
                onTap: () => _handleAttachment('Camera'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildAttachmentCard(
                'Gallery',
                'Upload File',
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: const Color(0xFF041627).withOpacity(0.3),
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF1A2B3C),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF8192A7), size: 32),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B1C30))),
            Text(subtitle,
                style: const TextStyle(fontSize: 10, color: Color(0xFF44474C))),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Attached Bill Files',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF44474C))),
            if (_isUploadingAttachment)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0453CD)),
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
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFADC6FF)),
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
                        color: const Color(0xFF0453CD),
                        child: const Icon(Icons.receipt, color: Colors.white),
                      ),
                    ),
                  )
                else
                  const Icon(Icons.attach_file, size: 24, color: Color(0xFF0453CD)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isImage ? 'Cloudinary Bill Attachment' : fileUrl,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF041627),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fileUrl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
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
              const Color(0xFFF8F9FF),
              const Color(0xFFF8F9FF).withOpacity(0.0),
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ElevatedButton(
              onPressed: _showSaveConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF041627),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle),
                  SizedBox(width: 8),
                  Text(
                    'SAVE TRANSACTION',
                    style: TextStyle(
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
    final amount = _amountController.text.isEmpty ? '0.00' : _amountController.text;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10b981), size: 28),
            SizedBox(width: 10),
            Text('Confirm Transaction', style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildConfirmRow('Type', _transactionType),
            _buildConfirmRow('Amount', '₹$amount'),
            _buildConfirmRow('Category', _selectedCategory),
            _buildConfirmRow('Payment', _selectedPaymentMethod),
            if (_attachments.isNotEmpty)
              _buildConfirmRow('Attachments', '${_attachments.length} file(s)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review', style: TextStyle(color: Color(0xFF74777D))),
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
                    content: Text(res['message'] ?? 'Transaction saved successfully!'),
                    backgroundColor: const Color(0xFF10b981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirm & Save'),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Color(0xFF44474C))),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF041627))),
        ],
      ),
    );
  }
}
