class MatchData {
  final String teamA;
  final String teamB;
  final int overs;
  final int playersPerTeam;
  final String tossWinner;
  final String tossDecision;
  final bool wideGivesRun;
  final bool noBallGivesRun;

  final bool trackPlayers;
  final bool enterNamesNow;
  final List<String> teamAPlayers;
  final List<String> teamBPlayers;

  MatchData({
    required this.teamA,
    required this.teamB,
    required this.overs,
    required this.playersPerTeam,
    required this.tossWinner,
    required this.tossDecision,
    required this.wideGivesRun,
    required this.noBallGivesRun,
    this.trackPlayers = false,
    this.enterNamesNow = false,
    this.teamAPlayers = const [],
    this.teamBPlayers = const [],
  });

  MatchData copyWith({
    String? teamA,
    String? teamB,
    int? overs,
    int? playersPerTeam,
    String? tossWinner,
    String? tossDecision,
    bool? wideGivesRun,
    bool? noBallGivesRun,
    bool? trackPlayers,
    bool? enterNamesNow,
    List<String>? teamAPlayers,
    List<String>? teamBPlayers,
  }) {
    return MatchData(
      teamA: teamA ?? this.teamA,
      teamB: teamB ?? this.teamB,
      overs: overs ?? this.overs,
      playersPerTeam: playersPerTeam ?? this.playersPerTeam,
      tossWinner: tossWinner ?? this.tossWinner,
      tossDecision: tossDecision ?? this.tossDecision,
      wideGivesRun: wideGivesRun ?? this.wideGivesRun,
      noBallGivesRun: noBallGivesRun ?? this.noBallGivesRun,
      trackPlayers: trackPlayers ?? this.trackPlayers,
      enterNamesNow: enterNamesNow ?? this.enterNamesNow,
      teamAPlayers: teamAPlayers ?? this.teamAPlayers,
      teamBPlayers: teamBPlayers ?? this.teamBPlayers,
    );
  }
}
