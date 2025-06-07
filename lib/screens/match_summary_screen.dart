import 'package:flutter/material.dart';
import '../models/match_data.dart';

class MatchSummaryScreen extends StatelessWidget {
  final MatchData matchData;
  final int teamAScore;
  final int teamAWickets;
  final int teamAOvers;

  final int teamBScore;
  final int teamBWickets;
  final int teamBOvers;

  final String topBatsman;
  final String bestBowler;

  const MatchSummaryScreen({
    super.key,
    required this.matchData,
    required this.teamAScore,
    required this.teamAWickets,
    required this.teamAOvers,
    required this.teamBScore,
    required this.teamBWickets,
    required this.teamBOvers,
    required this.topBatsman,
    required this.bestBowler,
  });

  @override
  Widget build(BuildContext context) {
    String winner;
    if (teamAScore > teamBScore) {
      winner = '${matchData.teamA} won the match';
    } else if (teamBScore > teamAScore) {
      winner = '${matchData.teamB} won the match';
    } else {
      winner = 'Match Tied';
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        title: const Text("Match Summary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  winner,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                matchScoreTile(matchData.teamA, teamAScore, teamAWickets, teamAOvers),
                const Divider(height: 30),
                matchScoreTile(matchData.teamB, teamBScore, teamBWickets, teamBOvers),
                const SizedBox(height: 30),
                playerStatTile("Top Batsman", topBatsman),
                const SizedBox(height: 12),
                playerStatTile("Best Bowler", bestBowler),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget matchScoreTile(String team, int score, int wickets, int overs) {
    return Column(
      children: [
        Text(
          team,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          "$score/$wickets in $overs overs",
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }

  Widget playerStatTile(String title, String player) {
    return Row(
      children: [
        Text("$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Expanded(
          child: Text(player, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
