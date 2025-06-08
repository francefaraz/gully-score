import 'package:flutter/material.dart';
import '../models/match_data.dart';
import 'match_summary_screen.dart';

class ScoringScreen extends StatefulWidget {
  final MatchData matchData;
  final bool isSecondInnings;
  final int? firstInningsScore;
  final int? firstInningsWickets;
  final int? firstInningsBalls;

  const ScoringScreen({
    super.key,
    required this.matchData,
    this.isSecondInnings = false,
    this.firstInningsScore,
    this.firstInningsWickets,
    this.firstInningsBalls,
  });

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen>
    with SingleTickerProviderStateMixin {
  int runs = 0;
  int wickets = 0;
  int balls = 0;

  List<Map<String, dynamic>> actions = [];
  List<Map<String, dynamic>> redoStack = [];
  List<List<String>> overSummary = [[]];
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playAnimation() {
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void addRun(int value) {
    if (isInningsOver()) {
      if (widget.isSecondInnings) {
        endInnings(); // Automatically end innings when target is reached
      }
      return;
    }
    setState(() {
      runs += value;
      balls++;
      actions.add({'type': 'run', 'value': value});
      redoStack.clear();
      overSummary.last.add('$value');
      if (balls % 6 == 0 && !isInningsOver()) overSummary.add([]);
      _playAnimation();

      // Check if target is reached after adding runs
      if (widget.isSecondInnings && isInningsOver()) {
        endInnings();
      }
    });
  }

  void addWicket() {
    if (isInningsOver()) {
      if (widget.isSecondInnings) {
        endInnings(); // Automatically end innings when all wickets are lost
      }
      return;
    }
    setState(() {
      wickets++;
      balls++;
      actions.add({'type': 'wicket'});
      redoStack.clear();
      overSummary.last.add('W');
      if (balls % 6 == 0 && !isInningsOver()) overSummary.add([]);
      _playAnimation();

      // Check if all wickets are lost
      if (widget.isSecondInnings && isInningsOver()) {
        endInnings();
      }
    });
  }

  void addExtra(String type) {
    if (isInningsOver()) {
      if (widget.isSecondInnings) {
        endInnings(); // Automatically end innings when target is reached
      }
      return;
    }
    int value =
        (type == 'wide' && widget.matchData.wideGivesRun) ||
            (type == 'noball' && widget.matchData.noBallGivesRun)
        ? 1
        : 0;
    setState(() {
      runs += value;
      actions.add({'type': type, 'value': value});
      redoStack.clear();
      overSummary.last.add(type == 'wide' ? 'WD' : 'NB');
      _playAnimation();

      // Check if target is reached after adding extra
      if (widget.isSecondInnings && isInningsOver()) {
        endInnings();
      }
    });
  }

  void undoAction() {
    if (actions.isEmpty) return;
    final last = actions.removeLast();
    setState(() {
      switch (last['type']) {
        case 'run':
          runs -= (last['value'] as num).toInt();
          balls--;
          break;
        case 'wicket':
          wickets--;
          balls--;
          break;
        case 'wide':
        case 'noball':
          runs -= (last['value'] as num).toInt();
          break;
      }
      redoStack.add(last);
      if (overSummary.isNotEmpty && overSummary.last.isNotEmpty) {
        overSummary.last.removeLast();
      }
    });
  }

  void redoAction() {
    if (redoStack.isEmpty) return;
    final last = redoStack.removeLast();
    setState(() {
      switch (last['type']) {
        case 'run':
          runs += (last['value'] as num).toInt();
          balls++;
          overSummary.last.add('${last['value']}');
          break;
        case 'wicket':
          wickets++;
          balls++;
          overSummary.last.add('W');
          break;
        case 'wide':
          runs += (last['value'] as num).toInt();
          overSummary.last.add('WD');
          break;
        case 'noball':
          runs += (last['value'] as num).toInt();
          overSummary.last.add('NB');
          break;
      }
      actions.add(last);
      if (balls % 6 == 0 && !isInningsOver()) overSummary.add([]);
    });
  }

  bool isInningsOver() {
    if (widget.isSecondInnings) {
      // Check if target is reached
      int targetScore = (widget.firstInningsScore ?? 0) + 1;
      if (runs >= targetScore) return true;
    }
    return balls >= widget.matchData.overs * 6 || wickets >= 10;
  }

  String get oversDisplay => "${balls ~/ 6}.${balls % 6}";

  String get ballsLeftDisplay {
    if (!widget.isSecondInnings) return "";
    int totalBalls = widget.matchData.overs * 6;
    int remainingBalls = totalBalls - balls;
    return remainingBalls.toString();
  }

  String get requiredRunRate {
    if (!widget.isSecondInnings) return "";
    int totalBalls = widget.matchData.overs * 6;
    int remainingBalls = totalBalls - balls;
    if (remainingBalls <= 0) return "0.00";

    int targetScore = (widget.firstInningsScore ?? 0) + 1;
    int runsNeeded = targetScore - runs;
    if (runsNeeded <= 0) return "0.00";

    double oversLeft = remainingBalls / 6;
    return (runsNeeded / oversLeft).toStringAsFixed(2);
  }

  String get runsNeeded {
    if (!widget.isSecondInnings) return "";
    int targetScore = (widget.firstInningsScore ?? 0) + 1;
    int needed = targetScore - runs;
    return needed > 0 ? needed.toString() : "0";
  }

  void endInnings() {
    if (!widget.isSecondInnings) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'First Innings Complete!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.matchData.teamA} scored:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$runs/$wickets',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($oversDisplay)',
                        style: TextStyle(fontSize: 18, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.matchData.teamB} needs ${runs + 1} runs to win',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScoringScreen(
                        matchData: widget.matchData,
                        isSecondInnings: true,
                        firstInningsScore: runs,
                        firstInningsWickets: wickets,
                        firstInningsBalls: balls,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Start Second Innings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Show match result dialog before going to summary
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          String result;
          if (runs > (widget.firstInningsScore ?? 0)) {
            result = '${widget.matchData.teamB} won by ${10 - wickets} wickets';
          } else if (runs < (widget.firstInningsScore ?? 0)) {
            result =
                '${widget.matchData.teamA} won by ${(widget.firstInningsScore ?? 0) - runs} runs';
          } else {
            result = 'Match tied!';
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Match Complete!',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    result,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.matchData.teamA}: ${widget.firstInningsScore ?? 0}/${widget.firstInningsWickets ?? 0}',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${widget.matchData.teamB}: $runs/$wickets',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchSummaryScreen(
                        matchData: widget.matchData,
                        teamAScore: widget.firstInningsScore ?? 0,
                        teamAWickets: widget.firstInningsWickets ?? 0,
                        teamAOvers: (widget.firstInningsBalls ?? 0) ~/ 6,
                        teamBScore: runs,
                        teamBWickets: wickets,
                        teamBOvers: balls ~/ 6,
                        topBatsman: "To be added",
                        bestBowler: "To be added",
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View Match Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine batting team based on toss winner and decision
    String battingTeam;
    if (!widget.isSecondInnings) {
      // First innings: If toss winner chose to bat, they bat first
      if (widget.matchData.tossWinner == widget.matchData.teamA) {
        battingTeam = widget.matchData.tossDecision == 'Bat'
            ? widget.matchData.teamA
            : widget.matchData.teamB;
      } else {
        battingTeam = widget.matchData.tossDecision == 'Bat'
            ? widget.matchData.teamB
            : widget.matchData.teamA;
      }
    } else {
      // Second innings: The other team bats
      battingTeam = widget.matchData.tossWinner == widget.matchData.teamA
          ? (widget.matchData.tossDecision == 'Bat'
                ? widget.matchData.teamB
                : widget.matchData.teamA)
          : (widget.matchData.tossDecision == 'Bat'
                ? widget.matchData.teamA
                : widget.matchData.teamB);
    }

    int targetScore = widget.isSecondInnings
        ? (widget.firstInningsScore ?? 0) + 1
        : 0;
    int totalBalls = widget.matchData.overs * 6;
    int remainingBalls = totalBalls - balls;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        elevation: 0,
        title: Column(
          children: [
            Text(
              "${widget.matchData.teamA} vs ${widget.matchData.teamB}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              "${widget.matchData.overs} Overs Match",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: undoAction,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: redoAction,
            tooltip: 'Redo',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue[900]!, Colors.blue[800]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue[900]!.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (!widget.isSecondInnings) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.matchData.tossWinner} won toss & chose to ${widget.matchData.tossDecision.toLowerCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            battingTeam,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (!widget.isSecondInnings)
                            Text(
                              '${widget.isSecondInnings ? "Chasing" : "Batting"} First',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Text(
                          "$runs/$wickets",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatChip(oversDisplay, "Overs"),
                    const SizedBox(width: 20),
                    _buildStatChip(
                      (runs / (balls / 6 + 0.0001)).toStringAsFixed(2),
                      "Run Rate",
                    ),
                    if (widget.isSecondInnings) ...[
                      const SizedBox(width: 20),
                      _buildStatChip(targetScore.toString(), "Target"),
                    ],
                  ],
                ),
                if (widget.isSecondInnings) ...[
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip(runsNeeded, "Need"),
                      const SizedBox(width: 20),
                      _buildStatChip(ballsLeftDisplay, "Balls Left"),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (var run in [0, 1, 2, 3, 4])
                              _buildScoreButton(
                                '$run',
                                () => addRun(run),
                                run == 4 ? Colors.green : Colors.blue,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildScoreButton(
                              '6',
                              () => addRun(6),
                              Colors.orange,
                            ),
                            _buildScoreButton(
                              'NB',
                              () => addExtra('noball'),
                              Colors.amber,
                            ),
                            _buildScoreButton(
                              'WD',
                              () => addExtra('wide'),
                              Colors.purple,
                            ),
                            _buildScoreButton('W', addWicket, Colors.red),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: overSummary.length,
                      itemBuilder: (_, index) {
                        final over = overSummary[index];
                        final totalRuns = over
                            .where((e) => e != 'W')
                            .map((e) {
                              if (e == 'WD' || e == 'NB') return 1;
                              return int.tryParse(e) ?? 0;
                            })
                            .fold(0, (a, b) => a + b);
                        final wkts = over.where((e) => e == 'W').length;

                        return Card(
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Colors.white, Colors.grey[50]!],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[900]!.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          "Over ${index + 1}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.blue[900],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue[900]!.withOpacity(
                                            0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          "$totalRuns/$wkts",
                                          style: TextStyle(
                                            color: Colors.blue[900],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: over.map((e) {
                                      Color ballColor = Colors.grey;
                                      if (e == '4') ballColor = Colors.green;
                                      if (e == '6') ballColor = Colors.orange;
                                      if (e == 'W') ballColor = Colors.red;
                                      if (e == 'WD') ballColor = Colors.purple;
                                      if (e == 'NB') ballColor = Colors.amber;

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: ballColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: ballColor.withOpacity(0.3),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: ballColor.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          e,
                                          style: TextStyle(
                                            color: ballColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: endInnings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  widget.isSecondInnings ? "Show Summary" : "End Innings",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreButton(String label, VoidCallback onPressed, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
