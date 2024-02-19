import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:laboratoriska3/model/exam.dart';

class ExamLocationsMapScreen extends StatelessWidget {
  final List<Exam> exams;

  const ExamLocationsMapScreen({Key? key, required this.exams})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Локации за вашите испити'),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(
              41.9981, 21.4254), // Default center location (e.g., Chicago)
          zoom: 12.0, // Default zoom level
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers:
                _buildMarkers(), // Function to build markers for each exam location
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return exams.map((exam) {
      return Marker(
        width: 40.0,
        height: 40.0,
        point:
            LatLng(exam.latitude, exam.longitude), // Exam location coordinates
        child: Icon(
          Icons.location_pin,
          color: Colors.red, // Customize marker color
        ),
      );
    }).toList();
  }
}
