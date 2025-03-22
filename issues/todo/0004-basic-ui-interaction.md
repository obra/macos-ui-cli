# Basic UI Interaction

## Problem
To make our CLI tool useful, we need to implement capabilities to interact with UI elements, such as pressing buttons, reading/writing text fields, manipulating windows, and simulating keyboard input.

## Approach
Leverage the Haxcessibility library's action methods to enable interaction with UI elements, wrapping them in a clean Swift API that makes common actions easy to perform.

## Implementation Plan
1. Implement button pressing functionality
2. Add text field reading and writing capabilities
3. Develop window manipulation (move, resize, focus)
4. Add element action discovery (what can be done with an element)
5. Implement basic keyboard input simulation

## Failed Approaches
N/A (initial implementation)

## Testing
- Test button pressing with various applications
- Verify text field reading and writing works correctly
- Test window manipulation operations
- Verify action discovery correctly identifies available actions
- Test keyboard input simulation

## Documentation
- Document UI interaction methods and examples
- Provide usage examples for common tasks

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

- [ ] Create Swift wrapper for HAXButton
- [ ] Implement button pressing functionality
- [ ] Create methods for text field manipulation
- [ ] Implement text reading from UI elements
- [ ] Implement text writing to UI elements
- [ ] Develop window manipulation methods (position, size)
- [ ] Implement window focus and raise methods
- [ ] Add element action discovery
- [ ] Implement keyboard input simulation
- [ ] Create convenience methods for common actions

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