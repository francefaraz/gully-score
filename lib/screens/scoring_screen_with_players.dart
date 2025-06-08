import 'package:flutter/material.dart';
import '../models/match_data.dart';
import 'match_summary_screen.dart';

class ScoringScreenWithPlayers extends StatefulWidget {
  final MatchData matchData;
  final bool isSecondInnings;
  final int? firstInningsScore;
  final int? firstInningsWickets;
  final int? firstInningsOvers;

  const ScoringScreenWithPlayers({
    super.key,
    required this.matchData,
    this.isSecondInnings = false,
    this.firstInningsScore,
    this.firstInningsWickets,
    this.firstInningsOvers,
  });

  @override
  State<ScoringScreenWithPlayers> createState() =>
      _ScoringScreenWithPlayersState();
}

class _ScoringScreenWithPlayersState extends State<ScoringScreenWithPlayers> {
  int currentOver = 0;
  int currentBall = 0;
  int totalRuns = 0;
  int totalWickets = 0;

  int strikerIndex = 0;
  int nonStrikerIndex = 1;
  int currentBowlerIndex = 0;

  List<int> batsmanRuns = [];
  List<int> batsmanBalls = [];
  List<int> batsmanFours = [];
  List<int> batsmanSixes = [];
  List<String> overSummary = [];
  List<Map<String, dynamic>> actions = [];

  final TextEditingController _strikeBatsmanController =
      TextEditingController();
  final TextEditingController _nonStrikeBatsmanController =
      TextEditingController();
  final TextEditingController _bowlerNameController = TextEditingController();

  bool _isMatchStarted = false;

  int _wideRuns = 0;
  int _noBallRuns = 0;
  int _byeRuns = 0;
  int _legByeRuns = 0;

  bool _isWide = false;
  bool _isNoBall = false;
  bool _isBye = false;
  bool _isLegBye = false;
  bool _isWicket = false;

  Map<String, Map<String, int>> _bowlerStats = {};

  // New state variables for current batting and bowling teams
  late List<String> _currentBattingTeamPlayers;
  late List<String> _currentBowlingTeamPlayers;
  late String _currentBattingTeamName;
  late String _currentBowlingTeamName;

  @override
  void initState() {
    super.initState();
    batsmanRuns = List.filled(widget.matchData.playersPerTeam, 0);
    batsmanBalls = List.filled(widget.matchData.playersPerTeam, 0);
    batsmanFours = List.filled(widget.matchData.playersPerTeam, 0);
    batsmanSixes = List.filled(widget.matchData.playersPerTeam, 0);

    if (widget.isSecondInnings) {
      _currentBattingTeamPlayers = List.from(widget.matchData.teamBPlayers);
      _currentBowlingTeamPlayers = List.from(widget.matchData.teamAPlayers);
      _currentBattingTeamName = widget.matchData.teamB;
      _currentBowlingTeamName = widget.matchData.teamA;
    } else {
      _currentBattingTeamPlayers = List.from(widget.matchData.teamAPlayers);
      _currentBowlingTeamPlayers = List.from(widget.matchData.teamBPlayers);
      _currentBattingTeamName = widget.matchData.teamA;
      _currentBowlingTeamName = widget.matchData.teamB;
    }

    // Handle initial player setup if names were entered in setup screen
    if (widget.matchData.trackPlayers &&
        widget.matchData.enterNamesNow &&
        _currentBattingTeamPlayers.length >= 2 &&
        _currentBowlingTeamPlayers.isNotEmpty) {
      _isMatchStarted = true;
      strikerIndex = 0;
      nonStrikerIndex = 1;
      currentBowlerIndex = 0;
      _bowlerStats[_currentBowlingTeamPlayers[0]] = {
        'runs': 0,
        'wickets': 0,
        'balls': 0,
      };
    }
  }

  @override
  void dispose() {
    _strikeBatsmanController.dispose();
    _nonStrikeBatsmanController.dispose();
    _bowlerNameController.dispose();
    super.dispose();
  }

  void _addRun(int runs) {
    setState(() {
      totalRuns += runs;
      batsmanRuns[strikerIndex] += runs;
      batsmanBalls[strikerIndex] += 1;
      if (runs == 4) {
        batsmanFours[strikerIndex] += 1;
      } else if (runs == 6) {
        batsmanSixes[strikerIndex] += 1;
      }

      final currentBowlerName =
          _currentBowlingTeamPlayers.length > currentBowlerIndex
          ? _currentBowlingTeamPlayers[currentBowlerIndex]
          : "Unknown Bowler";

      _bowlerStats.update(currentBowlerName, (value) {
        value['runs'] = (value['runs'] ?? 0) + runs;
        value['balls'] = (value['balls'] ?? 0) + 1;
        return value;
      }, ifAbsent: () => {'runs': runs, 'wickets': 0, 'balls': 1});

      overSummary.add(runs.toString());
      actions.add({
        'type': 'run',
        'value': runs,
        'strikerIndex': strikerIndex,
        'nonStrikerIndex': nonStrikerIndex,
        'bowlerName': currentBowlerName,
        'currentOver': currentOver,
        'currentBall': currentBall,
      });

      if (runs % 2 == 1) {
        _swapStrikers();
      }
      _incrementBall();
    });
  }

  void _registerWicket() {
    setState(() {
      totalWickets++;
      batsmanBalls[strikerIndex] += 1;

      final currentBowlerName =
          _currentBowlingTeamPlayers.length > currentBowlerIndex
          ? _currentBowlingTeamPlayers[currentBowlerIndex]
          : "Unknown Bowler";

      _bowlerStats.update(currentBowlerName, (value) {
        value['wickets'] = (value['wickets'] ?? 0) + 1;
        value['balls'] = (value['balls'] ?? 0) + 1;
        return value;
      }, ifAbsent: () => {'runs': 0, 'wickets': 1, 'balls': 1});

      _isWicket = false;
      overSummary.add('W');
      actions.add({
        'type': 'wicket',
        'strikerIndex': strikerIndex,
        'nonStrikerIndex': nonStrikerIndex,
        'bowlerName': currentBowlerName,
        'currentOver': currentOver,
        'currentBall': currentBall,
      });

      _showWicketDialog();
      _incrementBall();

      _checkInningsEnd();
    });
  }

  void _incrementBall() {
    currentBall++;
    if (currentBall == 6) {
      currentBall = 0;
      currentOver++;
      _swapStrikers();
      overSummary.add('|');
      _showBowlerChangeDialog();
    }
    _checkInningsEnd(); // Check if innings should end after ball
  }

  void _swapStrikers() {
    final temp = strikerIndex;
    strikerIndex = nonStrikerIndex;
    nonStrikerIndex = temp;
  }

  void _retireBatsman() {
    setState(() {
      if (totalWickets + 1 < widget.matchData.playersPerTeam) {
        strikerIndex = totalWickets + 1;
      }
    });
  }

  void _endInnings() {
    // This method is now primarily called by _checkInningsEnd based on innings context.
    // No direct navigation from here, it's handled by _checkInningsEnd now.
  }

  // New method to check if innings should end
  void _checkInningsEnd() {
    bool inningsOverByWickets =
        totalWickets >=
        widget.matchData.playersPerTeam - 1; // All but one batsman out
    bool inningsOverByOvers = currentOver >= widget.matchData.overs;
    bool targetReached = false;

    if (widget.isSecondInnings && widget.firstInningsScore != null) {
      targetReached = totalRuns > widget.firstInningsScore!;
    }

    if (inningsOverByWickets || inningsOverByOvers || targetReached) {
      if (!widget.isSecondInnings) {
        // Transition to second innings
        // Create a new MatchData instance with the current player lists
        // This ensures that any players added during the first innings are included
        final updatedMatchData = widget.matchData.copyWith(
          // If Team A was batting first, their players are in _currentBattingTeamPlayers
          // and Team B's players are in _currentBowlingTeamPlayers
          teamAPlayers: widget.matchData.teamA == _currentBattingTeamName
              ? _currentBattingTeamPlayers
              : _currentBowlingTeamPlayers,
          teamBPlayers: widget.matchData.teamB == _currentBowlingTeamName
              ? _currentBowlingTeamPlayers
              : _currentBattingTeamPlayers,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ScoringScreenWithPlayers(
              matchData: updatedMatchData, // Pass the updated MatchData
              isSecondInnings: true, // Mark as second innings
              firstInningsScore: totalRuns, // Pass first innings score
              firstInningsWickets: totalWickets,
              firstInningsOvers: currentOver,
            ),
          ),
        );
      } else {
        // Transition to match summary after second innings
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MatchSummaryScreen(
              matchData: widget.matchData,
              teamAScore: widget.firstInningsScore ?? 0, // First innings score
              teamAWickets: widget.firstInningsWickets ?? 0,
              teamAOvers: widget.firstInningsOvers ?? 0,
              teamBScore: totalRuns, // Second innings score
              teamBWickets: totalWickets,
              teamBOvers: currentOver,
              topBatsman: "", // Implement logic to find top batsman
              bestBowler: "", // Implement logic to find best bowler
            ),
          ),
        );
      }
    }
  }

  void _undoLastAction() {
    if (actions.isEmpty) return;

    final lastAction = actions.removeLast();

    setState(() {
      switch (lastAction['type']) {
        case 'run':
          totalRuns -= (lastAction['value'] as int);
          batsmanRuns[lastAction['strikerIndex']] -=
              (lastAction['value'] as int);
          batsmanBalls[lastAction['strikerIndex']] -= 1;
          if (lastAction['value'] == 4) {
            batsmanFours[lastAction['strikerIndex']] -= 1;
          } else if (lastAction['value'] == 6) {
            batsmanSixes[lastAction['strikerIndex']] -= 1;
          }
          final currentBowlerName =
              widget.matchData.teamBPlayers.length > currentBowlerIndex
              ? widget.matchData.teamBPlayers[currentBowlerIndex]
              : _bowlerNameController.text.isNotEmpty
              ? _bowlerNameController.text
              : "Unknown Bowler";
          _bowlerStats.update(currentBowlerName, (value) {
            value['runs'] = (value['runs'] ?? 0) - (lastAction['value'] as int);
            value['balls'] = (value['balls'] ?? 0) - 1;
            return value;
          }, ifAbsent: () => {'runs': 0, 'wickets': 0, 'balls': 0});

          if ((lastAction['value'] as int) % 2 == 1) {
            _swapStrikers();
          }
          break;
        case 'wicket':
          totalWickets--;
          batsmanBalls[lastAction['strikerIndex']] -= 1;
          final currentBowlerName =
              widget.matchData.teamBPlayers.length > currentBowlerIndex
              ? widget.matchData.teamBPlayers[currentBowlerIndex]
              : _bowlerNameController.text.isNotEmpty
              ? _bowlerNameController.text
              : "Unknown Bowler";
          _bowlerStats.update(currentBowlerName, (value) {
            value['wickets'] = (value['wickets'] ?? 0) - 1;
            value['balls'] = (value['balls'] ?? 0) - 1;
            return value;
          }, ifAbsent: () => {'runs': 0, 'wickets': 0, 'balls': 0});
          break;
        case 'wide':
        case 'noball':
        case 'bye':
        case 'legbye':
          totalRuns -= (lastAction['value'] as int);
          if (lastAction['type'] == 'wide') _wideRuns--;
          if (lastAction['type'] == 'noball') _noBallRuns--;
          if (lastAction['type'] == 'bye') _byeRuns--;
          if (lastAction['type'] == 'legbye') _legByeRuns--;
          if (lastAction['type'] != 'wide' && lastAction['type'] != 'noball') {
            currentBall--;
          }
          if (lastAction['type'] != 'wide' && lastAction['type'] != 'noball') {
            _bowlerStats.update(
              lastAction['bowlerName'],
              (value) {
                value['runs'] =
                    (value['runs'] ?? 0) - (lastAction['value'] as int);
                value['balls'] = (value['balls'] ?? 0) - 1;
                return value;
              },
              ifAbsent: () => {'runs': 0, 'wickets': 0, 'balls': 0},
            );
          }
          break;
      }

      currentBall = lastAction['currentBall'];
      currentOver = lastAction['currentOver'];

      if (overSummary.isNotEmpty) {
        String lastSummaryItem = overSummary.removeLast();
        if (lastSummaryItem == '|' && overSummary.isNotEmpty) {
          overSummary.removeLast();
        }
      }
    });
  }

  void _addExtra(String type) {
    setState(() {
      int value = 0;
      if (type == 'wide') {
        value = widget.matchData.wideGivesRun ? 1 : 0;
        _wideRuns++;
        _isWide = false;
      } else if (type == 'noball') {
        value = widget.matchData.noBallGivesRun ? 1 : 0;
        _noBallRuns++;
        _isNoBall = false;
      } else if (type == 'bye') {
        value = 1;
        _byeRuns++;
        _isBye = false;
      } else if (type == 'legbye') {
        value = 1;
        _legByeRuns++;
        _isLegBye = false;
      }
      totalRuns += value;

      final currentBowlerName =
          widget.matchData.teamBPlayers.length > currentBowlerIndex
          ? widget.matchData.teamBPlayers[currentBowlerIndex]
          : _bowlerNameController.text.isNotEmpty
          ? _bowlerNameController.text
          : "Unknown Bowler";

      if (type != 'wide' && type != 'noball') {
        _bowlerStats.update(currentBowlerName, (val) {
          val['balls'] = (val['balls'] ?? 0) + 1;
          return val;
        }, ifAbsent: () => {'runs': 0, 'wickets': 0, 'balls': 1});
      }
      _bowlerStats.update(currentBowlerName, (val) {
        val['runs'] = (val['runs'] ?? 0) + value;
        return val;
      }, ifAbsent: () => {'runs': value, 'wickets': 0, 'balls': 0});

      overSummary.add(
        type == 'wide'
            ? 'WD'
            : type == 'noball'
            ? 'NB'
            : type == 'bye'
            ? 'B'
            : 'LB',
      );
      actions.add({
        'type': type,
        'value': value,
        'bowlerName': currentBowlerName,
        'currentOver': currentOver,
        'currentBall': currentBall,
      });

      if (type != 'wide' && type != 'noball') {
        _incrementBall();
      }
    });
  }

  Future<void> _showBowlerChangeDialog() async {
    final newBowlerController = TextEditingController();
    String? selectedNewBowler;

    // Use _currentBowlingTeamPlayers instead of widget.matchData.teamBPlayers
    List<String> availableBowlers = List.from(_currentBowlingTeamPlayers);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Change Bowler'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      value: selectedNewBowler,
                      hint: const Text('Select existing bowler or enter new'),
                      items: availableBowlers.map((String bowler) {
                        return DropdownMenuItem<String>(
                          value: bowler,
                          child: Text(bowler),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateInDialog(() {
                          selectedNewBowler = newValue;
                          newBowlerController.text = newValue ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newBowlerController,
                      decoration: const InputDecoration(
                        hintText: "New Bowler Name (if not in list)",
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Add Bowler'),
                  onPressed: () {
                    String bowlerName = newBowlerController.text.trim();
                    if (bowlerName.isNotEmpty) {
                      setState(() {
                        if (!_currentBowlingTeamPlayers.contains(bowlerName)) {
                          _currentBowlingTeamPlayers.add(bowlerName);
                        }
                        currentBowlerIndex = _currentBowlingTeamPlayers.indexOf(
                          bowlerName,
                        );
                        _bowlerStats.putIfAbsent(
                          bowlerName,
                          () => {'runs': 0, 'wickets': 0, 'balls': 0},
                        );
                        currentBall = 0;
                        overSummary.add('|');
                      });
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showWicketDialog() async {
    String? selectedWicketType;
    final newBatsmanController = TextEditingController();
    String? selectedNewBatsman;

    // Create a list of available batsmen (players not yet batted)
    List<String> availableBatsmen = [];
    for (int i = totalWickets; i < widget.matchData.playersPerTeam; i++) {
      if (widget.matchData.teamAPlayers.length > i) {
        availableBatsmen.add(widget.matchData.teamAPlayers[i]);
      } else {
        availableBatsmen.add("New Player ${i + 1}");
      }
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to update dialog state
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Fall of Wicket'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      value: selectedWicketType,
                      hint: const Text('*Select Wicket Type'),
                      items:
                          <String>[
                            'Bowled',
                            'Caught',
                            'LBW',
                            'Run Out',
                            'Stumped',
                            'Hit Wicket',
                            'Obstructing the field',
                            'Retired Hurt',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setStateInDialog(() {
                          selectedWicketType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedNewBatsman,
                      hint: const Text('Select New Batsman or Enter Name'),
                      items: availableBatsmen.map((String batsman) {
                        return DropdownMenuItem<String>(
                          value: batsman,
                          child: Text(batsman),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setStateInDialog(() {
                          selectedNewBatsman = newValue;
                          newBatsmanController.text =
                              newValue ?? ''; // Pre-fill
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newBatsmanController,
                      decoration: const InputDecoration(
                        hintText: "New Batsman Name (if not in list)",
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('No'),
                  onPressed: () {
                    // If user cancels, revert wicket logic (e.g., decrement totalWickets)
                    // This might need more sophisticated undoing if the wicket was already registered
                    Navigator.of(context).pop();
                    // For now, if 'No' is pressed after a wicket was already registered,
                    // we simply dismiss the dialog and don't change batsman.
                  },
                ),
                TextButton(
                  child: const Text('Add Batsman'),
                  onPressed: () {
                    String batsmanName = newBatsmanController.text.trim();
                    if (batsmanName.isNotEmpty) {
                      setState(() {
                        if (!_currentBattingTeamPlayers.contains(batsmanName)) {
                          _currentBattingTeamPlayers.add(batsmanName);
                        }
                        strikerIndex = _currentBattingTeamPlayers.indexOf(
                          batsmanName,
                        );
                        if (nonStrikerIndex == strikerIndex) {
                          int tempNonStrikerIndex = -1;
                          for (
                            int i = 0;
                            i < widget.matchData.playersPerTeam;
                            i++
                          ) {
                            if (i != strikerIndex &&
                                _currentBattingTeamPlayers.length > i) {
                              tempNonStrikerIndex = i;
                              break;
                            }
                          }
                          if (tempNonStrikerIndex != -1) {
                            nonStrikerIndex = tempNonStrikerIndex;
                          } else {}
                        } else {}
                      });
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScoreRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_currentBattingTeamName}: $totalRuns/$totalWickets',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          'Over: $currentOver.${currentBall}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPlayerStats() {
    if (_currentBattingTeamPlayers.length < 2) {
      return const Text(
        "Not enough players available to show stats.",
        style: TextStyle(color: Colors.red),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(0.7),
            4: FlexColumnWidth(0.7),
            5: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.grey.shade400),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: const [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Batsman',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Runs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Balls',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '4s',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '6s',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'SR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            ...[strikerIndex, nonStrikerIndex].map((index) {
              final name = index < _currentBattingTeamPlayers.length
                  ? _currentBattingTeamPlayers[index]
                  : "N/A";
              final runs = batsmanRuns[index];
              final balls = batsmanBalls[index];
              final fours = batsmanFours[index];
              final sixes = batsmanSixes[index];
              final sr = balls > 0
                  ? (runs / balls * 100).toStringAsFixed(1)
                  : '0.0';
              return TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$name${index == strikerIndex ? ' *' : ''}'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$runs'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$balls'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$fours'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$sixes'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(sr),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildOverSummary() {
    // Get the balls for the current over only
    List<String> currentOverBalls = [];
    if (overSummary.isNotEmpty) {
      int lastOverSeparatorIndex = overSummary.lastIndexOf('|');
      if (lastOverSeparatorIndex != -1) {
        currentOverBalls = overSummary.sublist(lastOverSeparatorIndex + 1);
      } else {
        currentOverBalls = List.from(
          overSummary,
        ); // If no over separator yet, it's the first over
      }
    }

    return Wrap(
      spacing: 8,
      children: currentOverBalls.map((e) {
        return Chip(
          label: Text(e),
          backgroundColor: e == 'W'
              ? Colors.red.shade100
              : Colors.blue.shade100,
        );
      }).toList(),
    );
  }

  Widget _buildScoreButtons() {
    return Column(
      children: [
        Wrap(
          spacing: 10,
          children: List.generate(7, (i) {
            return ElevatedButton(
              onPressed: () => _addRun(i),
              child: Text('$i'),
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(), // Make buttons circular
                padding: const EdgeInsets.all(15), // Adjust padding for size
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _registerWicket,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ), // Red button for Wicket
          child: const Text("Wicket"),
        ),
      ],
    );
  }

  Widget _buildScorecardTable() {
    return Column(
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(0.7),
            4: FlexColumnWidth(0.7),
            5: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.grey.shade400),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: const [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Batsman',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Runs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Balls',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '4s',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '6s',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'SR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            // Display current striker and non-striker
            ...[strikerIndex, nonStrikerIndex].map((index) {
              // Ensure index is within bounds of teamAPlayers
              final name = index < _currentBattingTeamPlayers.length
                  ? _currentBattingTeamPlayers[index]
                  : "N/A";
              final runs = batsmanRuns[index];
              final balls = batsmanBalls[index];
              final fours = batsmanFours[index];
              final sixes = batsmanSixes[index];
              final sr = balls > 0
                  ? (runs / balls * 100).toStringAsFixed(1)
                  : '0.0';
              return TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$name${index == strikerIndex ? ' *' : ''}'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$runs'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$balls'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$fours'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('$sixes'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(sr),
                    ),
                  ),
                ],
              );
            }).toList(),
            // Display other batsmen who have batted (optional, for full scorecard)
            // This part would require iterating through all batsmen and checking if they have batted.
            // For now, only showing current batsmen.
          ],
        ),
        const SizedBox(height: 16),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.grey.shade400),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: const [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Bowler',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Over',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Wickets',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Runs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            // Display current bowler stats
            ..._bowlerStats.entries.map((entry) {
              String bowlerName = entry.key;
              Map<String, int> stats = entry.value;
              return TableRow(
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(bowlerName),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        '${stats['balls']! ~/ 6}.${stats['balls']! % 6}',
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('${stats['wickets']}'),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('${stats['runs']}'),
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _swapStrikers,
                child: const Text('Swap'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _retireBatsman,
                child: const Text('Retire'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _endInnings,
                child: const Text('End innings'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text("Wide", style: TextStyle(fontSize: 12)),
                value: _isWide,
                onChanged: (bool? value) {
                  setState(() {
                    _isWide = value!;
                    if (_isWide) _addExtra('wide');
                  });
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text("NoBall", style: TextStyle(fontSize: 12)),
                value: _isNoBall,
                onChanged: (bool? value) {
                  setState(() {
                    _isNoBall = value!;
                    if (_isNoBall) _addExtra('noball');
                  });
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text("Byes", style: TextStyle(fontSize: 12)),
                value: _isBye,
                onChanged: (bool? value) {
                  setState(() {
                    _isBye = value!;
                    if (_isBye) _addExtra('bye');
                  });
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text("LegByes", style: TextStyle(fontSize: 12)),
                value: _isLegBye,
                onChanged: (bool? value) {
                  setState(() {
                    _isLegBye = value!;
                    if (_isLegBye) _addExtra('legbye');
                  });
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text("Wicket", style: TextStyle(fontSize: 12)),
                value: _isWicket,
                onChanged: (bool? value) {
                  setState(() {
                    _isWicket = value!;
                    if (_isWicket) _registerWicket();
                  });
                },
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: _undoLastAction,
                child: const Text('Undo'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBowlerStatsDisplay() {
    final currentBowlerName =
        _currentBowlingTeamPlayers.length > currentBowlerIndex
        ? _currentBowlingTeamPlayers[currentBowlerIndex]
        : _bowlerNameController.text.isNotEmpty
        ? _bowlerNameController.text
        : "Unknown Bowler";
    final bowlerStats =
        _bowlerStats[currentBowlerName] ??
        {'runs': 0, 'wickets': 0, 'balls': 0};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          border: TableBorder.all(color: Colors.grey.shade400),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              children: const [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Bowler',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Over',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Wickets',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Runs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(currentBowlerName),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      '${bowlerStats['balls']! ~/ 6}.${bowlerStats['balls']! % 6}',
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${bowlerStats['wickets']}'),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('${bowlerStats['runs']}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInningsExtra() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'InningsExtra : $_wideRuns WD, $_noBallRuns NB, $_byeRuns B, $_legByeRuns LB',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildInitialPlayerEntry() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Start first innings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          const Text('Strike Batsman', style: TextStyle(fontSize: 18)),
          TextField(
            controller: _strikeBatsmanController,
            decoration: const InputDecoration(
              hintText: 'Enter strike batsman name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Non-Strike Batsman', style: TextStyle(fontSize: 18)),
          TextField(
            controller: _nonStrikeBatsmanController,
            decoration: const InputDecoration(
              hintText: 'Enter non-strike batsman name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Bowler Name', style: TextStyle(fontSize: 18)),
          TextField(
            controller: _bowlerNameController,
            decoration: const InputDecoration(
              hintText: 'Enter bowler name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: _startMatch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade900,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Start Match', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedOversDisplay() {
    List<Widget> overWidgets = [];
    int tempRuns = 0;
    int tempWickets = 0;
    int overNum = 0;
    List<String> currentOverBalls = [];

    for (var i = 0; i < overSummary.length; i++) {
      String ball = overSummary[i];
      if (ball == '|') {
        overWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Over ${overNum + 1}: ${currentOverBalls.join(' ')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: $tempRuns/$tempWickets',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
        overNum++;
        currentOverBalls.clear();
      } else {
        currentOverBalls.add(ball);
        if (ball == 'W') {
          tempWickets++;
        } else {
          tempRuns += int.parse(ball);
        }
      }
    }
    // Add the last incomplete over if any
    if (currentOverBalls.isNotEmpty) {
      overWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Over ${overNum + 1}: ${currentOverBalls.join(' ')}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Total: $tempRuns/$tempWickets',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overs Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...overWidgets,
      ],
    );
  }

  void _startMatch() {
    setState(() {
      _isMatchStarted = true;

      // Only update player lists if names are entered during the match (not in setup)
      if (widget.matchData.trackPlayers && !widget.matchData.enterNamesNow) {
        // Add new players to the current batting and bowling team lists
        if (_strikeBatsmanController.text.isNotEmpty) {
          _currentBattingTeamPlayers.add(_strikeBatsmanController.text.trim());
        }
        if (_nonStrikeBatsmanController.text.isNotEmpty) {
          _currentBattingTeamPlayers.add(
            _nonStrikeBatsmanController.text.trim(),
          );
        }
        if (_bowlerNameController.text.isNotEmpty) {
          _currentBowlingTeamPlayers.add(_bowlerNameController.text.trim());
          _bowlerStats[_bowlerNameController.text.trim()] = {
            'runs': 0,
            'wickets': 0,
            'balls': 0,
          };
        }

        // Set initial batsmen and bowler indices
        strikerIndex = 0;
        nonStrikerIndex = 1;
        currentBowlerIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    if (widget.isSecondInnings && widget.firstInningsScore != null) {
      appBarTitle =
          'Target: ${widget.firstInningsScore! + 1} (${widget.matchData.overs} Overs)';
    } else {
      appBarTitle = 'Total Overs : ${widget.matchData.overs}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Scorecard"),
                    content: SingleChildScrollView(
                      child: _buildScorecardTable(),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text(
              "Scorecard",
              style: TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: _isMatchStarted
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreRow(),
                    const SizedBox(height: 16),
                    _buildPlayerStats(),
                    const SizedBox(height: 16),
                    _buildBowlerStatsDisplay(),
                    const SizedBox(height: 16),
                    const Text(
                      'This Over',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildOverSummary(),
                    const SizedBox(height: 16),
                    _buildControlButtons(),
                    const SizedBox(height: 20),
                    const Text(
                      'Select score to update',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildScoreButtons(),
                    _buildInningsExtra(),
                    const SizedBox(height: 20),
                    Text(
                      'Overs: $currentOver.$currentBall',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 500),
                  ],
                ),
              ),
            )
          : _buildInitialPlayerEntry(),
    );
  }
}
