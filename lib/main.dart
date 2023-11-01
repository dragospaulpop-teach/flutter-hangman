import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const MaterialApp(home: MainApp()),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  String word = '';
  String guessed = '';
  int wrongTries = 0;
  int maxTries = 8;
  bool loading = false;
  List<String> hints = [];
  double wordLength = 15;

  void getWord() async {
    setState(() {
      word = '';
      guessed = '';
      loading = true;
    });

    try {
      final String url =
          'https://random-word-api.herokuapp.com/word?length=${wordLength.round()}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        final String firstWord = json.first;

        setState(() {
          word = firstWord;
          loading = false;
          wrongTries = 0;
          guessed = ''.padRight(word.length, ' ');
          hints = [];
        });
      } else {
        throw Exception('Failed to load word');
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
        ),
      );
    }
  }

  void guessLetter(String letter) {
    if (word.contains(letter)) {
      int index = word.indexOf(letter);

      while (index != -1) {
        List list = guessed.split('');
        list[index] = letter;
        guessed = list.join();
        index = word.indexOf(letter, index + 1);
      }
    } else {
      wrongTries++;
    }

    setState(() {
      guessed = guessed;
      wrongTries = wrongTries;
    });

    checkGameOver();
  }

  void checkGameOver() {
    bool isGuessed = guessed == word;
    bool isLoser = !isGuessed && wrongTries >= maxTries;
    bool isWinner = isGuessed && wrongTries < maxTries;

    if (isLoser) {
      guessed = word;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Game over'),
          content: const Text('You lost!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(Colors.red),
              ),
              child: const Text('Grrr...'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                getWord();
              },
              child: const Text('Play again'),
            ),
          ],
        ),
      );
    } else if (isWinner) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You won!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                getWord();
              },
              child: const Text('Play again'),
            ),
          ],
        ),
      );
    }
  }

  void provideHint() {
    List<String> letters = word.split('');
    letters.shuffle();
    String letter = letters.first;

    while (hints.contains(letter)) {
      letters.shuffle();
      letter = letters.first;
    }

    hints.add(letters.first);
    wrongTries++;

    setState(() {
      hints = hints;
      wrongTries = wrongTries;
    });

    guessLetter(letters.first);
  }

  void setDifficulty(double value) {
    setState(() {
      wordLength = value;
      maxTries = (wordLength / 2).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Let\'s play a game!'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height - 80.0,
          color: Colors.grey[300],
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Image.network(
                  'https://images.fineartamerica.com/images/artworkimages/medium/3/i-want-to-play-a-game-jigsaw-saw-movie-remake-posters-transparent.png',
                  height: 200,
                ),
                const Text(
                  'Push the button to get a random word and play hangman',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  'I do hope you hang, you know?',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                Column(
                  children: [
                    const SizedBox(height: 6),
                    const Text('Difficulty:'),
                    Slider(
                      value: wordLength,
                      max: 15,
                      min: 4,
                      onChanged: (double value) => setDifficulty(value),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Chars: ${wordLength.round().toString()}, '),
                        Text('Tries: $maxTries'),
                      ],
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: getWord,
                      label: const Text('Get a random word'),
                      icon: const Icon(Icons.touch_app),
                    ),
                    IconButton(
                      onPressed: word.isEmpty ? null : () => provideHint(),
                      icon: Icon(
                        Icons.help,
                        color: word.isEmpty ? Colors.grey : Colors.green,
                      ),
                    )
                  ],
                ),
                loading
                    ? const LinearProgressIndicator(
                        minHeight: 20,
                      )
                    : WordLetters(word: guessed),
                word.isNotEmpty && !loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Image.network(
                              'https://cdn-icons-png.flaticon.com/512/1142/1142172.png',
                              height: 30,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: wrongTries / maxTries,
                                  color: Colors.red,
                                  backgroundColor: Colors.grey[300],
                                  minHeight: 20,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Image.network(
                              'https://cdn-icons-png.flaticon.com/512/2230/2230897.png',
                              height: 30,
                            )
                          ])
                    : const Text(''),
                word.isNotEmpty && !loading
                    ? KeyboardWidget(
                        guessLetter: guessLetter,
                      )
                    : const Text('')
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WordLetters extends StatelessWidget {
  const WordLetters({
    super.key,
    required this.word,
  });

  final String word;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < word.length; i++)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 0,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: const Border(
                  bottom: BorderSide(color: Colors.black),
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    word[i],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class KeyboardWidget extends StatelessWidget {
  const KeyboardWidget({super.key, required this.guessLetter});

  final void Function(String letter) guessLetter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        KeyboardRow(rowNumber: 1, guessLetter: guessLetter),
        KeyboardRow(rowNumber: 2, guessLetter: guessLetter),
        KeyboardRow(rowNumber: 3, guessLetter: guessLetter)
      ],
    );
  }
}

class KeyboardRow extends StatefulWidget {
  final void Function(String letter) guessLetter;

  final List<String> letters;

  KeyboardRow({
    Key? key,
    required rowNumber,
    required this.guessLetter,
  })  : letters = _getLetters(rowNumber),
        super(key: key);

  static List<String> _getLetters(int rowNumber) {
    switch (rowNumber) {
      case 1:
        return ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
      case 2:
        return ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
      case 3:
        return ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];
      default:
        return [];
    }
  }

  @override
  State<KeyboardRow> createState() => _KeyboardRowState();
}

class _KeyboardRowState extends State<KeyboardRow> {
  List<String> _letters = [];

  letterPressed(String letter) {
    widget.guessLetter(letter.toLowerCase());
    _letters.add(letter);

    setState(() {
      _letters = _letters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double totalWidth = constraints.maxWidth;
      final double keyWidth = totalWidth / 10 - 4;

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (String letter in widget.letters)
            Padding(
              padding: const EdgeInsets.all(2.0),
              child: SizedBox(
                width: keyWidth,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: _letters.contains(letter)
                        ? Colors.grey
                        : Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => letterPressed(letter),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}
