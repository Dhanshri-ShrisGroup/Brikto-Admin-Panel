import 'package:brikto_admin_panel/services/developer_service.dart';
import 'package:flutter/material.dart';
class OwnerRequestsPage extends StatefulWidget {
  @override
  _OwnerRequestsPageState createState() => _OwnerRequestsPageState();
}

class _OwnerRequestsPageState extends State<OwnerRequestsPage> {
  final DeveloperService service = DeveloperService();
  List<Map<String, dynamic>> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  void loadRequests() async {
    setState(() => loading = true);
    await service.autoUpdateExpiredOwners(); // optional
    requests = await service.fetchOwnerRequests();
    setState(() => loading = false);
  }

  void handleApproval(int id, bool approve) async {
    final success = await service.handleOwnerApproval(id, approve);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(approve ? "Owner Approved" : "Owner Rejected")),
      );
      loadRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: DataTable(
        columns: [
          DataColumn(label: Text("Name")),
          DataColumn(label: Text("Email")),
          DataColumn(label: Text("Phone")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Actions")),
        ],
        rows: requests.map((owner) {
          return DataRow(cells: [
            DataCell(Text(owner['full_name'] ?? '')),
            DataCell(Text(owner['email'] ?? '')),
            DataCell(Text(owner['phone'] ?? '')),
            DataCell(Text(owner['status'] ?? 'Pending')),
            DataCell(Row(
              children: [
                ElevatedButton(
                  onPressed: () => handleApproval(owner['id'], true),
                  child: Text("Approve"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => handleApproval(owner['id'], false),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text("Reject"),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
