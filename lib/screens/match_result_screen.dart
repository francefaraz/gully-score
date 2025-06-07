import 'package:flutter/material.dart';

class MatchResultScreen extends StatelessWidget {
  final String teamA;
  final String teamB;
  final int teamAScore;
  final int teamAWickets;
  final int teamBScore;
  final int teamBWickets;

  const MatchResultScreen({super.key, 
    required this.teamA,
    required this.teamB,
    required this.teamAScore,
    required this.teamAWickets,
    required this.teamBScore,
    required this.teamBWickets,
  });

  @override
  Widget build(BuildContext context) {
    String winner = "Draw";
    if (teamAScore > teamBScore) {
      winner = "$teamA Won";
    } else if (teamBScore > teamAScore) {
      winner = "$teamB Won";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Match Summary"),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$teamA: $teamAScore/$teamAWickets"),
            SizedBox(height: 8),
            Text("$teamB: $teamBScore/$teamBWickets"),
            SizedBox(height: 24),
            Text("Result: $winner", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48)),
              child: Text("Back to Home"),
            )
          ],
        ),
      ),
    );
  }
}
