import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view_model/pdf_bloc.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view_model/pdf_event.dart';
import 'package:pdf_viewer/feature/pdf/presentation/view_model/pdf_state.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

class PdfListPage extends StatefulWidget {
  @override
  State<PdfListPage> createState() => _PdfListPageState();
}

class _PdfListPageState extends State<PdfListPage> {
  late Razorpay _razorpay;
  final Map<String, bool> _downloadingFiles = {};

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadInitialPdfs();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _loadInitialPdfs() {
    context.read<PdfBloc>().add(LoadPdfsEvent());
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("Payment successful: ${response.paymentId}");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Payment successful! Opening PDF...'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    context.read<PdfBloc>().add(LoadPdfsEvent());
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (response.code != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Payment failed: ${response.message ?? 'Unknown error'}'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External wallet selected: ${response.walletName}");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Redirecting to ${response.walletName}...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// FIXED: Using PdfEntity getter methods instead of map access
  void _initiatePdfPurchase(dynamic pdf) {
    final options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag',
      'amount': 10000,
      'name': 'PDF Viewer Pro',
      'description': 'Purchase: ${pdf.name}', // FIX: pdf.name instead of pdf['name']
      'prefill': {
        'contact': '',
        'email': '',
      },
      'theme': {'color': '#007ACC'},
    };
    
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Razorpay error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize payment'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// FIXED: Using PdfEntity getter methods
  Future<void> _openPdfFile(dynamic pdf) async {
    setState(() {
      _downloadingFiles[pdf.name] = true; // FIX: pdf.name instead of pdf['name']
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/${pdf.name}'); // FIX: pdf.name

      if (await file.exists()) {
        await _openLocalPdf(file);
      } else {
        await _downloadAndOpenPdf(pdf, file);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to open PDF: ${e.toString()}');
    } finally {
      setState(() {
        _downloadingFiles.remove(pdf.name); // FIX: pdf.name
      });
    }
  }

  Future<void> _openLocalPdf(File file) async {
    final result = await OpenFile.open(file.path);
    
    if (result.type != ResultType.done) {
      _showErrorSnackBar('Failed to open PDF file');
    }
  }

  /// FIXED: Using PdfEntity getter methods
  Future<void> _downloadAndOpenPdf(dynamic pdf, File file) async {
    try {
      _showDownloadDialog(pdf.name); // FIX: pdf.name
      
      final response = await http.get(Uri.parse(pdf.url)); // FIX: pdf.url instead of pdf['url']
      
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        
        Navigator.of(context, rootNavigator: true).pop();
        await _openLocalPdf(file);
        
        _showSuccessSnackBar('PDF downloaded successfully');
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop();
      throw e;
    }
  }

  void _showDownloadDialog(String fileName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Downloading $fileName...',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Please wait',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildPdfList(),
      floatingActionButton: _buildRefreshButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'PDF Library',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      shadowColor: Colors.black12,
      actions: [
        IconButton(
          icon: Icon(Icons.search, size: 24),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Search feature coming soon!')),
            );
          },
          tooltip: 'Search PDFs',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.filter_list, size: 24),
          onSelected: (value) {
            context.read<PdfBloc>().add(LoadPdfsEvent());
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'all', child: Text('All PDFs')),
            PopupMenuItem(value: 'purchased', child: Text('Purchased')),
            PopupMenuItem(value: 'free', child: Text('Free')),
          ],
        ),
      ],
    );
  }

  Widget _buildPdfList() {
    return BlocBuilder<PdfBloc, PdfState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _buildStateContent(state),
        );
      },
    );
  }

  Widget _buildStateContent(PdfState state) {
    if (state is PdfLoading) {
      return _buildLoadingState();
    } else if (state is PdfError) {
      return _buildErrorState(state);
    } else if (state is PdfLoaded) {
      return _buildPdfListView(state.pdfs);
    } else {
      return _buildInitialState();
    }
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => _buildPdfSkeletonItem(),
    );
  }

  Widget _buildErrorState(PdfError state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.7),
            ),
            SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.read<PdfBloc>().add(LoadPdfsEvent()),
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'No PDFs available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfListView(List<dynamic> pdfs) {
    if (pdfs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        final isDownloading = _downloadingFiles[pdf.name] == true; // FIX: pdf.name
        
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child: _buildPdfListItem(pdf, isDownloading),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey.withOpacity(0.4),
            ),
            SizedBox(height: 24),
            Text(
              'No PDFs Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Check back later for new content',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// FIXED: Using PdfEntity getter methods
  Widget _buildPdfListItem(dynamic pdf, bool isDownloading) {
    final isPurchased = pdf.purchased; // FIX: pdf.purchased instead of pdf['purchased']
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isDownloading ? null : () => _openPdfFile(pdf),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildPdfIcon(isPurchased, isDownloading),
                SizedBox(width: 16),
                Expanded(
                  child: _buildPdfInfo(pdf, isPurchased),
                ),
                _buildActionButtons(pdf, isPurchased, isDownloading),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfIcon(bool isPurchased, bool isDownloading) {
    Color iconColor;
    Widget iconWidget;

    if (isDownloading) {
      iconColor = Colors.blue;
      iconWidget = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      );
    } else if (isPurchased) {
      iconColor = Colors.green;
      iconWidget = Icon(Icons.verified, size: 16, color: Colors.white);
    } else {
      iconColor = Colors.blue;
      iconWidget = Icon(Icons.description, size: 20, color: Colors.white);
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Center(
        child: isDownloading 
            ? iconWidget 
            : Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: iconWidget),
              ),
      ),
    );
  }

  /// FIXED: Using PdfEntity getter methods
  Widget _buildPdfInfo(dynamic pdf, bool isPurchased) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pdf.name ?? 'Untitled PDF', // FIX: pdf.name
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
        Text(
          isPurchased ? 'Purchased • Ready to view' : 'Premium Content • ₹100.00',
          style: TextStyle(
            fontSize: 14,
            color: isPurchased ? Colors.green : Colors.grey[600],
            fontWeight: isPurchased ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        // Remove size if not available in PdfEntity
        // if (pdf.size != null) ...[
        //   SizedBox(height: 2),
        //   Text(
        //     pdf.size,
        //     style: TextStyle(
        //       fontSize: 12,
        //       color: Colors.grey[500],
        //     ),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildActionButtons(dynamic pdf, bool isPurchased, bool isDownloading) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOpenButton(pdf, isDownloading),
        SizedBox(width: 8),
        if (!isPurchased) _buildBuyButton(pdf),
        if (isPurchased) _buildPurchasedBadge(),
      ],
    );
  }

  Widget _buildOpenButton(dynamic pdf, bool isDownloading) {
    return Tooltip(
      message: isDownloading ? 'Downloading...' : 'Open PDF',
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDownloading ? Colors.grey[100] : Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: isDownloading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : Icon(Icons.open_in_new, size: 20),
          color: isDownloading ? Colors.grey : Colors.blue,
          onPressed: isDownloading ? null : () => _openPdfFile(pdf),
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }

  Widget _buildBuyButton(dynamic pdf) {
    return Tooltip(
      message: 'Purchase PDF',
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.shopping_cart, size: 18),
          color: Colors.white,
          onPressed: () => _initiatePdfPurchase(pdf),
          padding: EdgeInsets.all(8),
          constraints: BoxConstraints(minWidth: 40, minHeight: 40),
        ),
      ),
    );
  }

  Widget _buildPurchasedBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 14, color: Colors.green),
          SizedBox(width: 4),
          Text(
            'Owned',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfSkeletonItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return FloatingActionButton(
      onPressed: () {
        context.read<PdfBloc>().add(LoadPdfsEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Refreshing PDF library...'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Icon(Icons.refresh, size: 24),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
      tooltip: 'Refresh PDFs',
    );
  }
}