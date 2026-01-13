# CivicZero Architecture - UID-Based Authority System

## 🔐 CORE PRINCIPLE

**UID = AUTHORITY, Username = PRESENTATION**

```
✅ DO: Use UIDs for permissions, votes, roles, power
❌ DON'T: Use usernames for authority or enforcement
```

## Why This Matters

Without UID-based authority:
- ❌ Impersonation attacks (someone changes username to match admin)
- ❌ Rename attacks (user changes name to evade accountability)
- ❌ Historical data corruption (votes lose attribution)
- ❌ Permission escalation exploits

With UID-based authority:
- ✅ Immutable identity for power
- ✅ Username changes don't affect permissions
- ✅ Clean audit trails
- ✅ Impersonation impossible

## Data Model Architecture

### 1. Users Collection (Global)

```
users/{uid}
{
  "uid": "UDRzXr8..." // IMMUTABLE - AUTHORITY
  "email": "grace@example.com"
  "username": "grace" // UNIQUE, lowercase for matching
  "usernameDisplay": "Grace" // Original case for display
  "displayName": "Grace Shorter"
  "photoUrl": "https://..."
  "createdAt": timestamp
  "updatedAt": timestamp
}
```

**Rules:**
- Document keyed by UID (not username!)
- Username must be unique (enforced via query check)
- Usernames stored lowercase for consistency
- NEVER store role information here (roles are per-government!)

### 2. Government Membership Subcollection

```
governments/{govId}/members/{uid}
{
  "uid": "UDRzXr8..." // AUTHORITY
  "username": "grace" // DISPLAY (cached for performance)
  "roles": ["founder", "member", "voter", "contributor"]
  "joinedAt": timestamp
  "roleHistory": [
    {
      "role": "member",
      "assignedAt": timestamp,
      "method": "automatic",
      "assignedBy": null
    },
    {
      "role": "founder",
      "assignedAt": timestamp,
      "method": "creator",
      "assignedBy": null
    }
  ],
  "eligibility": {
    "voter": true,
    "representative": false
  },
  "status": "active" // active, suspended, banned
}
```

**Why Subcollection:**
- ✅ One user can have multiple roles simultaneously
- ✅ Roles are contextual to the government
- ✅ Clean audit trail via roleHistory
- ✅ Easy permission checks
- ✅ Scalable queries

**Why UID as Key:**
- ✅ Immutable identity
- ✅ Fast lookups
- ✅ No rename attacks
- ✅ Direct authority resolution

### 3. Government Document (Parent)

```
governments/{govId}
{
  "name": "Democratic City Council"
  "createdBy": "UDRzXr8..." // UID of creator (AUTHORITY)
  "memberCount": 42 // Performance cache only
  // NO memberIds array - truth is in subcollection!
  ...
}
```

**memberCount**: Cache for UI performance only. Truth is in members subcollection.

## Permission Evaluation Engine

### RoleService.canPerform()

**SINGLE SOURCE OF TRUTH** for all permission checks.

```dart
bool canPerform({
  required MemberModel? member, // null if not a member
  required GovernmentModel government,
  required String action, // 'vote', 'propose_laws', etc.
})
```

**How it works:**
1. If member is null → check if visitors can do action
2. Check member status (active/suspended/banned)
3. Loop through member's roles
4. Check if role has power for action
5. Return true if ANY role grants permission

**Usage in UI:**
```dart
// ❌ WRONG - scattered permission checks
if (user.isAdmin) { showButton(); }

// ✅ CORRECT - centralized authority
if (roleService.canPerform(member: member, government: gov, action: 'vote')) {
  showButton();
}
```

## Vote & Action Storage

Always store both UID (authority) and username (display):

```
votes/{voteId}
{
  "governmentId": "abc123"
  "proposalId": "xyz789"
  "voterUid": "UDRzXr8..." // AUTHORITY - enforcement uses this
  "voterUsername": "grace" // DISPLAY - UI shows this
  "choice": "yes"
  "castAt": timestamp
}
```

**Benefits:**
- Votes remain valid if username changes
- UI can show "grace (formerly gshorter)" if needed
- Governance logic trusts UID only

## Role Transitions

Managed via `GovernmentService.assignRole()`:

```dart
await governmentService.assignRole(
  governmentId: govId,
  uid: userUid, // UID = AUTHORITY
  role: 'representative',
  method: 'election',
  assignedBy: currentUserUid, // Who granted (if applicable)
);
```

**Automatic Roles on Join:**
- All new members get: `['member']`
- Founder gets: `['founder', 'member', 'voter', 'contributor']`

**Transition Methods:**
- `automatic` - meets criteria
- `election` - voted in
- `appointment` - assigned by authority
- `sortition` - randomly selected
- `invitation` - invited by member
- `public_vote` - approved by referendum

## Security Rules (Firestore - TODO)

```javascript
// Only the user can read their own user document
match /users/{uid} {
  allow read: if request.auth.uid == uid;
  allow write: if request.auth.uid == uid;
}

// Members subcollection - UID-based access
match /governments/{govId}/members/{uid} {
  allow read: if request.auth != null; // Members can see each other
  allow write: if false; // Only via cloud functions
}

// Governments - public read, controlled write
match /governments/{govId} {
  allow read: if true;
  allow create: if request.auth != null;
  allow update: if isMemberWithPower(govId, request.auth.uid, 'edit_docs_direct');
}
```

## Anti-Patterns to Avoid

### ❌ DON'T DO THIS:
```dart
// Checking username for authority
if (member.username == 'admin') { grantAccess(); }

// Storing only username
government.members = ['grace', 'john']; // NO UIDs!

// Trusting client-side username
vote.by = currentUsername; // Can be faked!
```

### ✅ DO THIS:
```dart
// Checking UID via role system
if (roleService.canPerform(member, gov, 'admin_action')) { grantAccess(); }

// Storing UID with username for display
member = { uid: 'abc123', username: 'grace' }

// Using UID for authority
vote.voterUid = currentUserUid; // Immutable identity
vote.voterUsername = currentUsername; // Display only
```

## Implementation Phases

### ✅ PHASE 1 - Read & Join (COMPLETE)
- Members subcollection created
- UID-based membership
- Auto-assign 'member' role on join
- Visitor read-only access

### 🔄 PHASE 2 - Role Power Resolution (CURRENT)
- canPerform() function implemented
- Gate UI buttons based on permissions
- Need: Enforce permissions server-side

### 📅 PHASE 3 - Founder & Contributor Logic (NEXT)
- Founder has no permanent override
- Contributor transitions via rules
- Role duration enforcement

### 📅 PHASE 4 - Voting Eligibility Layer
- Dynamic voter role assignment
- Eligibility computation
- Prevent voting without role

### 📅 PHASE 5 - Representative & Moderator
- Election assigns representative
- Moderator actions logged
- Strictly procedural powers

## Key Files

- `models/member_model.dart` - Member subcollection schema
- `services/role_service.dart` - Permission evaluation engine
- `services/government_service.dart` - UID-based operations
- `services/auth_service.dart` - Unique username enforcement

## Testing Checklist

- [ ] User can join government (UID recorded, not username)
- [ ] Username change doesn't break permissions
- [ ] Multiple users can't have same username
- [ ] Vote attribution survives username changes
- [ ] Role power checks use UID, not username
- [ ] Historical data shows UID → username resolution
- [ ] Founder has no hardcoded bypass
