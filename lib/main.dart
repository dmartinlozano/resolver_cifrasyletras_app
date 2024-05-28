import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'banner_widget.dart';
import 'utils.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  late Set<String> validWords;
  List<String> resultWords = [];
  List<String> resultNumbers = [];
  bool _isLoading = false;

  final TextEditingController _lettersController = TextEditingController();
  final TextEditingController _inputNumberController = TextEditingController();
  final TextEditingController _expectedNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/0_palabras_todas_no_conjugaciones.txt').then(
        (text) => validWords = text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toSet());
  }

  Widget _body() {
    return TabBarView(
      children: [
      Card(
        elevation: 4,
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 300,
                child: TextField(
                  controller: _lettersController,
                  maxLength: 9,
                  decoration: const InputDecoration(
                    labelText: 'Solo letras (sin espacios)',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    resultWords = [];
                  });
                  String text = _lettersController.text;
                  if (text.length > 4 && text.length <= 9){
                    try{
                      List<String> allWords = findAllWords(
                        validWords,
                        _lettersController.text
                              .replaceAll(RegExp(r'[^a-zA-Z ]'), '')
                              .toLowerCase()
                              .split(''),
                        timeOut);
                      setState(() {
                        _isLoading = false;
                        resultWords = sortAndFilterWords(allWords);
                        if (resultWords.isEmpty){
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('No se puede obtener ninguna palabra de longitud superior a 4'),
                          ));
                        }
                      });
                    }catch (error) {
                      setState(() {
                        _isLoading = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('No se ha podido encontrar ninguna palabra pasados 40 segundos.'),
                      ));
                    }
                  }else{
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('La longitud del texto ha de ser mayor de 4 y menor de 10'),
                    ));
                  }
                  
                },
                child: const Text('Procesar'),
              ),
              _isLoading
              ?  const Center(
                  child: CircularProgressIndicator(),
                )
              : (resultWords.isNotEmpty)
                ? Expanded(
                    child: ListView.builder(
                      itemCount: resultWords.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(resultWords[index]),
                        );
                      },
                    ),
                )
                : Container(),
            ],
          )
        )
      ),
      Card(
        elevation: 4,
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _inputNumberController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Numeros (separados por blancos)',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 300,
                    child: TextField(
                      controller: _expectedNumberController,
                      maxLength: 19,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Numero a obtener',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        resultNumbers = [];
                      });
                      try{
                        List<int> numberString = _inputNumberController.text.trim().split(' ')
                            .where((s) => int.tryParse(s) != null)
                            .map((s) => int.parse(s))
                            .toList();
                        if (numberString.length != 6){
                          _isLoading = false;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Por favor, introduzca 6 números separados por espacio'),
                          ));
                        }else{
                          List<NumbersResult> result = findClosestResults(
                            numberString,
                            int.parse(_expectedNumberController.text.trim().replaceAll(RegExp(r'[^0-9]'), '')),
                            timeOut
                          );
                          setState(() {
                            _isLoading = false;
                            if (result.isEmpty){
                              resultNumbers = [];
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('No se puede obtener ningún número'),
                              ));
                            }else{
                              NumbersResult shortestResult = result.reduce((curr, next) => curr.operations!.length <= next.operations!.length ? curr : next);
                              resultNumbers = [shortestResult.result.toString(), ...shortestResult.operations ?? []];
                            }
                          });
                        }
                      }catch (error) {
                        setState(() {
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('No se ha podido encontrar ningún numero pasados 40 segundos.'),
                        ));
                      }
                    },
                    child: const Text('Procesar'),
                  ),
                  _isLoading
                  ?  const Center(
                      child: CircularProgressIndicator(),
                    )
                  : (resultNumbers.isNotEmpty)
                    ? Expanded(
                      child: ListView.builder(
                        itemCount: resultNumbers.length,
                        itemBuilder: (context, index) {
                          Color textColor = index == 0 ? Colors.red : Colors.black;
                          return ListTile(
                            title: Text(resultNumbers[index], style: TextStyle(color: textColor))
                          );
                        },
                      ),
                    )
                    : Container(),
                ],
              )))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Resolver Cifras y Letras"),
          bottom: const TabBar(
              tabs: [
                Tab(text: "Letras"),
                Tab(text: "Cifras"),
              ],
            )
        ),
        body: (MediaQuery.of(context).orientation == Orientation.portrait)
            ? SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child:                       
                        BannerWidget(
                          child: _body()
                        ),
                    )
                  ],
                ),
              )
            : BannerWidget(
                child: SingleChildScrollView(
                  child: _body()
                ),
            )
      )
    );
  }
}
