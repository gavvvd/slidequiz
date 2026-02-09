import 'package:flutter_test/flutter_test.dart';
import 'package:slidequiz/services/csv_import_service.dart';
import 'package:slidequiz/models/question.dart';

void main() {
  final service = CsvImportService();

  test('Valid Import', () async {
    const csvData = '''
TYPE,QUESTION,CHOICE_A,CHOICE_B,CHOICE_C,CHOICE_D,CHOICE_E,CHOICE_F,ANSWER,TIMER
Identification,Who is the user?,Option A,,,,,,Gav,30
Multiple Choice,Choose A,A,B,,,,,A,20
True or False,Is this true?,,,,,,,True,10
Enumeration,List items,,,,,,,Item1|Item2,60
''';

    final result = await service.importQuestions(csvData, 'quiz-1');

    expect(result.errors, isEmpty);
    expect(result.questions.length, 4);

    // Check Identification
    expect(result.questions[0].type, Question.typeIdentification);
    expect(result.questions[0].answer, 'Gav');

    // Check Multiple Choice
    expect(result.questions[1].type, Question.typeMultipleChoice);
    expect(result.questions[1].answer, 'A');

    // Check True/False
    expect(result.questions[2].type, Question.typeTrueFalse);
    expect(result.questions[2].answer, 'True');

    // Check Enumeration
    expect(result.questions[3].type, Question.typeEnumeration);
    expect(result.questions[3].answer, 'Item1|Item2');
    // Note: acceptedAnswers parsing depends on split logic in service
    expect(
      result.questions[3].acceptedAnswers,
      containsAll(['Item1', 'Item2']),
    );
  });

  test('Invalid Import - Missing Answer', () async {
    const csvData = '''
TYPE,QUESTION,CHOICE_A,CHOICE_B,CHOICE_C,CHOICE_D,CHOICE_E,CHOICE_F,ANSWER,TIMER
Identification,Who?,,,,,,,
''';
    final result = await service.importQuestions(csvData, 'quiz-1');
    expect(result.errors.length, 1);
    expect(result.errors.first, contains('ANSWER is required'));
  });

  test('Invalid Import - Not Enough Choices', () async {
    const csvData = '''
TYPE,QUESTION,CHOICE_A,CHOICE_B,CHOICE_C,CHOICE_D,CHOICE_E,CHOICE_F,ANSWER,TIMER
Multiple Choice,Choose,,,,,,,A,
''';
    final result = await service.importQuestions(csvData, 'quiz-1');
    expect(result.errors.length, 1);
    expect(result.errors.first, contains('requires at least 2 choices'));
  });

  test('Invalid Import - Answer Not In Choices', () async {
    const csvData = '''
TYPE,QUESTION,CHOICE_A,CHOICE_B,CHOICE_C,CHOICE_D,CHOICE_E,CHOICE_F,ANSWER,TIMER
Multiple Choice,Choose,A,B,,,,,C,
''';
    final result = await service.importQuestions(csvData, 'quiz-1');
    expect(result.errors.length, 1);
    expect(
      result.errors.first,
      contains('ANSWER must match one of the provided choices'),
    );
  });
}
