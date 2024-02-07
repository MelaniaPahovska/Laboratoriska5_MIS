import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  final String name;
  final DateTime date;
  final String time;
  final String uid;
  //final List<String> participants;
  final String examId;
  final String description;
  bool completed;

  Exam({
    required this.name,
    required this.date,
    required this.time,
    required this.uid,
    // required this.participants,
    required this.examId,
    required this.description,
    this.completed = false,
  });

  static Exam fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Exam(
      name: snapshot["name"] ?? '',
      date: (snapshot["date"] as Timestamp).toDate(),
      time: snapshot["time"] ?? '',
      uid: snapshot["uid"] ?? '',
      examId: snapshot["examId"] ?? '',
      description: snapshot["description"] ?? '',
      completed: snapshot["completed"] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        "name": name,
        "date": Timestamp.fromDate(date),
        "time": time,
        "uid": uid,
        //    "participants": participants,
        "examId": examId,
        "description": description,
        "completed": completed,
      };
}
