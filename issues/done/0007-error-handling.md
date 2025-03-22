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
The error handling system has been implemented with the following components:

1. **Error Types and Hierarchy**:
   - Created `ApplicationError` protocol as the base for all application errors
   - Implemented specialized error types for different categories:
     - `AccessibilityError`: For permission and access issues
     - `UIElementError`: For problems with UI elements
     - `WindowError`: For window-related issues
     - `ApplicationManagerError`: For application management issues
     - `OperationError`: For timeouts and retry failures
     - `ValidationError`: For command argument validation failures

2. **Error Codes**:
   - Added numerical error codes (100s for accessibility, 200s for UI elements, etc.)
   - Consistent error codes make programmatic error handling easier

3. **Recovery Suggestions**:
   - Each error type includes user-friendly recovery suggestions
   - Helps users troubleshoot problems without reading documentation

4. **Timeout and Retry Mechanisms**:
   - Implemented `withTimeout()` function to prevent operations from hanging
   - Added `withRetry()` for flaky UI operations with configurable attempts and delay
   - Combined both with `withTimeoutAndRetry()` for robust UI interactions

5. **Input Validation**:
   - Added validation for command arguments and parameters
   - Provides clear error messages for invalid inputs

6. **Debug Logging**:
   - Implemented `DebugLogger` with different severity levels
   - Logs errors, warnings, and debug information

7. **Error Handler**:
   - Centralized error handling with `ErrorHandler` class
   - Formats error messages based on output format preferences

8. **NoThrow Pattern**:
   - Added methods with "NoThrow" suffix for backward compatibility
   - These methods catch errors and return nil/empty/false 

All UI operation methods now properly throw errors, with NoThrow variants available for backward compatibility. Command implementations have been updated to use try/catch patterns and proper error handling.

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

- [x] Define error types and error codes
- [x] Implement clear error messaging
- [x] Add timeout mechanism for UI operations
- [x] Implement retry logic for flaky operations
- [x] Create input validation for commands and arguments
- [x] Add error recovery suggestions
- [x] Implement graceful error handling for permission issues
- [x] Create debug mode for detailed error information

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
- [x] Audit all uncommitted files in your working copy
	- [x] Make sure that all files are either committed or, if they're temporary files, removed.
- [x] Author a meaningful commit message for this change. Include details of your intent, as well as logs showing that you ran tests and that they passed.

Test execution results:
```
Test Suite 'All tests' passed at 2025-03-22 16:17:21.590.
	 Executed 46 tests, with 0 failures (0 unexpected) in 16.646 (16.650) seconds
```

The error handling system is now fully implemented and all tests are passing. The implementation successfully addresses all the requirements in the issue.