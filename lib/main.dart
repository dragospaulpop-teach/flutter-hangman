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
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  String word = '';
  String guessed = '';
  int wrongTries = 0;
  int maxTries = 8;
  bool loading = false;
  List<String> hints = [];
  double wordLength = 15;
  bool isPlaying = false;

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
          isPlaying = true;
        });
      } else {
        throw Exception('Failed to load word');
      }
    } catch (e) {
      setState(() {
        loading = false;
        isPlaying = false;
      });
      ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Uff, there was an error obtaiing the word... Bummer!'),
        ),
      );
    }
  }

  void guessLetter(String letter) {
    if (!isPlaying) return;
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
      setState(() {
        guessed = word;
        isPlaying = false;
      });

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
      setState(() {
        isPlaying = false;
      });

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
      key: scaffoldKey,
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: const Text('Let\'s play a game!'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height -
              (MediaQuery.of(context).padding.top + kToolbarHeight),
          padding: const EdgeInsets.all(6),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Image(
                      image: AssetImage('assets/jigsaw.png'),
                      height: 200,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          const Text(
                            'Push the button to get a random word and play hangman',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'I do hope you hang, you know?',
                            style: TextStyle(
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              color: Colors.red[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Difficulty: '),
                        Text('Chars: ${wordLength.round().toString()}, '),
                        Text('Tries: $maxTries'),
                      ],
                    ),
                    Slider(
                      value: wordLength,
                      max: 15,
                      min: 4,
                      onChanged: (double value) => setDifficulty(value),
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
                      onPressed: word.isEmpty || !isPlaying
                          ? null
                          : () => provideHint(),
                      icon: Icon(
                        Icons.help,
                        color: word.isEmpty || !isPlaying
                            ? Colors.grey
                            : Colors.green,
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                loading
                    ? const LinearProgressIndicator(
                        minHeight: 20,
                      )
                    : WordLetters(word: guessed),
                const SizedBox(
                  height: 30,
                ),
                word.isNotEmpty && !loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            const Image(
                              image: AssetImage('assets/alive.png'),
                              height: 40,
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
                            const Image(
                              image: AssetImage('assets/dead.png'),
                              height: 40,
                            ),
                          ])
                    : const Text(''),
                const SizedBox(
                  height: 20,
                ),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.blueGrey,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              List.generate(word.length, (i) => WordLetter(word: word, i: i)),
        ),
      ),
    );
  }
}

class WordLetter extends StatelessWidget {
  const WordLetter({
    super.key,
    required this.word,
    required this.i,
  });

  final String word;
  final int i;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 0,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.blueGrey),
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

  late final List<String> letters;

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
  final List<String> _pressedLetters = [];

  letterPressed(String letter) {
    widget.guessLetter(letter.toLowerCase());

    setState(() {
      _pressedLetters.add(letter);
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
                    backgroundColor: _pressedLetters.contains(letter)
                        ? Colors.grey
                        : Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _pressedLetters.contains(letter)
                      ? null
                      : () => letterPressed(letter),
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
