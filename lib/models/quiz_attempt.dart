class QuizAttempt {
  final String questionId;
  String userAnswer;
  bool isCorrect;
  int pointsEarned;

  QuizAttempt({
    required this.questionId,
    this.userAnswer = '',
    this.isCorrect = false,
    this.pointsEarned = 0,
  });

  void checkAnswer(String correctAnswer, int questionPoints) {
    // Normalize answers for comparison (trim and lowercase)
    final normalizedUserAnswer = userAnswer.trim().toLowerCase();
    final normalizedCorrectAnswer = correctAnswer.trim().toLowerCase();

    isCorrect = normalizedUserAnswer == normalizedCorrectAnswer;
    pointsEarned = isCorrect ? questionPoints : 0;
  }
}
