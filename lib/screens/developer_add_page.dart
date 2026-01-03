import 'package:flutter/material.dart';
import '../services/developer_service.dart';

class DeveloperAddPage extends StatefulWidget {
  @override
  _DeveloperAddPageState createState() => _DeveloperAddPageState();
}

class _DeveloperAddPageState extends State<DeveloperAddPage> {
  final service = DeveloperService();

  final name = TextEditingController();
  final company = TextEditingController();
  final email = TextEditingController();
  final mobile = TextEditingController();
  final password = TextEditingController();

  String plan = "Monthly";
  DateTime? startDate;
  DateTime? expiryDate;

  Future pickDate(bool isStart) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2090),
      initialDate: DateTime.now(),
    );

    if (selected != null) {
      setState(() {
        if (isStart) startDate = selected;
        else expiryDate = selected;
      });
    }
  }

  Future save() async {
    if (startDate == null || expiryDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Select dates")));
      return;
    }

    final data = {
      'developer_name': name.text,
      'company_name': company.text,
      'email': email.text,
      'mobile': mobile.text,
      'password_hash': password.text,
      'subscription_plan': plan,
      'subscription_start_date': startDate!.toIso8601String(),
      'subscription_expiry_date': expiryDate!.toIso8601String(),
      'status': "Active",
    };

    final ok = await service.addDeveloper(data);
    if (!ok) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Developer")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: "Developer Name")),
            TextField(controller: company, decoration: InputDecoration(labelText: "Company Name")),
            TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: mobile, decoration: InputDecoration(labelText: "Mobile")),
            TextField(controller: password, decoration: InputDecoration(labelText: "Password Hash")),

            SizedBox(height: 20),
            DropdownButtonFormField(
              value: plan,
              items: ["Monthly", "Yearly", "Custom"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => plan = v!),
              decoration: InputDecoration(labelText: "Subscription Plan"),
            ),

            SizedBox(height: 20),
            ListTile(
              title: Text(startDate == null
                  ? 'Select Start Date'
                  : startDate!.toString().split(" ")[0]),
              trailing: Icon(Icons.calendar_today),
              onTap: () => pickDate(true),
            ),

            ListTile(
              title: Text(expiryDate == null
                  ? 'Select Expiry Date'
                  : expiryDate!.toString().split(" ")[0]),
              trailing: Icon(Icons.calendar_today),
              onTap: () => pickDate(false),
            ),

            SizedBox(height: 25),
            ElevatedButton(
              onPressed: save,
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
