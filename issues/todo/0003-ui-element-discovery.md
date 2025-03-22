# UI Element Discovery

## Problem
We need to be able to discover, enumerate, and inspect UI elements within macOS applications to enable interaction through the accessibility API.

## Approach
Implement window enumeration and hierarchical element traversal functionality in Swift by wrapping the Haxcessibility library's HAXWindow and HAXElement classes. Develop capabilities to inspect element properties and filter elements by type or attributes.

## Implementation Plan
1. Implement window enumeration to list all windows for an application
2. Create hierarchical element traversal to navigate UI element trees
3. Develop element property inspection to read attributes like role, title, etc.
4. Build element filtering to find elements by type or attributes
5. Implement focused element detection to identify the currently active element

## Failed Approaches
N/A (initial implementation)

## Testing
- Test window enumeration with various applications
- Verify hierarchical traversal correctly navigates element trees
- Test property inspection returns expected values
- Verify element filtering correctly identifies elements by type
- Test focused element detection identifies the active element

## Documentation
- Document window and element discovery methods
- Provide examples of element traversal and inspection

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

- [ ] Create Swift wrapper for HAXWindow
- [ ] Implement window enumeration for applications
- [ ] Create Swift wrapper for HAXElement
- [ ] Implement hierarchical element traversal (parent, children)
- [ ] Develop element property inspection (role, title, etc.)
- [ ] Build element filtering by type (buttons, text fields, etc.)
- [ ] Implement element filtering by attributes
- [ ] Create focused element detection
- [ ] Implement methods to find elements by path

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