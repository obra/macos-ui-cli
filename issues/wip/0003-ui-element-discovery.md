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
Implementation in progress.

### Plan
1. Create Swift wrapper for HAXWindow:
   - Implement window enumeration
   - Add methods to get window properties (title, frame, etc.)
   - Add window visibility and focus management

2. Create Swift wrapper for HAXElement:
   - Implement hierarchical element traversal (parent, children)
   - Add methods to get element properties (role, title, etc.)
   - Create element filtering capabilities

3. Implement element discovery functionality:
   - Add methods to find elements by type (buttons, text fields, etc.)
   - Create focused element detection
   - Implement methods to find elements by path or accessibility hierarchy

4. Expose functionality through a CLI subcommand:
   - Add commands to list windows
   - Add commands to find and inspect UI elements
   - Add interactive element discovery features

## Tasks
**CRITICAL: The instructions in this file are not optional guidelines - they are ALL MANDATORY requirements. DO NOT SKIP STEPS**

- [x] Plan your implementation
- [x] Ensure that all implementation tasks are listed in this TODO list. 

### Gate 1: Pre-Implementation 

Before writing ANY implementation code, confirm completion of ALL of these tasks:
- [x] All previous work is committed to git.
- [x] You are on a branch for this issue, branched from the most recent issue's branch
- [x] Required directories created (We'll use the existing structure)
- [x] Create new failing tests for this functionality.
- [x] Verify that new tests run to completion and fail


### Gate 2: Implement the functionality

- [x] Create Swift wrapper for HAXWindow
- [x] Implement window enumeration for applications
- [x] Create Swift wrapper for HAXElement
- [x] Implement hierarchical element traversal (parent, children)
- [x] Develop element property inspection (role, title, etc.)
- [x] Build element filtering by type (buttons, text fields, etc.)
- [x] Implement element filtering by attributes
- [x] Create focused element detection
- [x] Implement methods to find elements by path

### Gate 3: Mid-Implementation Review 

After implementing core functionality:
- [x] Verify all completed code adheres to ALL requirements in this file and in CLAUDE.md
- [x] Confirm test coverage for all implemented features

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

### Gate 5: Final commit for the issue 
- [ ] Audit all uncommitted files in your working copy
	- [ ] Make sure that all files are either committed or, if they're temporary files, removed.
- [ ] Author a meaningful commit message for this change. Include details of your intent, as well as logs showing that you ran tests and that they passed.

FAILURE TO PASS ANY GATE INVALIDATES THE WHOLE IMPLEMENTATION. 
YOU ARE NOT DONE UNTIL YOU CLEAR GATE 5.
NO EXCEPTIONS POLICY: Under no circumstances should you mark any test type as "not applicable". Every project, regardless of size or complexity, MUST have tests. If you believe tests aren't needed, ask the human to confirm by typing "YOU CAN SKIP THE TESTS, JUST THIS ONCE"