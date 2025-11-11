# Crossword Companion Requirements

## 1. Project Overview

The application will be an open-source sample hosted on GitHub in the flutter org. It aims to demonstrate the use of Flutter, Firebase AI Logic, and Gemini to produce an agentic workflow that can solve a small crossword puzzle (one with a size under 10x10).

## 2. Target Platforms

The application will be built with Flutter and run on Android, iOS, web, and macOS.

## 3. User Interface and Experience (UI/UX)

The workflow from start to completed puzzle is presented in a single screen with individual components representing the steps of the workflow and an indicator for overall progress. At each step of the workflow, the UI should offer users the opportunity to advance or (for all steps beyond the first) roll back to a previous step.

## 4. Agentic Workflow Steps

The application will guide the user through the following steps:

### 4.1. Crossword Image Input
- The app allows the user to select one or more images of an empty (unsolved) crossword puzzle from the camera or image picker. This allows for separate images of the grid and clues.
- Once chosen, the app should display the image(s), and allow the user to accept them or choose different image(s).

*Example Grid Image:*
(The user provided an image of a grid-based crossword puzzle at ![example crossword puzzle screenshot](example-screenshot.png)

### 4.2. Grid Size Inference & Verification
- The agent should infer the crossword dimensions from the crossword image(s).
- The agent will present the inferred height and width values to the user for verification and/or modification before continuing.

### 4.3. Grid Contents Inference & Verification
- The agent should infer the contents of the crossword grid (cell colors, presence of numbers for answers) from the crossword image(s).
- The inferred contents will be presented to the user for verification/modification.

### 4.4. Clue Text Inference & Verification
- The agent should infer the crossword clue text from the crossword image(s).
- The inferred clues will be presented to the user for verification.
- The user should have the option of editing a clue's number, direction, and/or text prior to advancing the workflow.

### 4.5. Puzzle Solving
- The application should solve the puzzle by filling in answers one at a time.
- The UI should animate this process so the user can observe progress.
- The UI will display the model's confidence in each answer and visually flag answers that are invalid or conflict with other answers.
- The app will automatically backtrack and retry clues that were answered incorrectly, using the updated state of the grid to inform the new attempt.
- The UI should offer the user a mechanism to pause and resume the solving process.
- The UI should offer the user a mechanism to restart the solving process, which will clear AI-provided data, keep user-entered data, and start the solving process over from the beginning.

### 4.6. Finished State
- Once the puzzle is solved, the application will display a "finished" message.
- The completed grid will be displayed.
- A button will be available to restart the workflow, erasing all current state.
