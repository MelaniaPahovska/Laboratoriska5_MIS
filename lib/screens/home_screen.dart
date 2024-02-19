import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:laboratoriska3/model/exam.dart';
import 'package:laboratoriska3/resources/firestore_methods.dart';
import 'package:laboratoriska3/screens/calendar_screen.dart';
import 'package:laboratoriska3/screens/exam_map.dart';
import 'package:laboratoriska3/screens/location_picker_screen.dart';
import 'package:laboratoriska3/widgets/exam_widget.dart';
import 'package:latlong2/latlong.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Exam> exams = [];
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreMethods _firestoreMethods = FirestoreMethods();
  String currentUserId = "";
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;

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
                ListTile(
                  title: Text('Избери локација на мапа'),
                  trailing: Icon(Icons.map),
                  onTap: () async {
                    final LatLng? pickedLocation =
                        await Navigator.of(context).push<LatLng>(
                      MaterialPageRoute(
                          builder: (context) => LocationPickerScreen()),
                    );
                    if (pickedLocation != null) {
                      // Update the state with the picked location
                      setState(() {
                        _selectedLatitude = pickedLocation.latitude;
                        _selectedLongitude = pickedLocation.longitude;
                      });
                    }
                  },
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
                    [],
                    // Participants
                    _selectedLatitude,
                    _selectedLongitude,
                  );

                  if (result == "success") {
                    if (exams != []) {
                      _scheduleNotification(exams.last);
                    }
                    setState(() {
                      exams.add(exams.last);
                      _selectedDate = null;
                      _selectedTime = null;
                    });
                    Navigator.of(context).pop();
                  } else {}
                } else {}

                _subjectController.clear();
                fetchExams();
              },
            ),
          ],
        );
      },
    );
  }

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
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = const IOSInitializationSettings();
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
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

  Future<void> _scheduleNotification(Exam exam) async {
    // Convert exam time string to DateTime object
    //DateTime examTime = DateFormat('HH:mm').parse(exam.time);
    DateTime notificationTime = exam.date.subtract(const Duration(
      minutes: 5,
      hours: 1,
    ));

    var androidDetails = const AndroidNotificationDetails(
      'exam_id',
      'Exam Notifications',
      channelDescription: 'Notification channel for exam reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSDetails = IOSNotificationDetails();
    var platformDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);

    await flutterLocalNotificationsPlugin.schedule(
      exam.hashCode,
      'Exam Reminder',
      '${exam.name} is scheduled for ${exam.time}',
      //examTime,
      notificationTime,
      platformDetails,
    );
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
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => CalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.map_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => ExamLocationsMapScreen(
                          exams: exams,
                        )),
              );
            },
          ),
        ],
      ),
      // body: GridView.builder(
      //   padding: EdgeInsets.all(10),
      //   itemCount: exams.length,
      //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      //     crossAxisCount: 2,
      //     childAspectRatio: 3 / 2,
      //     crossAxisSpacing: 10,
      //     mainAxisSpacing: 10,
      //   ),
      //   itemBuilder: (ctx, i) => Card(
      //     color: Colors.white,
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.center,
      //       children: <Widget>[
      //         Text(
      //           exams[i].name,
      //           style:
      //               TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
      //         ),
      //         Text(
      //           "${exams[i].date.day}.${exams[i].date.month}.${exams[i].date.year}, ${exams[i].time}",
      //           style: TextStyle(color: Colors.grey),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        itemCount: exams.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (ctx, i) => ExamTile(exam: exams[i]),
      ),
    );
  }
}
