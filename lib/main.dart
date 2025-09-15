import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MemberTransactionApp());
}

class MemberTransactionApp extends StatelessWidget {
  const MemberTransactionApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Member Transactions',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MemberTransactionScreen(),
    );
  }
}

class Member {
  String name;
  List<Transaction> transactions;

  Member({required this.name, List<Transaction>? transactions})
      : transactions = transactions ?? [];

  Map<String, dynamic> toJson() => {
    'name': name,
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  static Member fromJson(Map<String, dynamic> json) => Member(
    name: json['name'],
    transactions: (json['transactions'] as List)
        .map((t) => Transaction.fromJson(t))
        .toList(),
  );
}

class Transaction {
  String description;
  double amount;
  String type; // "from" or "to"

  Transaction({required this.description, required this.amount, required this.type});

  Map<String, dynamic> toJson() => {
    'description': description,
    'amount': amount,
    'type': type,
  };

  static Transaction fromJson(Map<String, dynamic> json) => Transaction(
    description: json['description'],
    amount: json['amount'],
    type: json['type'],
  );
}

class MemberTransactionScreen extends StatefulWidget {
  const MemberTransactionScreen({Key? key}) : super(key: key);

  @override
  _MemberTransactionScreenState createState() =>
      _MemberTransactionScreenState();
}

class _MemberTransactionScreenState extends State<MemberTransactionScreen> {
  final List<Member> members = [];
  Member? selectedMember;
  final TextEditingController memberNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String transactionType = "to"; // Default transaction type

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  // Save members data to SharedPreferences
  Future<void> _saveMembers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String membersJson = jsonEncode(
        members.map((member) => member.toJson()).toList()); // Convert to JSON
    await prefs.setString('members', membersJson);
  }

  // Load members data from SharedPreferences
  Future<void> _loadMembers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? membersJson = prefs.getString('members');
    if (membersJson != null) {
      setState(() {
        final List<dynamic> memberListJson = jsonDecode(membersJson);
        members.clear();
        members.addAll(
            memberListJson.map((m) => Member.fromJson(m)).toList()); // Load data
      });
    }
  }

  void addMember(String name) {
    setState(() {
      members.add(Member(name: name));
      _saveMembers(); // Save after adding member
    });
  }

  void addTransaction(Member member, String description, double amount, String type) {
    setState(() {
      member.transactions.add(Transaction(description: description, amount: amount, type: type));
      _saveMembers(); // Save after adding transaction
    });
  }

  void clearTransactions(Member member) {
    setState(() {
      member.transactions.clear();
      members.remove(member); // Remove member from the list
      selectedMember = null; // Clear the selected member name
      _saveMembers(); // Save after clearing
    });
  }

  void showClearConfirmationDialog() {
    if (selectedMember == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Clear'),
          content: const Text('Are you sure you want to clear all transactions and the member name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close the dialog
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                clearTransactions(selectedMember!);
                Navigator.of(context).pop(); // Close the dialog after clearing
              },
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  double calculateTotal(String type) {
    if (selectedMember == null) return 0.0;
    return selectedMember!.transactions
        .where((transaction) => transaction.type == type)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  @override
  Widget build(BuildContext context) {
    double totalTo = calculateTotal("to");
    double totalFrom = calculateTotal("from");
    double balance = totalFrom - totalTo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: memberNameController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (memberNameController.text.isNotEmpty) {
                      addMember(memberNameController.text);
                      memberNameController.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButton<Member>(
              isExpanded: true,
              value: selectedMember,
              hint: const Text('(Select Member)'),
              items: members.map((member) {
                return DropdownMenuItem<Member>(
                  value: member,
                  child: Text(member.name),
                );
              }).toList(),
              onChanged: (Member? member) {
                setState(() {
                  selectedMember = member;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              isExpanded: true,
              value: transactionType,
              items: const [
                DropdownMenuItem(
                    value: "to",
                    child: Text('(To)', style: TextStyle(color: Colors.red))),
                DropdownMenuItem(
                    value: "from",
                    child: Text('(From)', style: TextStyle(color: Colors.green))),
              ],
              onChanged: (String? value) {
                setState(() {
                  transactionType = value ?? "to";
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                if (descriptionController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  final amount = double.tryParse(amountController.text);
                  if (amount != null && selectedMember != null) {
                    addTransaction(selectedMember!, descriptionController.text, amount, transactionType);
                    descriptionController.clear();
                    amountController.clear();
                  }
                }
              },
              child: const Text('Add Transaction'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('From',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                        ...selectedMember?.transactions
                            .where((t) => t.type == "from")
                            .map((t) => Text('${t.description}  ${t.amount}')) ??
                            [],
                        Text('Σsum= $totalFrom',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('To',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                        ...selectedMember?.transactions
                            .where((t) => t.type == "to")
                            .map((t) => Text('${t.description}  ${t.amount}')) ??
                            [],
                        Text('Σsum= $totalTo',
                            style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.yellow,
              child: Text(
                balance >= 0 ? 'From = $balance' : 'To = ${-balance}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: balance >= 0 ? Colors.green : Colors.red),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: selectedMember != null ? showClearConfirmationDialog : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Clear Transactions', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
