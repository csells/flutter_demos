This document outlines the development tasks for building the Crossword Companion app. The tasks are structured as a series of milestones, each delivering a piece of visible functionality to the user.

## [x] Milestone 1: Basic App Shell and UI Structure

Create the main application window with a vertical stepper to guide the user through the workflow. All steps will be present, but initially disabled beyond the first step.

- [x] Create the project structure as defined in `design.md`.
- [x] Implement the main screen with a `Stepper` widget containing all 5 steps from the design.
- [x] Use the `provider` package to create a basic `CrosswordState` notifier to manage the current stepper index.
- [x] Refactor the button layout on all step pages to be right-aligned, with the primary action on the far right, as specified in the design.

## [x] Milestone 2: Select Crossword Image

Implement the functionality for the user to select a single crossword image (containing both the grid and clues) from their device.

- [x] Create an `ImagePickerService` to abstract the `image_picker` plugin.
- [x] Implement the UI for Step 1 ("Select Crossword Image").
- [x] Update `CrosswordState` to hold the selected crossword image.

## [x] Milestone 3: Grid Size Inference and Verification

Implement the AI's ability to infer the grid dimensions from the image and allow the user to correct them.

- [x] Set up the `firebase_ai` package and create a `GeminiService`.
- [x] Implement the `inferCrosswordData(image)` method in `GeminiService` to call the `gemini-2.5-pro` model.
- [x] Create the UI for Step 2 ("Verify Grid Size").
- [x] Update `CrosswordState` to hold the grid dimensions.

## [x] Milestone 4: Grid Contents Inference and Verification

Implement the AI's ability to infer the grid's structure (cells and numbers) and allow the user to edit it.

- [x] Create the data models: `CrosswordGrid` and `GridCell`.
- [x] Implement the UI for Step 3 ("Verify Grid Contents") that overlays the inferred grid on the original image.
    - [x] Add functionality to allow users to tap on cells to set the cell to inactive (black), empty (white), or numbered with a user-provided number.
## [x] Milestone 5: Clue Text Inference and Verification

Implement the AI's ability to infer the clue text from the crossword image and allow the user to edit it.

- [x] Create the `Clue` data model.
- [x] Create a `ClueList` widget to display the "Across" and "Down" clues.
- [x] Implement the UI for Step 4 ("Verify Clue Text").
- [x] Add functionality for the user to edit the clues.

## [x] Milestone 6: Pre-Solve Validation

Implement a validation step to ensure the integrity of the puzzle data before solving.

- [x] Implement a validation step to ensure clue numbers match the numbers in the grid.
- [x] Display a warning to the user if there are mismatches.

## [x] Milestone 7: Intelligent Puzzle Solving

Implement the core puzzle-solving logic with enhanced UI, controls, and a more robust, app-driven solving strategy.

- [x] Create the `ClueAnswer` and `TodoItem` data models.
- [x] Update `GridCell` to track `acrossLetter` and `downLetter` separately to detect conflicts.
- [x] Configure a `gemini-2.5-flash` model with a detailed system prompt to act as a crossword "expert".
- [x] Implement an app-driven solving loop in a dedicated `PuzzleSolver` service.
- [x] Implement answer validation to check if the returned word fits the grid.
- [x] Update the UI to display the answer, confidence score, and a "-- WRONG" status for invalid answers.
- [x] Update the grid UI to color-code letters based on conflicts (red), matches (green), or single entries (black).
- [x] Implement the "Pause" and "Resume" controls.
- [ ] Implement the "Restart" button.
- [x] Implement logic to auto-pause when navigating back and to reset the solution when starting a new solve.
- [x] Add JSON-based debug output to the console for monitoring the puzzle state and prompts.

## [x] Milestone 8: Refactoring for clarity

- [x] is there any repeated logic or structure in the stepper pages that should be refactored into a base class or a mixin?
- [x] are there other things that can be refactored to make the code more clear and readable?
  