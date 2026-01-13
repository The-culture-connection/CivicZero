import 'package:civiczero/models/government_model.dart';
import 'package:civiczero/models/member_model.dart';

/// Role Power Evaluation Engine
/// SINGLE SOURCE OF TRUTH for "Can user X perform action Y in government Z?"
class RoleService {
  /// Core permission check - returns true if user can perform action
  /// NEVER scatter permission checks in UI - always use this function
  bool canPerform({
    required MemberModel? member,
    required GovernmentModel government,
    required String action,
  }) {
    // Visitor access (not a member)
    if (member == null) {
      return action == 'view' && government.enabledRoles.contains('visitor');
    }

    // Member is suspended/banned
    if (member.status != 'active') {
      return false;
    }

    // Check each role the member has
    for (final role in member.roles) {
      // Skip if role not enabled in this government
      if (!government.enabledRoles.contains(role)) continue;

      final powers = government.rolePowers[role];
      if (powers == null) continue;

      // Map actions to power fields
      switch (action) {
        case 'fork':
          if (powers['fork'] == true) return true;
          break;
        case 'propose_events':
          if (powers['proposeEvents'] == true) return true;
          break;
        case 'propose_laws':
          if (powers['proposeLaws'] == true) return true;
          break;
        case 'vote':
          if (powers['vote'] == true && member.eligibility['voter'] == true) return true;
          break;
        case 'initiate_simulations':
          if (powers['initiateSimulations'] == true) return true;
          break;
        case 'be_elected':
          if (powers['beElected'] == true) return true;
          break;
        case 'edit_docs_draft':
          if (powers['editDocs'] == 'draft' || powers['editDocs'] == 'direct') return true;
          break;
        case 'edit_docs_direct':
          if (powers['editDocs'] == 'direct') return true;
          break;
        case 'view':
          return true; // All members can view
        case 'leave':
          // Prevent last founder from leaving (anti-orphan rule)
          if (member.roles.contains('founder')) {
            // TODO: Check if other founders exist
            return true;
          }
          return true;
        default:
          return false;
      }
    }

    return false;
  }

  /// Check if user can transition to a new role
  bool canTransitionTo({
    required MemberModel member,
    required GovernmentModel government,
    required String targetRole,
  }) {
    // Check if role exists in government
    if (!government.enabledRoles.contains(targetRole)) return false;

    // Already has role
    if (member.roles.contains(targetRole)) return false;

    // Check transition rules
    final transitions = government.roleTransitions;
    
    // If no explicit transition defined, default to automatic for basic roles
    if (!transitions.containsKey(targetRole)) {
      return ['member', 'visitor'].contains(targetRole);
    }

    final method = transitions[targetRole]?['method'] as String?;
    
    switch (method) {
      case 'automatic':
        // Check if meets criteria (implement eligibility logic)
        return true;
      case 'election':
        // Must be elected (checked elsewhere)
        return member.eligibility[targetRole] ?? false;
      case 'appointment':
      case 'invitation':
        // Must be appointed/invited (checked elsewhere)
        return member.eligibility[targetRole] ?? false;
      case 'sortition':
        // Random selection (checked elsewhere)
        return member.eligibility[targetRole] ?? false;
      case 'public_vote':
        // Must have public approval (checked elsewhere)
        return member.eligibility[targetRole] ?? false;
      default:
        return false;
    }
  }

  /// Get display name for role
  String getRoleDisplayName(String role) {
    final names = {
      'visitor': 'Visitor',
      'member': 'Member',
      'contributor': 'Contributor',
      'voter': 'Voter',
      'representative': 'Representative',
      'moderator': 'Moderator',
      'founder': 'Founder',
    };
    return names[role] ?? role;
  }

  /// Get role description
  String getRoleDescription(String role) {
    final descriptions = {
      'visitor': 'Read-only access to public information',
      'member': 'Joined participant in the government',
      'contributor': 'Can write proposals and drafts',
      'voter': 'Eligible to vote on proposals',
      'representative': 'Elected or selected leader',
      'moderator': 'Facilitates discussions and processes',
      'founder': 'Created the government (no permanent authority)',
    };
    return descriptions[role] ?? '';
  }

  /// Calculate role eligibility based on government rules and member data
  Map<String, bool> calculateEligibility({
    required MemberModel member,
    required GovernmentModel government,
  }) {
    final eligibility = <String, bool>{};

    for (final role in government.enabledRoles) {
      // Already has role
      if (member.roles.contains(role)) {
        eligibility[role] = true;
        continue;
      }

      // Check transition method
      final method = government.roleTransitions[role]?['method'] as String?;
      
      switch (method) {
        case 'automatic':
          // Check time, participation, etc. (simplified for now)
          eligibility[role] = true;
          break;
        case 'election':
        case 'appointment':
        case 'invitation':
        case 'sortition':
        case 'public_vote':
          // Must be explicitly granted
          eligibility[role] = false;
          break;
        default:
          eligibility[role] = false;
      }
    }

    return eligibility;
  }
}
