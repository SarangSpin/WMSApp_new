import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:wms_new/login.dart';
import 'package:wms_new/managerEvent.dart';
import 'dart:developer';
import 'dart:convert';

// ignore: must_be_immutable
class Manager extends StatefulWidget {
  var token = "";
  var manager;
  
  Manager({super.key, required this.token, required this.manager});

  @override
  State<Manager> createState() => _ManagerState();
}

class _ManagerState extends State<Manager> with TickerProviderStateMixin {
  Future<void> _showDialog({String type = 'Alert', String message = 'Success'}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(type),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  var mainData;
  late TabController _controller;
  List<dynamic> jsonResponse = [];

  @override
  void initState() {
    super.initState();
    initSharedPref();
    _controller = TabController(length: 2, vsync: this);
  }

  void initSharedPref() async {
    mainData = await SharedPreferences.getInstance();
  }

  var response;
  Future<List<dynamic>> managerDash() async {
    var managerResponse = jsonDecode(widget.manager);
    String url = 'http://153.92.5.199:5000/managerDash?osm=${managerResponse['employee_id']}';

    response = await http.get(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
    );

    jsonResponse = jsonDecode(response.body)['data'];
    log("${widget.manager}");
    log(managerResponse['employee_id']);
    return jsonResponse;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Manager: ${jsonDecode(widget.manager)['first_name']} ${jsonDecode(widget.manager)['last_name']}',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 233, 115, 79),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false,
            ),
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(child: Text("Assigned", style: TextStyle(color: Colors.white),),),
            Tab(child: Text("Completed", style: TextStyle(color: Colors.white),)),
          ],
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: managerDash(),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return TabBarView(
                controller: _controller,
                children: [
                  _buildAssignmentList(snapshot.data, 'assigned', 'No Pending Assignments'),
                  _buildAssignmentList(snapshot.data, 'completed', 'No Completed Assignments'),
                ],
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildAssignmentList(List<dynamic>? data, String status, String emptyMessage) {
    if (data == null || data.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      );
    }

    var filteredData = data.where((item) => item['status'] == status).toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 5,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              title: Text(
                'Event: ${filteredData[index]['event_']}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              subtitle: Text(
                'Population: ${filteredData[index]['population']}',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              trailing: Text(
                'Deadline: ${filteredData[index]['start_date'].toString().substring(0, 10)}',
                style: TextStyle(
                  color: status == 'assigned' ? Colors.red : Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManagerEvent(event: filteredData[index]),
                ),
              ),
              tileColor: status == 'assigned' ? Colors.orange[50] : Colors.lightGreen[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      },
    );
  }
}
