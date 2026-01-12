---
name: research-plan-implement
description: A structured workflow for AI-assisted development using research, planning, and systematic implementation phases
agents:
  - codebase-locator
  - codebase-analyzer
  - pattern-finder
---

# Research-Plan-Implement Workflow

This skill provides a structured approach to software development through three distinct phases: Research, Plan, and Implement. Each phase builds on the previous to ensure thorough understanding before making changes.

## Workflow Phases

### Phase 1: Research Codebase

Before making any changes, deeply explore the codebase to understand:

1. **Architecture Analysis**
   - Identify the overall project structure and organization
   - Map dependencies and module relationships
   - Understand build systems and tooling

2. **Pattern Discovery**
   - Find existing patterns for similar functionality
   - Identify coding conventions and style guides
   - Note testing patterns and coverage expectations

3. **Relevant Code Location**
   - Locate files that will need modification
   - Identify related files that may be affected
   - Find existing tests for the areas of change

**Research Execution Strategy:**
- Use parallel agent execution for faster analysis
- Document findings in a structured format
- Answer specific questions about the codebase before proceeding

**Research Questions to Answer:**
- Where does similar functionality already exist?
- What patterns should new code follow?
- What files will need to be modified?
- What tests already exist for this area?
- Are there any architectural constraints to consider?

### Phase 2: Create Implementation Plan

Based on research findings, create a detailed implementation plan:

1. **Define Scope**
   - List all files that will be created or modified
   - Identify dependencies between changes
   - Set clear boundaries for what is included/excluded

2. **Phase the Work**
   - Break implementation into logical phases
   - Order phases by dependencies
   - Define success criteria for each phase

3. **Specify Details**
   - For each change, describe the specific modifications
   - Include code patterns to follow
   - Note any risks or considerations

**Plan Structure Template:**

```markdown
## Implementation Plan: [Feature/Change Name]

### Overview
[Brief description of the change and its purpose]

### Research Summary
[Key findings from the research phase]

### Phases

#### Phase 1: [Phase Name]
**Files:**
- [ ] `path/to/file1.ts` - [Description of changes]
- [ ] `path/to/file2.ts` - [Description of changes]

**Success Criteria:**
- [ ] [Specific, testable criterion]
- [ ] [Specific, testable criterion]

#### Phase 2: [Phase Name]
[Continue with additional phases...]

### Testing Strategy
[How to verify the implementation]

### Rollback Plan
[How to revert if issues arise]
```

### Phase 3: Validate Plan

Before implementation, verify the plan is complete and correct:

1. **Completeness Check**
   - All necessary files identified
   - All dependencies mapped
   - Success criteria are testable

2. **Feasibility Review**
   - Changes are technically sound
   - No conflicts with existing code
   - Follows established patterns

3. **Risk Assessment**
   - Potential issues identified
   - Mitigation strategies defined
   - Rollback path is clear

### Phase 4: Implement Plan

Execute the plan systematically:

1. **Follow the Plan**
   - Implement changes in phase order
   - Mark checkboxes as tasks complete
   - Verify success criteria at each step

2. **Track Progress**
   - Update plan document with completion status
   - Note any deviations from the plan
   - Document decisions made during implementation

3. **Validate Continuously**
   - Run tests after each phase
   - Verify integration points
   - Check against success criteria

**Implementation Rules:**
- Never skip phases or steps
- If the plan needs changes, update it before proceeding
- Document any issues encountered
- Commit after completing each phase

## Usage Instructions

When invoking this skill, specify your intent:

1. **To Research:** "Research the codebase to understand [specific topic or area]"
2. **To Plan:** "Create an implementation plan for [feature/change]"
3. **To Validate:** "Validate the implementation plan for [feature/change]"
4. **To Implement:** "Implement the plan for [feature/change]"

## Agent Collaboration

This skill leverages specialized agents for research:

### Codebase Locator Agent
Finds relevant files and directories for a given topic or feature area. Use when you need to discover where specific functionality lives.

### Codebase Analyzer Agent
Performs deep analysis of code structure, patterns, and dependencies. Use for understanding how systems work.

### Pattern Finder Agent
Identifies coding patterns, conventions, and best practices used in the codebase. Use to ensure new code follows existing standards.

## Context Persistence

For long-running projects, save progress using a structured format:

```markdown
## Session: [Date/Time]

### Current State
- Phase: [Research/Plan/Implement]
- Progress: [Description]

### Completed
- [x] [Completed item]

### In Progress
- [ ] [Current work]

### Next Steps
- [ ] [Upcoming work]

### Notes
[Important observations or decisions]
```

## Best Practices

1. **Research First**: Never skip the research phase. Understanding prevents mistakes.
2. **Plan Thoroughly**: A detailed plan saves time during implementation.
3. **Validate Before Acting**: Catch issues before they become problems.
4. **Track Everything**: Document progress and decisions.
5. **Use Parallel Agents**: Speed up research with concurrent analysis.
6. **Commit Often**: Save progress after each logical unit of work.
7. **Test Continuously**: Verify each phase before moving on.
