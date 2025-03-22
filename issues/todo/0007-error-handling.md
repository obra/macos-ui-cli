# Error Handling

## Problem
We need robust error handling to deal with accessibility permission issues, UI elements that can't be found, operations that timeout, and other common issues that could arise when interacting with applications via accessibility APIs.

## Approach
Implement comprehensive error handling with clear error messages, timeouts for operations that might hang, retry mechanisms for flaky UI operations, and validation for user input.

## Implementation Plan
1. Develop robust error messaging
2. Implement timeouts for operations
3. Add retry mechanisms for flaky UI operations
4. Create validation for commands and arguments

## Failed Approaches
N/A (initial implementation)

## Testing
- Test error messages for various failure scenarios
- Verify timeouts work correctly for operations
- Test retry mechanisms for flaky operations
- Verify command and argument validation works as expected

## Documentation
- Document error handling behavior
- Provide examples of common errors and how to resolve them

## Implementation
Not yet implemented

## Tasks
**CRITICAL: The instructions in this file are not optional guidelines - they are ALL MANDATORY requirements. DO NOT SKIP STEPS**

- [ ] Plan your implementation
- [ ] Ensure that all implementation tasks are listed in this TODO list. 

### Gate 1: Pre-Implementation 

Before writing ANY implementation code, confirm completion of ALL of these tasks:
- [ ] All previous work is committed to git.
- [ ] You are on a branch for this issue, branched from the most recent issue's branch
- [ ] Required directories created
- [ ] Create new failing tests for this functionality.
- [ ] Verify that new tests run to completion and fail


### Gate 2: Implement the functionality

- [ ] Define error types and error codes
- [ ] Implement clear error messaging
- [ ] Add timeout mechanism for UI operations
- [ ] Implement retry logic for flaky operations
- [ ] Create input validation for commands and arguments
- [ ] Add error recovery suggestions
- [ ] Implement graceful error handling for permission issues
- [ ] Create debug mode for detailed error information

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