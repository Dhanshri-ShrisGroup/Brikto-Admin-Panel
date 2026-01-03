import 'package:flutter/material.dart';
import '../services/developer_service.dart';

class DeveloperEditPage extends StatefulWidget {
  final Map<String, dynamic> devData;

  DeveloperEditPage({required this.devData});

  @override
  _DeveloperEditPageState createState() => _DeveloperEditPageState();
}

class _DeveloperEditPageState extends State<DeveloperEditPage> {
  final service = DeveloperService();

  late TextEditingController name;
  late TextEditingController company;
  late TextEditingController email;
  late TextEditingController mobile;

  String plan = "Monthly";
  String status = "Active";
  DateTime? startDate;
  DateTime? expiryDate;

  @override
  void initState() {
    super.initState();
    final d = widget.devData;

    name = TextEditingController(text: d['developer_name'] ?? '');
    company = TextEditingController(text: d['company_name'] ?? '');
    email = TextEditingController(text: d['email'] ?? '');
    mobile = TextEditingController(text: d['mobile'] ?? '');

    plan = d['subscription_plan'] ?? "Monthly";
    status = d['status'] ?? "Active";

    startDate = d['subscription_start_date'] != null
        ? DateTime.parse(d['subscription_start_date'])
        : null;

    expiryDate = d['subscription_expiry_date'] != null
        ? DateTime.parse(d['subscription_expiry_date'])
        : null;
  }

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
    final data = {
      'developer_name': name.text,
      'company_name': company.text,
      'email': email.text,
      'mobile': mobile.text,
      'subscription_plan': plan,
      'status': status,
      'subscription_start_date': startDate?.toIso8601String(),
      'subscription_expiry_date': expiryDate?.toIso8601String(),
    };

    await service.updateDeveloper(widget.devData['id'], data);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Developer")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: name, decoration: InputDecoration(labelText: "Developer Name")),
            TextField(controller: company, decoration: InputDecoration(labelText: "Company Name")),
            TextField(controller: email, decoration: InputDecoration(labelText: "Email")),
            TextField(controller: mobile, decoration: InputDecoration(labelText: "Mobile")),

            SizedBox(height: 20),
            DropdownButtonFormField(
              value: plan,
              items: ["Monthly", "Yearly", "Custom"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => plan = v!),
              decoration: InputDecoration(labelText: "Subscription Plan"),
            ),

            DropdownButtonFormField(
              value: status,
              items: ["Active", "Inactive", "Expired", "Suspended"]
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => status = v!),
              decoration: InputDecoration(labelText: "Status"),
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
              child: Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
