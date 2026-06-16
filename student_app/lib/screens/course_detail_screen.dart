import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../models/student.dart';
import '../theme/student_ui.dart';

class CourseDetailScreen extends StatefulWidget {
  final Student student;
  final String courseId;
  final AppSettings settings;

  const CourseDetailScreen({
    super.key,
    required this.student,
    required this.courseId,
    this.settings = AppSettings.fallback,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _course;

  final _addressController = TextEditingController();
  final _teacherNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitting = false;

  bool _modeOnlineAvailable = false;
  bool _modeOfflineAvailable = true;
  String _selectedMode = 'offline';

  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _loadCourse();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _addressController.dispose();
    _teacherNameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCourse() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient();
      final res = await api.getCourseById(widget.courseId);
      final data = res.data as Map<String, dynamic>;

      final modeOptions = data['modeOptions'] as Map<String, dynamic>?;

      _course = data;
      _modeOnlineAvailable = modeOptions?['online'] == true;
      _modeOfflineAvailable = modeOptions?['offline'] != false;
      _selectedMode = _modeOfflineAvailable ? 'offline' : 'online';
    } catch (e) {
      _error = 'Error loading course';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _requestOffline() async {
    if (!_modeOfflineAvailable) return;

    final address = _addressController.text.trim();
    final teacherName = _teacherNameController.text.trim();
    final phone = _phoneController.text.trim();
    final message = _messageController.text.trim();

    if (address.isEmpty || teacherName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill address, teacher name, and phone.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final api = ApiClient();
      final res = await api.requestOfflineAdmission(
        studentId: widget.student.id,
        courseId: widget.courseId,
        address: address,
        teacherName: teacherName,
        phone: phone,
        message: message,
      );

      final data = res.data as Map<String, dynamic>?;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data?['message'] ?? 'Enrollment request created',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error creating enrollment request'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _startOnlinePayment() async {
    final c = _course;
    if (c == null) return;

    final price = c['price'] ?? 0;
    final int amount = (price is int) ? price : int.tryParse('$price') ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid course price')),
      );
      return;
    }

    try {
      final api = ApiClient();

      // 1) Ask backend to create Razorpay order
      final res = await api.post(
        '/payment/order',
        data: {
          'amount': amount, // rupees; backend multiplies * 100
          'currency': 'INR',
          'receipt': 'course_${widget.courseId}_${widget.student.id}',
          'notes': {
            'courseId': widget.courseId,
            'studentId': widget.student.id,
          },
        },
      );

      final order = res.data as Map<String, dynamic>;
      final orderId = order['id'] as String;

      // 2) Open Razorpay checkout
      final options = {
        'key': 'YOUR_RAZORPAY_KEY_ID', // replace with your public key
        'amount': amount * 100,
        'currency': 'INR',
        'name': widget.settings.brandName,
        'description': c['title'] ?? 'Course payment',
        'order_id': orderId,
        'prefill': {
          'contact': '', // you can prefill phone from student model
          'email': '',
        },
        'notes': {
          'courseId': widget.courseId,
          'studentId': widget.student.id,
        },
      };

      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start payment')),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // TODO: optionally send response.paymentId/orderId/signature to backend
    // and mark enrollment as paid there.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful')),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet: ${response.walletName}'),
      ),
    );
  }

  String _buildCoverUrl(String raw) {
    if (raw.startsWith('http')) return raw;
    // adjust host (10.0.2.2, LAN IP, or domain)
    return '${ApiClient().baseUrl}/${raw.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = _course;

    return Scaffold(
      backgroundColor: StudentColors.bg,
      appBar: AppBar(
        backgroundColor: StudentColors.bg,
        elevation: 0,
        title: Row(
          children: [
            StudentBrandMark(settings: widget.settings, size: 32, radius: 10),
            const SizedBox(width: 10),
            const Text(
              'Course detail',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                StudentSkeletonCard(height: 240),
                StudentSkeletonCard(height: 86),
                StudentSkeletonCard(height: 86),
              ],
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudentEmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Course unavailable',
                      message: _error!,
                      actionLabel: 'Retry',
                      onAction: _loadCourse,
                    ),
                  ),
                )
              : c == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: StudentEmptyState(
                          icon: Icons.menu_book_outlined,
                          title: 'Course not found',
                          message: 'This course may have been removed.',
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // top card with image
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF020617)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: const Color(0xFF1F2937),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 20,
                                  offset: Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                    color: Colors.black,
                                    image: c['coverImageUrl'] != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              _buildCoverUrl(
                                                c['coverImageUrl'] as String,
                                              ),
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: c['coverImageUrl'] == null
                                      ? const Center(
                                          child: Icon(
                                            Icons.menu_book_rounded,
                                            color: Color(0xFF38BDF8),
                                            size: 48,
                                          ),
                                        )
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['title'] ?? 'Untitled course',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        c['description'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              color: (c['isPaid'] == true)
                                                  ? const Color(0xFF4C1D95)
                                                  : const Color(0xFF064E3B),
                                            ),
                                            child: Text(
                                              (c['isPaid'] == true)
                                                  ? 'Paid: Rs. ${c['price'] ?? 0}'
                                                  : 'Free',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (c['category'] != null &&
                                              (c['category'] as String)
                                                  .isNotEmpty)
                                            Text(
                                              c['category'],
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Choose mode',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_modeOnlineAvailable)
                            Theme(
                              data: Theme.of(context).copyWith(
                                unselectedWidgetColor:
                                    const Color(0xFF9CA3AF),
                              ),
                              child: RadioListTile<String>(
                                value: 'online',
                                groupValue: _selectedMode,
                                activeColor: const Color(0xFF38BDF8),
                                tileColor: const Color(0xFF020617),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedMode = v ?? 'online';
                                  });
                                },
                                title: const Text(
                                  'Online (pay & enroll)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          if (_modeOfflineAvailable)
                            Theme(
                              data: Theme.of(context).copyWith(
                                unselectedWidgetColor:
                                    const Color(0xFF9CA3AF),
                              ),
                              child: RadioListTile<String>(
                                value: 'offline',
                                groupValue: _selectedMode,
                                activeColor: const Color(0xFF22C55E),
                                tileColor: const Color(0xFF020617),
                                onChanged: (v) {
                                  setState(() {
                                    _selectedMode = v ?? 'offline';
                                  });
                                },
                                title: const Text(
                                  'Offline (request admission)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          const Text(
                            'Offline details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDarkTextField(
                            controller: _addressController,
                            label: 'Your address',
                          ),
                          const SizedBox(height: 8),
                          _buildDarkTextField(
                            controller: _teacherNameController,
                            label: "Sir's name",
                          ),
                          const SizedBox(height: 8),
                          _buildDarkTextField(
                            controller: _phoneController,
                            label: 'Phone number',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 8),
                          _buildDarkTextField(
                            controller: _messageController,
                            label: 'Message',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _selectedMode == 'online'
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF22C55E),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              onPressed: _selectedMode == 'online'
                                  ? _startOnlinePayment
                                  : _submitting
                                      ? null
                                      : _requestOffline,
                              child: Text(
                                _selectedMode == 'online'
                                    ? 'Pay & enroll online'
                                    : _submitting
                                        ? 'Submitting...'
                                        : 'Request offline admission',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF020617),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF020617),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF374151)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF38BDF8)),
        ),
      ),
    );
  }
}
