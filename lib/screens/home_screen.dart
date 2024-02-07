import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:laboratoriska3/model/exam.dart';
import 'package:laboratoriska3/resources/firestore_methods.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Exam> exams = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  String currentUserId = "";

  Future<void> _addExam() async {
    final TextEditingController _subjectController = TextEditingController();
    DateTime? _selectedDate;
    TimeOfDay? _selectedTime;

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2025),
      );
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
        });
      }
    }

    Future<void> _selectTime(BuildContext context) async {
      final TimeOfDay? picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (picked != null && picked != _selectedTime) {
        setState(() {
          _selectedTime = picked;
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Додади нов колоквиум'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(labelText: 'Предмет'),
                ),
                ListTile(
                  title: Text(_selectedDate == null
                      ? 'Избери датум'
                      : 'Датум: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context),
                ),
                ListTile(
                  title: Text(_selectedTime == null
                      ? 'Избери време'
                      : 'Време: ${_selectedTime!.format(context)}'),
                  trailing: Icon(Icons.access_time),
                  onTap: () => _selectTime(context),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Откажи'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Зачувај'),
              onPressed: () async {
                if (_selectedDate != null &&
                    _selectedTime != null &&
                    _subjectController.text.isNotEmpty) {
                  final DateTime examDateTime = DateTime(
                    _selectedDate!.year,
                    _selectedDate!.month,
                    _selectedDate!.day,
                    _selectedTime!.hour,
                    _selectedTime!.minute,
                  );
                  final String result = await _firestoreMethods.uploadExam(
                    _subjectController.text,
                    examDateTime,
                    DateFormat('HH:mm').format(examDateTime),
                    "", // Description
                    [], // Participants
                  );

                  if (result == "success") {
                    Navigator.of(context).pop();
                  } else {}
                } else {}

                _subjectController.clear();
                fetchExams();
                setState(() {
                  _selectedDate = null;
                  _selectedTime = null;
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          currentUserId = user.uid;
        });
        fetchExams();
      }
    });
  }

  void getCurrentUserAndFetchData() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
      fetchExams();
    }
  }

  void fetchExams() {
    _firestore
        .collection('exams')
        .where('uid', isEqualTo: currentUserId)
        .orderBy('date')
        .snapshots()
        .listen((snapshot) {
      print("Fetched ${snapshot.docs.length} exams.");
      setState(() {
        exams = snapshot.docs.map((doc) => Exam.fromSnap(doc)).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Листа на колоквиуми'),
        titleTextStyle:
            TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addExam,
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        itemCount: exams.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (ctx, i) => Card(
          color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                exams[i].name,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              Text(
                "${exams[i].date.day}.${exams[i].date.month}.${exams[i].date.year}, ${exams[i].time}",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
