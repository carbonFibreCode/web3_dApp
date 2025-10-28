import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Web3 Wallet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const BalanceFetcherPage(),
    );
  }
}

class BalanceFetcherPage extends StatefulWidget {
  const BalanceFetcherPage({super.key});

  @override
  State<BalanceFetcherPage> createState() => _BalanceFetcherPageState();
}

class _BalanceFetcherPageState extends State<BalanceFetcherPage> {
  final TextEditingController _addressController = TextEditingController();

  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _recipientAddressController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  // -------------------------------------

  final String _rpcUrl = "https://ethereum-sepolia-rpc.publicnode.com";
  late Web3Client _client;

  String _balance = '';
  bool _isFetchingBalance = false;
  String _errorMessage = '';

  bool _isSending = false;
  String _statusMessage = '';
  // ----------------------------------------

  @override
  void initState() {
    super.initState();
    _client = Web3Client(_rpcUrl, Client());
  }

  Future<void> _fetchBalance() async {
    final String address = _addressController.text;
    if (address.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a wallet address';
      });
      return;
    }

    setState(() {
      _isFetchingBalance = true;
      _balance = '';
      _errorMessage = '';
      _statusMessage = '';
    });

    try {
      final EthereumAddress walletAddress = EthereumAddress.fromHex(
        address.toLowerCase(),
      );

      final EtherAmount balance = await _client.getBalance(walletAddress);

      final String balanceInEther = balance
          .getValueInUnit(EtherUnit.ether)
          .toString();

      setState(() {
        _balance = '$balanceInEther ETH';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isFetchingBalance = false;
      });
    }
  }

  Future<void> _sendTransaction() async {
    final String privateKey = _privateKeyController.text.trim();
    final String recipientAddress = _recipientAddressController.text.trim();
    final String amount = _amountController.text.trim();

    if (privateKey.isEmpty || recipientAddress.isEmpty || amount.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all send fields';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = '';
      _statusMessage = '';
    });

    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      final senderAddress = await credentials.extractAddress();

      final EthereumAddress toAddress = EthereumAddress.fromHex(
        recipientAddress.toLowerCase(),
      );

      final EtherAmount amountToSend = EtherAmount.fromUnitAndValue(
        EtherUnit.ether,
        amount,
      );

      final String txHash = await _client.sendTransaction(
        credentials,
        Transaction(to: toAddress, value: amountToSend),
        chainId: 11155111,
      );

      setState(() {
        _statusMessage =
            'Transaction sent! Waiting for confirmation...\nHash: $txHash';
      });

      TransactionReceipt? receipt;
      const Duration pollInterval = Duration(seconds: 3);
      const int maxRetries = 40;
      int retries = 0;

      while (receipt == null && retries < maxRetries) {
        try {
          receipt = await _client.getTransactionReceipt(txHash);
        } catch (e) {
          print('Error polling for receipt: $e');
        }

        if (receipt == null) {
          await Future.delayed(pollInterval);
          retries++;
        }
      }

      if (receipt == null) {
        setState(() {
          _isSending = false;
          _errorMessage =
              'Transaction sent, but polling timed out. Check Etherscan for status.\nHash: $txHash';
        });
        return;
      }

      if (receipt.status == true) {
        setState(() {
          _isSending = false;
          _statusMessage =
              'Success! Transaction confirmed in block ${receipt?.blockNumber.toString()}.';
        });

        _addressController.text = senderAddress.hex;
        _fetchBalance();
      } else {
        setState(() {
          _isSending = false;
          _errorMessage =
              'Transaction failed. Check ED:\Documents\Internship 2024\Canvas-Gemini\gemini-canvas-prod-cli\src\test\goldens\etherscan for details.\nHash: $txHash';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _privateKeyController.dispose();
    _recipientAddressController.dispose();
    _amountController.dispose();
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Web3 Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                title: '1. Fetch Balance',
                children: [
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Wallet Address',
                      hintText: '0x...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isFetchingBalance ? null : _fetchBalance,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: _isFetchingBalance
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Fetch Balance'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildCard(
                title: '2. Send Testnet ETH',
                children: [
                  const Text(
                    'Use a SEPOLIA TESTNET private key. NEVER a real key.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.orangeAccent),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _privateKeyController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Your Private Key (Testnet)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _recipientAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient Address',
                      hintText: '0x...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount (e.g., 0.01)',
                      hintText: '0.01',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Transaction'),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // --- Section 3: Results Area ---
              _buildCard(
                title: 'Results:',
                children: [
                  // Balance Result
                  if (_balance.isNotEmpty)
                    Text(
                      'Balance: $_balance',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                      ),
                    ),

                  if (_statusMessage.isNotEmpty)
                    SelectableText(
                      _statusMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.lightBlueAccent,
                      ),
                    ),

                  if (_errorMessage.isNotEmpty)
                    SelectableText(
                      _errorMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.red),
                    ),

                  if (_balance.isEmpty &&
                      _statusMessage.isEmpty &&
                      _errorMessage.isEmpty)
                    const Text(
                      'Results will appear here...',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withOpacity(0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
