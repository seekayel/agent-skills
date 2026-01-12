# agent-skills

Collection of skills for Claude Code agents.

## Plugins

### research-plan-implement-plugin

A structured workflow for AI-assisted development using research, planning, and systematic implementation phases. Includes specialized sub-agents for codebase exploration.

### orchestration-plugin

Tools for orchestrating and improving coding agent workflows.

## Usage

To use these skills in your project, add the following to your local `AGENTS.md` file (or `CLAUDE.md`):

### Research-Plan-Implement Workflow

Add this snippet to ensure Claude uses the structured research-plan-implement approach for all code changes:

```markdown
## Development Workflow

When implementing changes, features, or bug fixes, follow the research-plan-implement workflow:

### Before Making Changes

1. **Research Phase**: Before modifying any code, thoroughly research the codebase:
   - Use the `codebase-locator` agent to find relevant files and directories
   - Use the `codebase-analyzer` agent to understand code structure and dependencies
   - Use the `pattern-finder` agent to identify existing patterns and conventions
   - Document findings before proceeding

2. **Planning Phase**: Create a detailed implementation plan:
   - List all files that need to be created or modified
   - Break work into logical phases with clear success criteria
   - Identify dependencies between changes
   - Define testing strategy

3. **Validation Phase**: Before implementing, verify:
   - All necessary files have been identified
   - Changes follow existing patterns
   - Success criteria are testable

4. **Implementation Phase**: Execute systematically:
   - Follow the plan in phase order
   - Verify success criteria at each step
   - Commit after completing each phase

5. **Testing Phase**: Run the tests defined in the Planning phase:
   - Execute all test cases from the testing strategy
   - Verify all success criteria are met
   - Fix any failures before considering the work complete
   - Do not skip tests or mark work as done until all tests pass

### Agent Usage

When researching the codebase, spawn these specialized agents in parallel:

- **codebase-locator**: "Find all files related to [feature/component]"
- **codebase-analyzer**: "Analyze the architecture of [system/module]"
- **pattern-finder**: "Identify patterns used for [type of code]"

### Required Outputs

For any non-trivial change, produce:
1. Research summary documenting relevant files and patterns found
2. Implementation plan with phases and success criteria
3. Validation checklist confirming plan completeness
```

### Minimal Version

For a more concise configuration, use this minimal snippet:

```markdown
## Development Workflow

For all code changes:
1. **Research first** - Use codebase-locator, codebase-analyzer, and pattern-finder agents to understand the codebase before making changes
2. **Plan before implementing** - Create a phased implementation plan with success criteria and testing strategy
3. **Validate the plan** - Verify completeness before writing code
4. **Implement systematically** - Follow the plan, verify each phase, commit often
5. **Test thoroughly** - Run all tests from the plan, fix failures, do not skip tests
```

### Agent-Focused Version

If you want to emphasize parallel agent usage:

```markdown
## Agent-Driven Research

Before implementing any feature or fix, spawn these research agents in parallel:

| Agent | Purpose | Example Prompt |
|-------|---------|----------------|
| codebase-locator | Find relevant files | "Locate all authentication-related files" |
| codebase-analyzer | Understand structure | "Analyze how the API layer handles requests" |
| pattern-finder | Identify conventions | "Find patterns for creating new endpoints" |

Wait for all agents to complete, then synthesize findings into an implementation plan before writing any code.
```

## Installation

### Install the Plugin Marketplace

Add the agent-skills marketplace to your Claude Code configuration:

```bash
# Add the marketplace to your global Claude Code settings
claude mcp add agent-skills-marketplace https://github.com/seekayel/agent-skills
```

Or manually add to your `~/.claude/settings.json`:

```json
{
  "plugins": {
    "marketplaces": [
      {
        "name": "agent-skills-marketplace",
        "source": "https://github.com/seekayel/agent-skills"
      }
    ]
  }
}
```

### Install Individual Plugins

Once the marketplace is added, install specific plugins:

```bash
# Install the research-plan-implement plugin
claude plugin install research-plan-implement-plugin

# Install the orchestration plugin
claude plugin install orchestration-plugin
```

Or add to your project's `.claude/settings.json`:

```json
{
  "plugins": {
    "installed": [
      "agent-skills-marketplace/research-plan-implement-plugin",
      "agent-skills-marketplace/orchestration-plugin"
    ]
  }
}
```

### Configure Your Project

Add the appropriate AGENTS.md snippet (see Usage section above) to your project to ensure Claude follows the research-plan-implement workflow.

## License

MIT
