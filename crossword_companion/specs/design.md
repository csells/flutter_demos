# Crossword Companion Design

## 1. Architecture Overview

The application follows a standard Flutter project structure, using the `firebase_ai` package for generative AI functionality. It is built to work on Android, iOS, web, and macOS. The application logic is centered around a decoupled state management system that uses three distinct `ChangeNotifier` classes to manage the UI, data, and solving process.

- **Gemini API (AI Models):** The core AI logic is powered by two Gemini models:
    - **`gemini-2.5-pro`:** A multi-modal model used for the initial, complex task of analyzing the user's crossword image(s) to infer the grid structure and all clue text.
    - **`gemini-2.5-flash`:** A faster, more focused model used for the puzzle-solving step. This model is configured with a detailed system prompt to act as a crossword-solving "expert" and is called individually for each clue.

## 2. UI/UX Design

The application uses a single screen with a vertical `Stepper` to guide the user through the workflow.

-   **Explicit State Passing:** The `CrosswordScreen` is responsible for building the `Stepper`. It determines which step is active based on the `currentStep` from the `AppStepState`. It then passes an `isActive` boolean (`isActive: appStepState.currentStep == stepIndex`) to each step's content widget.
-   **Mixin-Based Activation Logic:** To adhere to the DRY principle, the common state management logic for each stepper page is encapsulated in a `StepStateMixin`. This mixin provides the `initState` and `didUpdateWidget` lifecycle methods, which automatically call an `onActivated` method when the step becomes active. Each step's `State` class uses this mixin, ensuring activation logic runs reliably without duplicating code.
-   **Encapsulated Controls:** Each step widget is responsible for rendering its own navigation controls (e.g., "NEXT", "BACK", "SOLVE"). These controls directly call methods on the appropriate state notifiers (e.g., `appStepState.nextStep()`, `puzzleSolverState.solvePuzzle()`) to update the application's state.

### Stepper Steps:

1.  **Select Crossword Image:** The user selects one or more images of a crossword puzzle from their device's gallery or camera. The selected images are displayed, and a "NEXT" button becomes active, allowing the user to proceed.

2.  **Verify Grid Size:** Upon entering this step, the application automatically infers the grid's dimensions from the image(s), showing a loading indicator while it works. The inferred width and height are then displayed in editable text fields for user verification or correction. The user can press "NEXT" to accept the dimensions or "BACK" to re-select the image.

3.  **Verify Grid Contents:** The app displays the inferred grid of black and white squares. The user can tap any cell to toggle its color, correcting any errors from the inference step. "NEXT" and "BACK" buttons are provided for navigation.

4.  **Verify Clue Text:** The inferred "Across" and "Down" clues are displayed in two columns for user verification. The user can tap on any clue to edit its text or number. "SOLVE" and "BACK" buttons are provided.

5.  **Solve the Puzzle:**
    *   Solving begins automatically when this step is entered.
    *   The grid is displayed on the left and fills with answers in real-time, with conflicting answers in red and matching answers in green.
    *   A "To Do" list on the right shows the status of each clue, including the answer and the model's confidence score. Answers that don't fit the grid are marked as "-- WRONG".
    *   "Pause" and "Resume" buttons allow the user to control the solving process.
    *   A "Restart" button appears to the right of the "Pause/Resume" button. It clears any AI-provided data while keeping all user-entered data, and starts the solving session over from the beginning.
    *   A "START OVER" button resets the entire workflow.
    *   A "BACK" button stops the solving process, clears the partial solution from the grid, and returns to the previous step.

## 3. State Management

The `provider` package is used for state management. The architecture follows the **Separation of Concerns** principle by dividing state into three independent `ChangeNotifier` classes, which are provided to the widget tree using `MultiProvider` in `main.dart`.

-   **`AppStepState`**: Manages the UI navigation state, specifically the `currentStep` of the `Stepper`. It exposes methods like `nextStep()`, `previousStep()`, and `reset()`.
-   **`PuzzleDataState`**: Manages the lifecycle of the crossword data itself. Its responsibilities include handling image selection, triggering the AI-powered data inference, and managing user-initiated updates to the grid and clues.
-   **`PuzzleSolverState`**: Dedicated entirely to the puzzle-solving process. It manages the "to-do" list of clues, orchestrates the `PuzzleSolver` service, and handles the `isSolving`, `pause`, `resume`, and `restart` states.

This decoupled approach ensures that each part of the state is managed independently, improving maintainability and testability.

## 4. Services

- **`ImagePickerService`:** A wrapper around the `image_picker` package.
- **`GeminiService`:** This service handles all communication with the Gemini models. It is configured with the "expert" system prompt for the solver and has methods for:
    - `inferCrosswordData(images)`: Calls `gemini-2.5-pro` to analyze one or more images.
    - `solveClue(clue, length, pattern)`: Calls `gemini-2.5-flash` to get an answer and confidence score for a single clue.
    - `getWordMetadata(word)`: Calls `gemini-2.5-flash` to get metadata (e.g., part of speech, definition) for a given word.
- **`PuzzleSolver`:** Contains the business logic for the main solving loop, iterating through clues and coordinating with the `GeminiService`, `PuzzleDataState`, and `PuzzleSolverState` to solve the puzzle.

## 5. Puzzle Solving Logic

The puzzle-solving process is managed by an app-driven loop within the `PuzzleSolver` service, not by an LLM agent.

1.  **Prompt Generation:** For each clue, the app calculates the required word length and the current letter pattern (e.g., `_A_`) from the grid.
2.  **LLM Call:** It sends a focused prompt to the "expert" `gemini-2.5-flash` model containing only the clue text, length, and pattern.
3.  **Answer Validation:** The app validates the returned answer. If the length does not match the available space, the answer is marked as wrong, and the clue is queued to be retried later.
4.  **Grid Update:** Valid answers are placed on the grid. The UI uses color-coding to indicate confidence:
    - **Black:** A single, uncontested answer.
    - **Green:** Two matching answers (from an Across and Down clue) for the same cell.
    - **Red:** Two conflicting answers for the same cell.
5.  **Looping:** The app loops through all unsolved clues until the puzzle is complete, making multiple passes if necessary to retry clues that were previously answered incorrectly.

### Handling Concurrent Operations

To provide a responsive user experience and efficiently manage resources, the application must be able to cancel in-flight requests to the Gemini API. This is critical when the user pauses or restarts the solving process. The application achieves this through stream-based API calls and explicit cancellation.

-   **Stream-Based Requests:** Instead of using the single-response `generateContent` method, the `GeminiService` uses `streamGenerateContent` for solving clues. This method returns a `Stream` of response chunks.

-   **Request Cancellation:** When the service listens to this stream, it receives a `StreamSubscription` object. This object acts as a handle to the active API call and has a `cancel()` method.

-   **Encapsulated Logic:** The `GeminiService` encapsulates this entire mechanism. It holds a reference to the current `_clueSolverSubscription` and exposes a public `cancelCurrentSolve()` method. When this method is called, it cancels the active subscription, which immediately terminates the underlying network request.

-   **State Integration:** The `PuzzleSolverState` calls `geminiService.cancelCurrentSolve()` from its `pauseSolving` and `restartSolving` methods. This ensures that whenever the user interrupts the solver, the active LLM request is instantly canceled, preventing wasted processing and ensuring no stale data can interfere with the new state. The `solveClue` method in the service is designed to handle this cancellation gracefully, returning a `null` value which the `PuzzleSolver` already handles.

## 6. Data Models

- **`AppStepState`**: Manages the current step of the UI stepper.
- **`PuzzleDataState`**: Manages the crossword puzzle data, including images, grid structure, and clues.
- **`PuzzleSolverState`**: Manages the state of the puzzle-solving process.
- **`CrosswordData`:** The top-level model holding the entire puzzle's state.
- **`CrosswordGrid`:** Holds the grid's dimensions and a list of `GridCell` objects.
- **`GridCell`:** Represents a single cell. Crucially, it contains separate `acrossLetter`, `downLetter`, and `userLetter` fields to track answers from both directions and user edits, and to detect conflicts.
- **`Clue`:** Represents a single clue.
- **`ClueAnswer`:** A model to hold the string `answer` and double `confidence` returned by the LLM.
- **`TodoItem`:** Represents a clue in the UI list on the solver page, holding the clue's description, its solving status, the `ClueAnswer`, and an `isWrong` flag.

## 7. Project Structure

The project follows the standard structure outlined in `GEMINI.md`.