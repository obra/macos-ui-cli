# Permissions and Application Access

## Problem
To interact with macOS applications via accessibility APIs, we need to handle permissions properly and implement core functionality to discover and connect to applications.

## Approach
Implement permission request workflows for accessibility access and create Swift wrappers around HAXSystem and HAXApplication classes to discover processes and connect to applications.

## Implementation Plan
1. Create permission handling for macOS accessibility features
2. Implement process discovery to find running applications
3. Develop Swift wrappers around HAXSystem to access system-wide accessibility features
4. Create application connection functionality via PID/name
5. Build a clean Swift object model representing applications

## Failed Approaches
N/A (initial implementation)

## Testing
- Test permission request and validation
- Verify process discovery finds running applications
- Test connecting to applications by PID and name
- Verify Swift application model contains expected properties

## Documentation
- Document permission requirements for users
- Document application connection methods and examples

## Implementation
Implementation in progress.

### Plan
1. Create Swift wrappers for accessibility permissions:
   - Check if accessibility features are enabled
   - Provide guidance for enabling accessibility features if not enabled
   - Handle permission errors gracefully

2. Implement Swift wrappers for HAXSystem:
   - Create a SystemAccessibility class that wraps HAXSystem
   - Add methods to get running applications 
   - Add methods to get focused application

3. Implement Swift wrappers for HAXApplication:
   - Create an Application class that wraps HAXApplication
   - Add properties for application name, PID, etc.
   - Add methods to interact with application windows

4. Create Swift models for application properties:
   - Define Swift structs for application info

5. Implement application discovery:
   - Find running applications by name
   - Find running applications by PID
   - List all running applications

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

- [x] Create permission request and validation functions
- [x] Implement process discovery to find running applications
- [x] Create Swift wrapper for HAXSystem
- [x] Implement methods to get focused application
- [x] Create Swift wrapper for HAXApplication
- [x] Implement application connection by PID
- [x] Implement application lookup by name
- [x] Create clean Swift models for application properties
- [x] Implement methods to get application windows

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