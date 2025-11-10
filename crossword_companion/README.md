# Crossword Companion

The Crossword Companion is a Flutter sample app demonstrating an intelligent,
app-driven workflow using Flutter and the Google Gemini API through Firebase.
The app allows users to take or upload a picture of a crossword puzzle, verifies
the puzzle's structure and clues with the user, and then uses Gemini to solve it
 in real-time.

This project is an open-source sample intended to showcase how easy it is to
build an AI-powered app in Flutter beyond simple chat, allowing the user to step
in and direct the model as appropriate.

The Crossword Companion app is supported where Firebase is support: Android,
iOS, web and macOS.

## How It Works

The application uses a multi-modal Gemini model (`gemini-2.5-pro`) to analyze an
image of a crossword puzzle. It then uses a separate model (`gemini-2.5-flash`),
configured with a detailed system prompt to act as a crossword "expert", to
solve the puzzle. Additionally, the app integrates with an external dictionary API (dictionaryapi.dev) to provide word metadata (e.g., part of speech) when requested by the Gemini model during the solving process. This integration allows the Gemini model to verify grammatical constraints, such as part of speech, for potential answers, thereby improving the accuracy and relevance of its solutions.

The app itself drives the solving process. For each clue, it determines the
required word length and the current known letter pattern from the grid. It then
sends this focused context to the expert model. The app validates the answer,
updates the grid, and automatically retries clues that were answered
incorrectly, creating a robust feedback loop.

<video controls src="readme/screen-recording.mov" title="Title"></video>

## Getting Started

### Prerequisites

- A Firebase project.
- The Flutter SDK installed.

### Installation

1.  Clone the repository.
2.  Configure your Firebase project by running the following command at the
    project root and following the instructions:

    ```bash
    flutterfire config
    ```

    This will connect your Flutter application to your Firebase project, which
    is necessary to use the Gemini API.

3.  Run the application on your desired platform:

    ```bash
    flutter run
    ```

## Functionality

This application guides the user through a step-by-step workflow to solve a
crossword puzzle from an image.

1.  **Select Crossword Image:** The user can select an image of a crossword
    puzzle from their device's gallery or by taking a photo.

2.  **Verify Grid Size:** The application uses Gemini to infer the information
    about the crossword. On this step, the app shows the inferred grid
    dimensions (width and height) and allows the user to make corrections.

3.  **Verify Grid Contents:** The app displays the inferred grid and the user
    can tap on cells to toggle them between inactive, blank or numbered.

4.  **Verify Clue Text:** The inferred "Across" and "Down" clues are displayed,
    and the user can edit them for accuracy. After this step, the app validates
    that the user's edits on the grid have resulted in a consistent puzzle, e.g.
    there are numbers on the grid that match the clues, etc.

5.  **LLM-based Solving:** The application uses Gemini model to solve the
    puzzle. The app manages the solving loop, sending focused prompts for each
    clue. The UI displays the model's confidence and color-codes letters to show
    conflicts, allowing the user to watch the puzzle being solved in real-time.

    The user may pause or resume the solving process as well as start over with
    a new puzzle as they choose.