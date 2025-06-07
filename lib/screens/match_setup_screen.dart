import 'package:flutter/material.dart';
import '../models/match_data.dart';
import 'scoring_screen.dart';

class MatchSetupScreen extends StatefulWidget {
  const MatchSetupScreen({super.key});

  @override
  State<MatchSetupScreen> createState() => _MatchSetupScreenState();
}

class _MatchSetupScreenState extends State<MatchSetupScreen> {
  final teamAController = TextEditingController();
  final teamBController = TextEditingController();
  final oversController = TextEditingController(text: '5');
  final playersController = TextEditingController(text: '6');

  String tossWinner = 'Team A';
  String tossDecision = 'Bat';

  bool wideGivesRun = true;
  bool noBallGivesRun = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Team A Name", teamAController),
            const SizedBox(height: 16),
            _buildTextField("Team B Name", teamBController),
            const SizedBox(height: 16),
            _buildTextField("Number of Overs", oversController, inputType: TextInputType.number),
            const SizedBox(height: 16),
            _buildTextField("Players per Team", playersController, inputType: TextInputType.number),
            const SizedBox(height: 24),
            _buildSection("Toss Winner", [
              _dropdown(['Team A', 'Team B'], tossWinner, (String? val) {
                if (val != null) setState(() => tossWinner = val);
              }),
            ]),
            const SizedBox(height: 16),
            _buildSection("Elected To", [
              _choiceToggle(['Bat', 'Bowl'], tossDecision, (val) {
                setState(() => tossDecision = val);
              }),
            ]),
            const SizedBox(height: 24),
            _buildSwitch("Wide Ball Run Allowed?", wideGivesRun, (val) {
              setState(() => wideGivesRun = val);
            }),
            _buildSwitch("No Ball Run Allowed?", noBallGivesRun, (val) {
              setState(() => noBallGivesRun = val);
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _startMatch,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text("Start Match", style: TextStyle(fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: children),
      ],
    );
  }

  Widget _dropdown(List<String> items, String selected, ValueChanged<String?> onChanged) {
    return DropdownButton<String>(
      value: selected,
      onChanged: onChanged,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    );
  }

  Widget _choiceToggle(List<String> items, String selected, ValueChanged<String> onChanged) {
    return Wrap(
      spacing: 12,
      children: items.map((item) {
        final isSelected = item == selected;
        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (_) => onChanged(item),
          selectedColor: Colors.blue.shade900,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        );
      }).toList(),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.deepPurple,
    );
  }

  void _startMatch() {
    final teamA = teamAController.text.trim();
    final teamB = teamBController.text.trim();
    final overs = int.tryParse(oversController.text.trim()) ?? 0;
    final players = int.tryParse(playersController.text.trim()) ?? 0;

    if (teamA.isEmpty || teamB.isEmpty || overs < 1 || players < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid team names, overs, and players")),
      );
      return;
    }

    final matchData = MatchData(
      teamA: teamA,
      teamB: teamB,
      overs: overs,
      playersPerTeam: players,
      tossWinner: tossWinner == "Team A" ? teamA : teamB,
      tossDecision: tossDecision,
      wideGivesRun: wideGivesRun,
      noBallGivesRun: noBallGivesRun,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScoringScreen(matchData: matchData),
      ),
    );
  }
}
