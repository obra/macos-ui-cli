# CLI Command Structure

## Problem
We need to design and implement a well-structured, intuitive command-line interface for our tool that makes it easy to discover and interact with UI elements in macOS applications.

## Approach
Design a hierarchical command structure with clear subcommands for different operations, implement those commands, and provide comprehensive help documentation and examples.

## Implementation Plan
1. Design the CLI command hierarchy and syntax
2. Implement subcommands for different operations (list, inspect, interact, etc.)
3. Add help documentation and examples for each command
4. Create consistent output formatting for command results

## Failed Approaches
N/A (initial implementation)

## Testing
- Test each command with various parameters
- Verify help documentation is clear and accurate
- Test command output formatting for readability

## Documentation
- Comprehensive help text for each command and subcommand
- Examples showing typical command usage

## Implementation
Not yet implemented

## Tasks
**CRITICAL: The instructions in this file are not optional guidelines - they are ALL MANDATORY requirements. DO NOT SKIP STEPS**

- [x] Plan your implementation
- [x] Ensure that all implementation tasks are listed in this TODO list. 

### Gate 1: Pre-Implementation 

Before writing ANY implementation code, confirm completion of ALL of these tasks:
- [x] All previous work is committed to git.
- [x] You are on a branch for this issue, branched from the most recent issue's branch (issue-0005/cli-command-structure)
- [x] Required directories created
- [x] Create new failing tests for this functionality.
- [x] Verify that new tests run to completion and fail


### Gate 2: Implement the functionality

- [x] Design root command and subcommand structure
    - Create logical grouping of commands (discovery, interaction, utility)
    - Organize commands into appropriate groups
- [x] Reorganize main.swift file to separate commands into files by group
    - [x] Create DiscoveryCommands.swift file
    - [x] Create InteractionCommands.swift file
    - [x] Create UtilityCommands.swift file
- [x] Enhance command documentation
    - [x] Add detailed descriptions for all commands
    - [x] Add usage examples in help text
    - [x] Improve option descriptions
- [x] Add command configuration improvements
    - [x] Add detailed discussion sections
    - [x] Add usage examples
    - [x] Create command groups
- [x] Implement version command with detailed info
- [x] Add help improvements
    - [x] Include examples in help text
    - [x] Add command completion support

### Gate 3: Mid-Implementation Review 

After implementing core functionality:
- [ ] Verify all completed code adheres to ALL requirements in this file and in CLAUDE.md
- [ ] Confirm test coverage for all implemented features

### Gate 4: Pre-Completion Verification

Before declaring the task complete perform these MANDATORY checks:
- [ ] Run ALL verification commands (tests, linting, typechecking)
- [ ] Write function-level documentation for all functions explaining what they do, their parameters, return values, and usage examples where appropriate.
- [ ] Add explanatory comments for any non-obvious or tricky code that might confuse another experienced developer who isn't familiar with this specific codebase.
- [ ] Update the README.md. It should always include:
	- [ ] a set of examples showing how to use all the commandline tools in the project. 
	- [ ] how to run the test suite
	- [ ] steps needed to set up a development environment
- [ ] Run the unit tests by themselves. Verify that they to completion and pass and that there is no unexpected output

### Gate 5: Final commit for the issue 
- [ ] Audit all uncommitted files in your working copy
	- [ ] Make sure that all files are either committed or, if they're temporary files, removed.
- [ ] Author a meaningful commit message for this change. Include details of your intent, as well as logs showing that you ran tests and that they passed.

FAILURE TO PASS ANY GATE INVALIDATES THE WHOLE IMPLEMENTATION. 
YOU ARE NOT DONE UNTIL YOU CLEAR GATE 5.
NO EXCEPTIONS POLICY: Under no circumstances should you mark any test type as "not applicable". Every project, regardless of size or complexity, MUST have tests. If you believe tests aren't needed, ask the human to confirm by typing "YOU CAN SKIP THE TESTS, JUST THIS ONCE"