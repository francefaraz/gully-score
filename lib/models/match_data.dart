class MatchData {
  final String teamA;
  final String teamB;
  final int overs;
  final int playersPerTeam;
  final String tossWinner;
  final String tossDecision;
  final bool wideGivesRun;
  final bool noBallGivesRun;

  MatchData({
    required this.teamA,
    required this.teamB,
    required this.overs,
    required this.playersPerTeam,
    required this.tossWinner,
    required this.tossDecision,
    required this.wideGivesRun,
    required this.noBallGivesRun,
  });
}
