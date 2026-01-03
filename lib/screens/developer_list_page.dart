import 'package:flutter/material.dart';
import '../services/developer_service.dart';
import 'developer_add_page.dart';
import 'developer_edit_page.dart';

class DeveloperListPage extends StatefulWidget {
  @override
  _DeveloperListPageState createState() => _DeveloperListPageState();
}

class _DeveloperListPageState extends State<DeveloperListPage> {
  final service = DeveloperService();
  List<Map<String, dynamic>> developers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await service.autoUpdateExpiredDevelopers();
    developers = await service.fetchDevelopers();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Developers")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => DeveloperAddPage()));
          loadData();
        },
        child: Icon(Icons.add),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : developers.isEmpty
              ? Center(child: Text("No developers found"))
              : ListView.builder(
                  itemCount: developers.length,
                  itemBuilder: (context, i) {
                    final d = developers[i];
                    return Card(
                      child: ListTile(
                        title: Text(d['developer_name'] ?? ''),
                        subtitle: Text("${d['email']} • ${d['status']}"),
                        trailing: Icon(Icons.edit),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DeveloperEditPage(devData: d),
                            ),
                          );
                          loadData();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
