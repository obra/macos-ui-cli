# Project Setup

## Problem
We need to establish the foundation for our Swift-based command-line tool that will interact with the Haxcessibility library to control macOS applications through the accessibility API.

## Approach
Create a proper Swift package structure with necessary build configurations, bridging headers for the Objective-C Haxcessibility library, and basic CLI argument parsing setup.

## Implementation Plan
1. Create a new Swift package for the CLI tool
2. Set up the build system to include the Haxcessibility library
3. Create bridging headers to access Objective-C code from Swift
4. Implement basic command-line argument parsing using ArgumentParser

## Failed Approaches
N/A (initial setup)

## Testing
- Verify the project builds successfully
- Ensure Haxcessibility classes are accessible from Swift code
- Test basic command-line argument parsing

## Documentation
- README.md with project overview and setup instructions
- Basic usage documentation for the CLI tool

## Implementation
Not yet implemented

## Tasks
**CRITICAL: The instructions in this file are not optional guidelines - they are ALL MANDATORY requirements. DO NOT SKIP STEPS**

- [x] Plan your implementation
- [x] Ensure that all implementation tasks are listed in this TODO list. 

### Gate 1: Pre-Implementation 

Before writing ANY implementation code, confirm completion of ALL of these tasks:
- [x] All previous work is committed to git.
- [x] You are on a branch for this issue, branched from the most recent issue's branch
- [x] Required directories created
- [x] Create new failing tests for this functionality.
- [x] Verify that new tests run to completion and fail


### Gate 2: Implement the functionality

- [ ] Initialize Swift package with SwiftPM
- [ ] Set up dependency on ArgumentParser package
- [ ] Configure build settings to include Haxcessibility library
- [ ] Create bridging header for Haxcessibility
- [ ] Import Haxcessibility in Swift code
- [ ] Create basic CLI command structure
- [ ] Implement help command and version flags
- [ ] Test build with basic imports

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