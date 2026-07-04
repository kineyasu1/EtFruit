import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/payment_service.dart';
import 'package:agrimarketmob/l10n/app_localizations.dart';

class PaymentCheckoutView extends ConsumerStatefulWidget {
  const PaymentCheckoutView({
    super.key,
    required this.listingId,
    required this.listingTitle,
    required this.price,
    required this.sellerId,
    required this.sellerName,
  });

  final String listingId;
  final String listingTitle;
  final double price;
  final String sellerId;
  final String sellerName;

  @override
  ConsumerState<PaymentCheckoutView> createState() => _PaymentCheckoutViewState();
}

class _PaymentCheckoutViewState extends ConsumerState<PaymentCheckoutView> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'Telebirr';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.price > 0) {
      _amountController.text = widget.price.toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _initiatePayment() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Enter a valid amount');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final buyer = ref.read(authProvider)!;

    try {
      final result = await PaymentService().initializePayment(
        listingId: widget.listingId,
        listingTitle: widget.listingTitle,
        amount: amount,
        buyerId: buyer.id,
        sellerId: widget.sellerId,
        paymentMethod: _selectedMethod,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        final txId = result['txId'] as String;
        final checkoutUrl = result['checkoutUrl'] as String;
        final isMock = result['isMock'] as bool;

        if (mounted) {
          if (isMock) {
            // Push local Sandbox Simulator view
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChapaSandboxSimulatorView(
                  txId: txId,
                  amount: amount,
                  paymentMethod: _selectedMethod,
                  sellerName: widget.sellerName,
                ),
              ),
            );
          } else {
            // Launch real Chapa browser link
            launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
            Navigator.pop(context);
          }
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to initiate payment. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final methods = [
      {'id': 'Telebirr', 'name': 'Telebirr', 'color': const Color(0xFF0D47A1), 'icon': Icons.account_balance_wallet_rounded},
      {'id': 'CBE Birr', 'name': 'CBE Birr', 'color': const Color(0xFF4A148C), 'icon': Icons.account_balance_rounded},
      {'id': 'HelloCash', 'name': 'HelloCash', 'color': const Color(0xFFE65100), 'icon': Icons.phone_android_rounded},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.confirmPayment),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFF4F6F2),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.listingTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seller: ${widget.sellerName}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),
                    // Amount Input field
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.amountToPay,
                        prefixText: 'ETB ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.paymentMethod,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[900]),
            ),
            const SizedBox(height: 10),
            // Selectable Payment Options list
            Expanded(
              child: ListView.builder(
                itemCount: methods.length,
                itemBuilder: (context, index) {
                  final m = methods[index];
                  final isSelected = _selectedMethod == m['id'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? (m['color'] as Color) : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => setState(() => _selectedMethod = m['id'] as String),
                      leading: Icon(m['icon'] as IconData, color: m['color'] as Color, size: 28),
                      title: Text(
                        m['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle_rounded, color: m['color'] as Color, size: 26)
                          : null,
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n.paySeller,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CHAPA SANDBOX SIMULATOR VIEW (webview replacement for local tests)
// -----------------------------------------------------------------------------
class ChapaSandboxSimulatorView extends StatefulWidget {
  const ChapaSandboxSimulatorView({
    super.key,
    required this.txId,
    required this.amount,
    required this.paymentMethod,
    required this.sellerName,
  });

  final String txId;
  final double amount;
  final String paymentMethod;
  final String sellerName;

  @override
  State<ChapaSandboxSimulatorView> createState() => _ChapaSandboxSimulatorViewState();
}

class _ChapaSandboxSimulatorViewState extends State<ChapaSandboxSimulatorView> {
  bool _isProcessing = false;
  String _simStatus = 'pending'; // 'pending', 'success', 'cancelled'

  void _triggerSuccess() async {
    setState(() {
      _isProcessing = true;
      _simStatus = 'processing';
    });

    // Simulate backend webhook latency
    await Future.delayed(const Duration(seconds: 2));
    await PaymentService().simulatePaymentSuccess(widget.txId);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _simStatus = 'success';
      });
    }
  }

  void _triggerCancel() async {
    setState(() {
      _isProcessing = true;
      _simStatus = 'processing';
    });

    await Future.delayed(const Duration(seconds: 1));
    await PaymentService().simulatePaymentFailure(widget.txId);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _simStatus = 'cancelled';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('Chapa Checkout Gateway', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF5E35B1), // Chapa Purple
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Icon(Icons.payment_rounded, size: 64, color: Colors.purple[800]),
              const SizedBox(height: 8),
              const Text(
                'chapa',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF5E35B1)),
                textAlign: TextAlign.center,
              ),
              const Text(
                'SECURE SANDBOX GATEWAY',
                style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.grey, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Paying: ${widget.sellerName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Via ${widget.paymentMethod}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${widget.amount} ETB',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF5E35B1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ref: ${widget.txId}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (_simStatus == 'processing') ...[
                const Center(child: CircularProgressIndicator(color: Color(0xFF5E35B1))),
                const SizedBox(height: 12),
                const Text('Verifying security signatures...', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              ] else if (_simStatus == 'success') ...[
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                const SizedBox(height: 12),
                const Text('Payment Authorized!', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Return to FarmLink', style: TextStyle(color: Colors.white)),
                ),
              ] else if (_simStatus == 'cancelled') ...[
                const Icon(Icons.cancel_rounded, color: Colors.red, size: 64),
                const SizedBox(height: 12),
                const Text('Payment Cancelled', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Return to FarmLink', style: TextStyle(color: Colors.white)),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _triggerSuccess,
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  label: const Text('Simulate Success (Authorise)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _triggerCancel,
                  icon: const Icon(Icons.close_rounded, color: Colors.red),
                  label: const Text('Simulate Cancel / Decline', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
