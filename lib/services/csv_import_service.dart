import 'package:csv/csv.dart';
import 'package:slidequiz/models/question.dart';
import 'package:slidequiz/models/choice.dart';
import 'package:uuid/uuid.dart';

class ImportResult {
  final List<Question> questions;
  final List<Choice> choices;
  final List<String> errors;

  ImportResult({
    required this.questions,
    required this.choices,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
}

class CsvImportService {
  static const List<String> requiredHeaders = [
    'TYPE',
    'QUESTION',
    'CHOICE_A',
    'CHOICE_B',
    'CHOICE_C',
    'CHOICE_D',
    'CHOICE_E',
    'CHOICE_F',
    'ANSWER',
    'TIMER',
  ];

  static const String colType = 'TYPE';
  static const String colQuestion = 'QUESTION';
  static const String colChoiceA = 'CHOICE_A';
  static const String colChoiceB = 'CHOICE_B';
  static const String colChoiceC = 'CHOICE_C';
  static const String colChoiceD = 'CHOICE_D';
  static const String colChoiceE = 'CHOICE_E';
  static const String colChoiceF = 'CHOICE_F';
  static const String colAnswer = 'ANSWER';
  static const String colTimer = 'TIMER';
  // Note: POINTS header was mentioned in instructions for Identification ("Points (if applicable) must be an integer...")
  // but not in the main header list: [TYPE, QUESTION, CHOICE_A... ANSWER, TIMER].
  // I will check if it exists, otherwise default to 1.

  Future<ImportResult> importQuestions(String csvContent, String quizId) async {
    final List<Question> questions = [];
    final List<Choice> allChoices = [];
    final List<String> errors = [];

    try {
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
        csvContent,
        eol: '\n',
        shouldParseNumbers: false,
      );

      if (rows.isEmpty) {
        return ImportResult(
          questions: [],
          choices: [],
          errors: ['CSV is empty'],
        );
      }

      // 1. Validate Headers
      final headers = rows.first
          .map((e) => e.toString().trim().toUpperCase())
          .toList();

      // Check for missing required headers
      for (final req in requiredHeaders) {
        if (!headers.contains(req)) {
          return ImportResult(
            questions: [],
            choices: [],
            errors: ['Missing required header: $req'],
          );
        }
      }

      final typeIdx = headers.indexOf(colType);
      final questionIdx = headers.indexOf(colQuestion);
      final choiceAIdx = headers.indexOf(colChoiceA);
      final choiceBIdx = headers.indexOf(colChoiceB);
      final choiceCIdx = headers.indexOf(colChoiceC);
      final choiceDIdx = headers.indexOf(colChoiceD);
      final choiceEIdx = headers.indexOf(colChoiceE);
      final choiceFIdx = headers.indexOf(colChoiceF);
      final answerIdx = headers.indexOf(colAnswer);
      final timerIdx = headers.indexOf(colTimer);

      // Optional points header if present
      final pointsIdx = headers.indexOf('POINTS');

      // 2. Process Rows
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty))
          continue;

        // Helper to safely get value
        String getValue(int idx) {
          if (idx >= row.length) return '';
          final val = row[idx];
          if (val == null) return '';
          return val.toString().trim();
        }

        final type = getValue(typeIdx);
        final questionText = getValue(questionIdx);
        final answer = getValue(answerIdx);
        final timerStr = getValue(timerIdx);
        final choiceTexts = [
          getValue(choiceAIdx),
          getValue(choiceBIdx),
          getValue(choiceCIdx),
          getValue(choiceDIdx),
          getValue(choiceEIdx),
          getValue(choiceFIdx),
        ];

        // Basic Validation
        if (type.isEmpty) {
          errors.add('Row ${i + 1}: TYPE is required.');
          continue;
        }
        if (questionText.isEmpty) {
          errors.add('Row ${i + 1}: QUESTION is required.');
          continue;
        }

        // Timer validation
        int? timer;
        if (timerStr.isNotEmpty) {
          timer = int.tryParse(timerStr);
          if (timer == null) {
            errors.add('Row ${i + 1}: TIMER must be an integer.');
            continue;
          }
        }

        // Points validation (default 1)
        int points = 1;
        if (pointsIdx != -1) {
          final pointsStr = getValue(pointsIdx);
          if (pointsStr.isNotEmpty) {
            final p = int.tryParse(pointsStr);
            if (p == null) {
              errors.add('Row ${i + 1}: POINTS must be an integer.');
              continue;
            }
            points = p;
          }
        }

        // Type-Specific Validation
        final validTypes = [
          Question.typeIdentification,
          Question.typeMultipleChoice,
          Question.typeTrueFalse,
          Question.typeEnumeration,
        ];

        // Normalize type check (case-insensitive match against known types)
        final matchedType = validTypes.firstWhere(
          (t) => t.toLowerCase() == type.toLowerCase(),
          orElse: () => '',
        );

        if (matchedType.isEmpty) {
          errors.add('Row ${i + 1}: Invalid TYPE "$type".');
          continue;
        }

        String finalAnswer = answer;
        List<String>? acceptedAnswers;
        final List<Choice> questionChoices = [];

        if (matchedType == Question.typeIdentification) {
          // Rule: ANSWER must be provided
          if (answer.isEmpty) {
            errors.add('Row ${i + 1}: ANSWER is required for Identification.');
            continue;
          }
          // Rule: Ignore choices (we just don't process them)
        } else if (matchedType == Question.typeMultipleChoice) {
          // Rule: Min 2, max 6 non-empty choices
          final nonEmptyChoices = choiceTexts
              .where((c) => c.isNotEmpty)
              .toList();
          if (nonEmptyChoices.length < 2) {
            errors.add(
              'Row ${i + 1}: Multiple Choice requires at least 2 choices.',
            );
            continue;
          }

          // Rule: ANSWER must match one of the choices
          // We'll store choices with labels A, B, C... to make it robust?
          // Or does the user expect the ANSWER column to contain the TEXT of the answer or the LETTER?
          // "The ANSWER must match one of the provided choices." implies content match usually.
          // However, typically in these formats ANSWER might be 'A' or 'Option Text'.
          // Let's assume strict content match first as it's safer, but also check if answer is A/B/C etc.

          // Let's create Choice objects
          final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
          bool answerFound = false;

          for (int c = 0; c < 6; c++) {
            if (choiceTexts[c].isNotEmpty) {
              final choice = Choice(
                questionId: '', // Set later
                label: labels[c],
                text: choiceTexts[c],
                order: c,
              );
              questionChoices.add(choice);

              // Check if answer matches text or label
              if (answer == choice.text || answer == choice.label) {
                answerFound = true;
                // Standardize answer to be the choice text for consistency with model?
                // Or keep logical link? model uses `answer` string.
                // Usually for MC, model might store the text.
                finalAnswer = choice.text;
              }
            }
          }

          if (!answerFound) {
            errors.add(
              'Row ${i + 1}: ANSWER must match one of the provided choices.',
            );
            continue;
          }
        } else if (matchedType == Question.typeTrueFalse) {
          // Rule: ANSWER must be True or False (case-insensitive)
          final lower = answer.toLowerCase();
          if (lower != 'true' && lower != 'false') {
            errors.add(
              'Row ${i + 1}: True/False answer must be "True" or "False".',
            );
            continue;
          }
          // Normalize to capitalized
          finalAnswer = lower == 'true' ? 'True' : 'False';

          // Rule: Ignore choices
        } else if (matchedType == Question.typeEnumeration) {
          // Rule: ANSWER contains enumerated answers directly
          if (answer.isEmpty) {
            errors.add('Row ${i + 1}: ANSWER is required for Enumeration.');
            continue;
          }
          // Split by some delimiter? Or is the whole cell one answer and we expect multiple rows?
          // "The ANSWER field must contain the enumerated answers directly."
          // "Answers may include programming symbols... preserving formatting"
          // Usually Enumeration has multiple correct answers.
          // If it's a single cell, maybe they are comma separated? Or newline?
          // The prompt says "Answers may include... symbols like , ;".
          // If the delimiters are part of the content, we can't easily split.
          // However, usually for CSV import, we might assume one row = one question.
          // If Enumeration has multiple answers, maybe they are pipe separated?
          // OR maybe acceptedAnswers is just this one string?
          // Actually `Question` model has `List<String>? acceptedAnswers`.
          // Let's assume for now the ANSWER column contains all accepted answers, maybe separated by `|`
          // OR just treat the whole thing as one for now if uncertain, BUT
          // Prompt says "Question type Enumeration... Answers field must contain enumerated answers directly"
          // Let's split by `|` (pipe) as a safe convention for lists in CSV, or just semicolon if usually distinct?
          // Given "programming symbols... ;", semicolon is risky.
          // Let's strictly follow: "The ANSWER field must contain the enumerated answers directly."
          // If multiple answers are required, maybe they are entered as `Answer1|Answer2`?
          // I will use `|` as the delimiter for multiple accepted answers in Enumeration.

          acceptedAnswers = answer
              .split('|')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
          finalAnswer = answer; // Keep raw string too?
        }

        // Construct Question
        final questionId = const Uuid().v4();
        final q = Question(
          id: questionId,
          quizId: quizId,
          type: matchedType,
          questionText: questionText,
          answer: finalAnswer,
          points: points,
          timerSeconds: timer,
          acceptedAnswers: acceptedAnswers,
        );

        questions.add(q);

        // Link choices
        for (final c in questionChoices) {
          c.questionId = questionId;
          allChoices.add(c);
        }
      }
    } catch (e) {
      errors.add('CSV Parsing Error: $e');
    }

    return ImportResult(
      questions: questions,
      choices: allChoices,
      errors: errors,
    );
  }
}
