/// Centralized constants for proposal system
class ProposalStatus {
  static const String draft = 'draft';
  static const String submitted = 'submitted';
  static const String debating = 'debating';
  static const String voting = 'voting';
  static const String passed = 'passed';
  static const String rejected = 'rejected';
  static const String executed = 'executed';

  static const List<String> activeStatuses = [submitted, debating, voting];
  static const List<String> pendingExecutionStatuses = [passed];
  static const List<String> completedStatuses = [executed, rejected];

  static String getDisplayName(String status) {
    switch (status) {
      case draft:
        return 'Draft';
      case submitted:
        return 'Submitted';
      case debating:
        return 'Debating';
      case voting:
        return 'Voting';
      case passed:
        return 'Passed';
      case rejected:
        return 'Rejected';
      case executed:
        return 'Executed';
      default:
        return status;
    }
  }

  static String getNextStep(String status) {
    switch (status) {
      case submitted:
        return 'Awaiting debate or vote';
      case debating:
        return 'Debate in progress';
      case voting:
        return 'Vote open';
      case passed:
        return 'Execution pending';
      case executed:
        return 'Changes applied';
      case rejected:
        return 'Rejected by vote';
      default:
        return '';
    }
  }
}

class ProposalType {
  static const String newLaw = 'new_law';
  static const String amendment = 'amendment';
  static const String repeal = 'repeal';
  static const String governanceChange = 'governance_change';
  static const String event = 'event';
  static const String fork = 'fork';

  static const List<String> all = [
    newLaw,
    amendment,
    repeal,
    governanceChange,
    event,
    fork,
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case newLaw:
        return 'New Law';
      case amendment:
        return 'Amendment';
      case repeal:
        return 'Repeal';
      case governanceChange:
        return 'Governance Change';
      case event:
        return 'Event';
      case fork:
        return 'Fork';
      default:
        return type;
    }
  }

  static bool isConstitutional(String type) {
    return type == governanceChange;
  }
}

class ActionKey {
  static const String proposeAmendment = 'propose_amendment';
  static const String proposeLaw = 'propose_laws';
  static const String proposeEvent = 'propose_events';
  static const String fork = 'fork';
  static const String initiateSimulation = 'initiate_simulations';
  static const String vote = 'vote';
  static const String editDocs = 'edit_docs';
  static const String view = 'view';
}
