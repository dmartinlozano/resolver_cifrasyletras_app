
import 'dart:async';

const Duration timeOut = Duration(seconds: 40);

class NumbersResult{
  int? result;
  List<String>? operations = [];
  NumbersResult({this.result, this.operations});
}


List<String> findAllWords(Set<String> validWords, List<String> possibleLetters, Duration timeout) {
  List<String> results = [];
  bool stop = false;
  Timer(timeout, () {
    stop = true;
  });
  void lettersBacktrack(String currentWord, List<String> remainingLetters) {
    if (stop) throw Exception("Function timed out");
    if (currentWord.length > 4 && validWords.contains(currentWord)) {
      results.add(currentWord);
    }
    for (int i = 0; i < remainingLetters.length; i++) {
      String newWord = currentWord + remainingLetters[i];
      List<String> newRemainingLetters = List.from(remainingLetters)..removeAt(i);
      lettersBacktrack(newWord, newRemainingLetters);
    }
  }
  lettersBacktrack('', possibleLetters);
  return results;
}

List<String> sortAndFilterWords(List<String> words) {
  Set<String> uniqueWordsSet = Set<String>.from(words);
  List<String> uniqueWordsArray = uniqueWordsSet.toList();
  List<String> filteredAndSortedWords = uniqueWordsArray
      .where((word) => word.length > 4)
      .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
  return filteredAndSortedWords.take(20).toList();
}

List<NumbersResult> findClosestResults(List<int> numbers, int target, Duration timeout) {
  int closestDifference = 2147483647;
  List<NumbersResult> allClosestResults = [];
  bool stop = false;
  Timer(timeout, () {
    stop = true;
  });

  void backtrack(int currentValue, List<int> remainingNumbers, List<String> operations) {
    if (stop) throw Exception("Function timed out");
    int currentDifference = (target - currentValue).abs();

    if (currentDifference < closestDifference) {
      closestDifference = currentDifference;
      allClosestResults.clear();
      allClosestResults.add(NumbersResult(result: currentValue, operations: List.from(operations)));
    } else if (currentDifference == closestDifference) {
      allClosestResults.add(NumbersResult(result: currentValue, operations: List.from(operations)));
    }

    if (remainingNumbers.isEmpty) {
      return;
    }

    for (int i = 0; i < remainingNumbers.length; i++) {
      List<int> newRemainingNumbers = List.from(remainingNumbers);
      newRemainingNumbers.removeAt(i);

      // Suma
      backtrack(currentValue + remainingNumbers[i], newRemainingNumbers, [...operations, '$currentValue + ${remainingNumbers[i]} = ${currentValue + remainingNumbers[i]}']);
      // Resta
      if (currentValue - remainingNumbers[i] > 0) {
        backtrack(currentValue - remainingNumbers[i], newRemainingNumbers, [...operations, '$currentValue - ${remainingNumbers[i]} = ${currentValue - remainingNumbers[i]}']);
      }
      // Multiplicación
      backtrack(currentValue * remainingNumbers[i], newRemainingNumbers, [...operations, '$currentValue * ${remainingNumbers[i]} = ${currentValue * remainingNumbers[i]}']);
      // División entera (solo si el divisor no es 0 y la división es exacta)
      if (remainingNumbers[i] != 0 && (currentValue % remainingNumbers[i] == 0)) {
        backtrack(currentValue ~/ remainingNumbers[i], newRemainingNumbers, [...operations, '$currentValue / ${remainingNumbers[i]} = ${currentValue ~/ remainingNumbers[i]}']);
      }
    }
  }

  for (int i = 0; i < numbers.length; i++) {
    List<int> remainingNumbers = List.from(numbers);
    remainingNumbers.removeAt(i);
    backtrack(numbers[i], remainingNumbers, []);
  }

  return allClosestResults;
}