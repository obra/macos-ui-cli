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

- [x] Plan your implementation
- [x] Ensure that all implementation tasks are listed in this TODO list. 

### Implementation Plan
1. Enhance Element class with UI interaction capabilities:
   - Add ButtonElement subclass to support button pressing
   - Add TextFieldElement subclass for text input/output
   - Implement keyboard input simulation methods
   - Add element action discovery (what can be done with elements)

2. Enhance Window class with manipulation capabilities:
   - Add methods to move/resize windows
   - Implement window focus and raise functionality
   - Add window manipulation through accessibility actions

3. Create new CLI commands for interaction:
   - Add command to press buttons
   - Add command to read/write text fields
   - Add command to manipulate windows
   - Add command to simulate keyboard input

4. Write comprehensive tests:
   - Unit tests for all interaction methods
   - Mock tests for UI actions
   - Integration tests with test applications

### Gate 1: Pre-Implementation 

Before writing ANY implementation code, confirm completion of ALL of these tasks:
- [x] All previous work is committed to git.
- [x] You are on a branch for this issue, branched from the most recent issue's branch
- [x] Required directories created
- [x] Create new failing tests for this functionality.
- [x] Verify that new tests run to completion and fail

Note: The tests were running but we needed to add proper mock implementations to make them fail initially. We've set up the mocks and verified that they work correctly. Additionally, we fixed issues with the HAXApplication non-existent PID handling.


### Gate 2: Implement the functionality

- [x] Create Swift wrapper for HAXButton
- [x] Implement button pressing functionality
- [x] Create methods for text field manipulation
- [x] Implement text reading from UI elements
- [x] Implement text writing to UI elements
- [x] Develop window manipulation methods (position, size)
- [x] Implement window focus and raise methods
- [x] Add element action discovery
- [x] Implement keyboard input simulation
- [x] Create convenience methods for common actions

### Gate 3: Mid-Implementation Review 

After implementing core functionality:
- [x] Verify all completed code adheres to ALL requirements in this file and in CLAUDE.md
- [x] Confirm test coverage for all implemented features

Notes from review:
1. All code has proper comments and documentation following the ABOUTME format
2. The implementation matches the style of the existing codebase
3. Tests cover all new functionality including:
   - Button interaction
   - Text field reading/writing
   - Window manipulation (position, size, focus, etc.)
   - Keyboard input simulation
   - Element action discovery
4. All code is working correctly as demonstrated by passing tests

### Gate 4: Pre-Completion Verification

Before declaring the task complete perform these MANDATORY checks:
- [x] Run ALL verification commands (tests, linting, typechecking)
- [x] Write function-level documentation for all functions explaining what they do, their parameters, return values, and usage examples where appropriate.
- [x] Add explanatory comments for any non-obvious or tricky code that might confuse another experienced developer who isn't familiar with this specific codebase.
- [x] Update the README.md. It should always include:
	- [x] a set of examples showing how to use all the commandline tools in the project. 
	- [x] how to run the test suite
	- [x] steps needed to set up a development environment
- [x] Run the unit tests by themselves. Verify that they to completion and pass and that there is no unexpected output

Verification results:
1. All tests pass successfully with 0 failures
2. All functions have proper documentation with parameter and return descriptions
3. Complex code sections have explanatory comments
4. README.md has been updated with:
   - New command documentation 
   - UI interaction examples
   - Updated feature list
5. All build and verification commands complete successfully

### Gate 5: Final commit for the issue 
- [x] Audit all uncommitted files in your working copy
	- [x] Make sure that all files are either committed or, if they're temporary files, removed.
- [x] Author a meaningful commit message for this change. Include details of your intent, as well as logs showing that you ran tests and that they passed.

Final verification:
- All code changes have been committed
- All tests pass successfully
- Documentation is complete and up-to-date
- Feature implementation is fully compliant with requirements
- Issue is ready to be closed and moved to "done"

FAILURE TO PASS ANY GATE INVALIDATES THE WHOLE IMPLEMENTATION. 
YOU ARE NOT DONE UNTIL YOU CLEAR GATE 5.
NO EXCEPTIONS POLICY: Under no circumstances should you mark any test type as "not applicable". Every project, regardless of size or complexity, MUST have tests. If you believe tests aren't needed, ask the human to confirm by typing "YOU CAN SKIP THE TESTS, JUST THIS ONCE"