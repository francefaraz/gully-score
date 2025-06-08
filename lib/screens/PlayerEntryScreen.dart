import 'package:flutter/material.dart';
import '../models/match_data.dart';
import 'scoring_screen.dart';

class PlayerEntryScreen extends StatefulWidget {
  final MatchData matchData;

  const PlayerEntryScreen({Key? key, required this.matchData})
      : super(key: key);

  @override
  State<PlayerEntryScreen> createState() => _PlayerEntryScreenState();
}

class _PlayerEntryScreenState extends State<PlayerEntryScreen> {
  final List<TextEditingController> teamAControllers = [TextEditingController()];
  final List<TextEditingController> teamBControllers = [TextEditingController()];

  void _addPlayer(List<TextEditingController> controllers) {
    setState(() {
      controllers.add(TextEditingController());
    });
  }

  void _removePlayer(List<TextEditingController> controllers, int index) {
    setState(() {
      if (controllers.length > 1) {
        controllers.removeAt(index);
      }
    });
  }

  void _startMatch() {
    final teamAPlayers = teamAControllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final teamBPlayers = teamBControllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (teamAPlayers.isEmpty || teamBPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Both teams must have at least 1 player")),
      );
      return;
    }

    widget.matchData.teamAPlayers = teamAPlayers;
    widget.matchData.teamBPlayers = teamBPlayers;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ScoringScreen(matchData: widget.matchData),
      ),
    );
  }

  Widget _buildPlayerFields(String title, List<TextEditingController> controllers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$title Players", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ...List.generate(controllers.length, (index) {
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controllers[index],
                  decoration: InputDecoration(labelText: "Player ${index + 1}"),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _removePlayer(controllers, index),
              )
            ],
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Player"),
            onPressed: () => _addPlayer(controllers),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Players")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildPlayerFields(widget.matchData.teamA, teamAControllers),
            _buildPlayerFields(widget.matchData.teamB, teamBControllers),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startMatch,
              child: const Text("Start Match"),
            ),
          ],
        ),
      ),
    );
  }
}
