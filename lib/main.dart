import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;

import 'package:hex/hex.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // static const rpcUrl = 'http://192.168.31.22:7545';
  static const rpcUrl = 'https://sepolia.infura.io/v3/16964016234a4b919484bce13ca4cbe3';

  String _mnemonic = '';
  String _privateKey = '';
  String _address = '';
  String _balance = '';
  BigInt _estimateGas = BigInt.zero;
  String _sendResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _mnemonic,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _mnemonic = bip39.generateMnemonic();
                });
              },
              child: const Text('创建助记词'),
            ),

            Text(_privateKey,),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _mnemonic = 'early absurd oval good wall senior chief tell always leisure split tell';
                  final Uint8List seed = bip39.mnemonicToSeed(_mnemonic);
                  final bip32.BIP32 root = bip32.BIP32.fromSeed(seed);
                  final bip32.BIP32 child1 = root.derivePath("m/44'/60'/0'/0/0");
                  _privateKey = HEX.encode(child1.privateKey!.toList());
                });
              },
              child: const Text('privateKey'),
            ),

            Text(_address,),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final EthPrivateKey ethPrivateKey = EthPrivateKey.fromHex(_privateKey);
                  final EthereumAddress ethereumAddress = ethPrivateKey.address;
                  _address = HEX.encode(ethereumAddress.addressBytes.toList());
                });
              },
              child: const Text('Address'),
            ),

            Text(_balance,),
            ElevatedButton(
              onPressed: () async {
                final client = Web3Client(rpcUrl, Client());
                final clientVersion = await client.getClientVersion();
                final clientChainId = await client.getChainId();
                final clientGasPrice = await client.getGasPrice();
                final clientNetworkId = await client.getNetworkId();
                try {
                  EtherAmount balance = await client.getBalance(EthereumAddress.fromHex(_address));
                  double b = balance.getValueInUnit(EtherUnit.ether);
                  _balance = b.toStringAsFixed(12);
                } catch (e) {
                  _balance = e.toString();
                }
                setState(() {

                });
              },
              child: const Text('Balance'),
            ),

            Text(_estimateGas.toString(),),
            ElevatedButton(
              onPressed: () async {
                final client = Web3Client(rpcUrl, Client());
                final clientVersion = await client.getClientVersion();
                final clientChainId = await client.getChainId();
                final clientGasPrice = await client.getGasPrice();
                final clientNetworkId = await client.getNetworkId();
                _estimateGas = await client.estimateGas(
                  sender: EthereumAddress.fromHex(_address),
                  to: EthereumAddress.fromHex('51538E31946e3D4be6acDC0BBfCE15C7725e525c'),
                  value: EtherAmount.fromInt(EtherUnit.finney, 10),
                );
                setState(() {
                });
              },
              child: const Text('EstimateGas'),
            ),

            Text(_sendResult,),
            ElevatedButton(
              onPressed: () async {
                try {
                  final client = Web3Client(rpcUrl, Client());
                  final Credentials credentials = EthPrivateKey.fromHex(_privateKey);
                  final Transaction transaction = Transaction(
                    to: EthereumAddress.fromHex('51538E31946e3D4be6acDC0BBfCE15C7725e525c'),
                    gasPrice: EtherAmount.inWei(BigInt.parse('20000000000')),
                    maxGas: 100000,
                    value: EtherAmount.fromInt(EtherUnit.finney, 10),
                  );
                  _sendResult = await client.sendTransaction(credentials, transaction, chainId: 1337);
                } catch (e) {
                  _sendResult = e.toString();
                } finally {
                  setState(() {
                  });
                }

              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),

    );
  }
}
