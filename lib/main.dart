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
      title: 'Flutter Web3 Balance',
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

  final String _rpcUrl = "https://ethereum-sepolia-rpc.publicnode.com";

  String _balance = '';
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _fetchBalance() async {
    final String address = _addressController.text;
    if (address.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a wallet address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _balance = '';
      _errorMessage = '';
    });

    try {
      final client = Web3Client(_rpcUrl, Client());

      final EthereumAddress walletAddress = EthereumAddress.fromHex(
        address.toLowerCase(),
      );

      final EtherAmount balance = await client.getBalance(walletAddress);

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
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Web3 Balance Fetcher')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                onPressed: _isLoading ? null : _fetchBalance,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Fetch Balance'),
              ),
              const SizedBox(height: 30),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Result:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_balance.isNotEmpty)
                      SelectableText(
                        _balance,
                        style: const TextStyle(
                          fontSize: 22,
                          fontFamily: 'monospace',
                          color: Colors.greenAccent,
                        ),
                      ),
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Note: This app is connected to the Sepolia Testnet. '
                'It will not show mainnet balances.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
