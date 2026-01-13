# Governance Proposal System

## 🏛️ Core Principle: Self-Governance

**Any change to governance structure must go through the governance process itself.**

This prevents:
- ❌ Power grabs via simple edits
- ❌ Invisible constitution changes
- ❌ Founder permanent authority
- ❌ Role manipulation without consent

## 📋 Governed Objects (Require Proposals)

Changes to these fields MUST go through `governance_change` proposals:

### Constitutional Fields:
- `enabledRoles` - Which roles exist
- `rolePowers` - What each role can do
- `roleTransitions` - How users gain roles
- `roleDurations` - How long roles last
- `lawmakingSOP` - Proposal procedures
- `forkRules` - Exit procedures
- `votingBody` - Who can vote
- `branches` - Government structure
- `checksAndBalances` - Branch limitations

### Standard Proposal Types:
- `new_law` - Regular legislation (simple majority)
- `amendment` - Modify existing law
- `repeal` - Remove a law
- `governance_change` - **CONSTITUTIONAL** (requires supermajority!)
- `emergency` - Fast-track for crises

## 🔐 Governance Change SOP (Default)

```json
{
  "debateRequired": "always",
  "debateFormat": "open_discussion",
  "voteRequired": true,
  "votingBody": "eligible_voters",
  "threshold": "supermajority_66",  // 2/3 majority required!
  "quorum": 0.2  // 20% participation minimum
}
```

**Why Higher Threshold?**
- Role changes = power shifts
- Must have broad consensus
- Prevents hostile takeovers
- Preserves institutional trust

## 📊 Proposal Data Model

### Collection Structure:
```
governments/{govId}/proposals/{proposalId}
{
  // Identity (UID-based!)
  "id": "abc123"
  "governmentId": "xyz789"
  "createdBy": "UDRzXr8..." // UID = AUTHORITY
  "creatorUsername": "grace" // DISPLAY only
  
  // Type & Category
  "type": "governance_change"
  "category": "roles_and_permissions"
  
  // Status Lifecycle
  "status": "submitted" // draft → submitted → debating → voting → passed/rejected → executed
  
  // Content
  "title": "Allow Members to Propose Laws"
  "rationale": "We want broader participation..."
  
  // Changes (atomic operations)
  "changes": [
    {
      "op": "set",           // set, remove, add
      "path": "rolePowers.member.proposeLaws",
      "value": true
    }
  ],
  
  // SOP Snapshot (frozen at creation!)
  "sopSnapshot": {
    "debateRequired": "always",
    "threshold": "supermajority_66",
    ...
  },
  
  // Voting
  "votesFor": 24,
  "votesAgainst": 3,
  "votesAbstain": 2,
  "votingStarted": timestamp,
  "votingEnds": timestamp,
  
  // Execution
  "executedAt": timestamp,
  "executedBy": "uid"
}
```

### Votes Subcollection:
```
governments/{govId}/proposals/{proposalId}/votes/{uid}
{
  "voterUid": "UDRzXr8..." // AUTHORITY - prevents double voting
  "voterUsername": "grace" // DISPLAY
  "choice": "for" // for, against, abstain
  "castAt": timestamp
}
```

**Why UID-keyed votes:**
- One vote per user (enforced by document ID)
- Rename-proof (historical attribution)
- Impersonation-proof

## 🛡️ Validation Rules (Enforced Before Execution)

### Rule 1: enabledRoles Gates Everything
```javascript
if (change.path.startsWith('rolePowers.')) {
  const role = change.path.split('.')[1];
  if (!enabledRoles.includes(role)) {
    reject("Cannot modify powers for disabled role");
  }
}
```

### Rule 2: votingBody Must Be Satisfiable
```javascript
if (disabling('voter') && anySOPRequires('eligible_voters')) {
  reject("Cannot disable voter role - required by procedures");
}
```

### Rule 3: beElected Requires Election Path
```javascript
if (setting('beElected', true)) {
  if (!proposalTypes.includes('election') && !alternateMethod) {
    reject("beElected requires election mechanism");
  }
}
```

### Rule 4: editDocs "direct" Is Constitutional
```javascript
if (setting('editDocs', 'direct')) {
  // High-impact change - log as constitutional
  // "Direct" means "author the draft", NOT "silent mutation"
  requiresRatification = true;
}
```

## 🔄 Proposal Lifecycle

```
1. DRAFT
   ↓ (creator submits)
2. SUBMITTED
   ↓ (if SOP requires debate)
3. DEBATING
   ↓ (debate period ends)
4. VOTING
   ↓ (vote passes/fails based on threshold)
5a. PASSED → 6. EXECUTED (applied to government)
5b. REJECTED (archived)
```

## 🎨 UI Flow

### Current Behavior (Wrong):
```dart
// ❌ Direct mutation
Switch(
  value: rolePowers['member']['proposeLaws'],
  onChanged: (val) => rolePowers['member']['proposeLaws'] = val
)
```

### Correct Behavior:
```dart
// ✅ Opens proposal draft
Switch(
  value: rolePowers['member']['proposeLaws'],
  onChanged: (val) => _proposeGovernanceChange(
    path: 'rolePowers.member.proposeLaws',
    value: val
  )
)

void _proposeGovernanceChange(path, value) {
  // Create proposal draft
  // User adds rationale
  // Submit → routes through SOP
  // Debate → Vote → Execute
}
```

### Role Powers View:
- **Can propose changes**: Show "Propose Changes" button
- **Cannot propose**: Show "Read-only (locked by constitution)" badge
- **All changes**: Create proposals, not direct edits

## 🔧 Allowed Operations

### A) Role System Structure
- `enable_role` - Add to enabledRoles
- `disable_role` - Remove from enabledRoles (validates dependencies)
- `change_transition` - Modify roleTransitions
- `set_duration` - Update roleDurations

### B) Permissions (per role)
- `set_power` - Change permission flag (fork, proposeLaws, vote, etc.)
- `set_edit_mode` - Change editDocs (no | draft | direct)
- `set_eligibility` - Change beElected, vote eligibility

### C) Meta Actions
- `recompute_constraints` - Validate all dependencies
- `migrate_members` - If role disabled, move members to fallback role

## 🚀 Implementation Phases

### ✅ PHASE 1 - Data Models (COMPLETE)
- ProposalModel with governance_change type
- ProposalChange for atomic operations
- SOP snapshot to freeze rules

### ✅ PHASE 2 - Services (COMPLETE)
- ProposalService with create/validate/execute
- Validation rules enforced
- UID-based voting

### ✅ PHASE 3 - Basic UI (COMPLETE)
- ProposalsView with Active/Passed/All tabs
- Proposal cards with status badges
- governance_change highlighted in red
- Vote counts displayed

### 📅 PHASE 4 - Advanced UI (NEXT)
- Proposal creation form
- Debate interface
- Voting interface
- Execution triggers

### 📅 PHASE 5 - Server-Side Enforcement
- Cloud Functions for validation
- Atomic execution with rollback
- Audit log versioning

## 🎯 Key Design Decisions

### 1. governance_change Cannot Be Disabled
- Always in proposalTypes
- Locked in UI (cannot uncheck)
- Required for legitimate governance

### 2. SOP Snapshot Frozen
- Proposal created with current rules
- Rules changing mid-vote doesn't affect proposal
- Clean audit trail

### 3. Validation Before Execution
- All constraints checked
- Dependency graph validated
- Failed validation = proposal rejected

### 4. Founder Has No Permanent Power
- Founder role has no special bypass
- Can only propose like others
- Must follow SOP for governance changes

## 📖 Example: Changing Role Powers

**Scenario**: Members want to propose laws (currently can't).

### Step 1: Create Proposal
```dart
proposalService.createProposal(
  governmentId: govId,
  creatorUid: currentUid, // AUTHORITY
  creatorUsername: currentUsername, // DISPLAY
  type: 'governance_change',
  category: 'roles_and_permissions',
  title: 'Allow Members to Propose Laws',
  rationale: 'Broader participation in lawmaking...',
  changes: [
    ProposalChange(
      op: 'set',
      path: 'rolePowers.member.proposeLaws',
      value: true
    )
  ],
  sopSnapshot: government.lawmakingSOP['governance_change']
);
```

### Step 2: SOP Evaluation
- Check `debateRequired` → "always" → Enter debate phase
- Check `voteRequired` → true → After debate, start voting
- Check `votingBody` → "eligible_voters" → Only voters can vote
- Check `threshold` → "supermajority_66" → Need 66% approval

### Step 3: Vote (UID-based!)
```dart
proposalService.castVote(
  governmentId: govId,
  proposalId: propId,
  voterUid: currentUid, // AUTHORITY
  voterUsername: currentUsername, // DISPLAY
  choice: 'for'
);
```

### Step 4: Execution (After Passing)
```dart
proposalService.executeGovernanceChange(
  governmentId: govId,
  proposalId: propId,
  executorUid: executorUid
);
```

Applies changes to government document atomically.

### Step 5: Audit Trail
- Proposal archived with full history
- Audit log entry created
- Version snapshot (optional)

## ⚠️ Security Guarantees

✅ **No Direct Mutation**: All changes via proposals
✅ **Consensus Required**: Supermajority for governance changes
✅ **UID-Based Authority**: Votes keyed by UID, not username
✅ **Validation Enforced**: Invalid changes rejected
✅ **Audit Trail**: Complete history of all governance changes
✅ **Frozen Rules**: SOP can't change mid-proposal
✅ **No Founder Bypass**: Even creator follows the rules

This creates **legitimate, accountable, democratic governance**! 🏛️
