import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/models/member_model.dart';
import 'package:civiczero/constants/proposal_constants.dart';

/// ActionGate - Centralized permission checking
/// Returns {allowed, reason, requiredRole} for any action
class ActionGateResult {
  final bool allowed;
  final String reason;
  final String? requiredRole;

  ActionGateResult({
    required this.allowed,
    this.reason = '',
    this.requiredRole,
  });
}

class ActionGate {
  /// Check if member can perform action in government
  static ActionGateResult check({
    required GovernmentModel government,
    required MemberModel? member,
    required String actionKey,
  }) {
    // Visitor access
    if (member == null) {
      if (actionKey == ActionKey.view) {
        return ActionGateResult(allowed: true);
      }
      return ActionGateResult(
        allowed: false,
        reason: 'You must join this government',
      );
    }

    // Member is not active
    if (member.status != 'active') {
      return ActionGateResult(
        allowed: false,
        reason: 'Your membership is ${member.status}',
      );
    }

    // Check each role the member has
    for (final role in member.roles) {
      if (!government.enabledRoles.contains(role)) continue;

      final powers = government.rolePowers[role];
      if (powers == null) continue;

      bool hasPermission = false;
      switch (actionKey) {
        case ActionKey.proposeLaw:
          hasPermission = powers['proposeLaws'] == true;
          break;
        case ActionKey.proposeAmendment:
          hasPermission = powers['editDocs'] != 'no' || powers['proposeLaws'] == true;
          break;
        case ActionKey.proposeEvent:
          hasPermission = powers['proposeEvents'] == true;
          break;
        case ActionKey.fork:
          hasPermission = powers['fork'] == true;
          break;
        case ActionKey.initiateSimulation:
          hasPermission = powers['initiateSimulations'] == true;
          break;
        case ActionKey.vote:
          hasPermission = powers['vote'] == true && member.eligibility['voter'] == true;
          break;
        case ActionKey.editDocs:
          hasPermission = powers['editDocs'] != 'no';
          break;
        case ActionKey.view:
          hasPermission = true;
          break;
      }

      if (hasPermission) {
        return ActionGateResult(allowed: true);
      }
    }

    // Find which role has this permission
    for (final role in government.enabledRoles) {
      final powers = government.rolePowers[role];
      if (powers == null) continue;

      bool roleHasPermission = false;
      switch (actionKey) {
        case ActionKey.proposeLaw:
          roleHasPermission = powers['proposeLaws'] == true;
          break;
        case ActionKey.proposeAmendment:
          roleHasPermission = powers['editDocs'] != 'no' || powers['proposeLaws'] == true;
          break;
        case ActionKey.proposeEvent:
          roleHasPermission = powers['proposeEvents'] == true;
          break;
        case ActionKey.fork:
          roleHasPermission = powers['fork'] == true;
          break;
        case ActionKey.initiateSimulation:
          roleHasPermission = powers['initiateSimulations'] == true;
          break;
        case ActionKey.vote:
          roleHasPermission = powers['vote'] == true;
          break;
      }

      if (roleHasPermission) {
        return ActionGateResult(
          allowed: false,
          reason: 'Requires $role role',
          requiredRole: role,
        );
      }
    }

    return ActionGateResult(
      allowed: false,
      reason: 'Not enabled in this government',
    );
  }

  /// Resolve SOP for a proposal type
  static Map<String, dynamic>? resolveSOP(
    GovernmentModel government,
    String proposalType,
  ) {
    return government.lawmakingSOP[proposalType];
  }

  /// Check if proposal type is enabled
  static bool isProposalTypeEnabled(
    GovernmentModel government,
    String proposalType,
  ) {
    return government.proposalTypes.contains(proposalType);
  }
}
