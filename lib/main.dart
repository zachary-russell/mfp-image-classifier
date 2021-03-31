import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(
        title: 'MFP Photo Classifier',
        key: ValueKey('app'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({required Key key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<List<dynamic>> imageData = [];
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      _parseCsv();
    });
  }

  Future<void> _writeToCsv() async {
    String csv = const ListToCsvConverter().convert(imageData);
    final path = await _localPath;
    File file = File('$path/images.csv');
    await file.writeAsString(csv);
    print('saved local file');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    // ignore: unrelated_type_equality_checks
    if (File('$path/images.csv').existsSync()) {
      print('loaded local file');
      return File('$path/images.csv');
    } else {
      throw ('foo');
    }
  }

  Future<void> _parseCsv() async {
    var file;
    try {
      final localFile = await _localFile;
      file = await localFile.readAsString();
    } catch (e) {
      print(e);
      print("loading base file");
      file = await rootBundle.loadString('assets/images.csv');
    }

    List<List<dynamic>> foo = CsvToListConverter().convert(file);
    foo.forEach((element) {
      element.length = 4;
    });
    setState(() {
      imageData = foo;
    });
    print('parsing CSV');
  }

  Future<void> _classifyImage(bool isPhoto) async {
    setState(() {
      imageData[currentIndex][3] = isPhoto;
    });
    setState(() {
      currentIndex = currentIndex + 1;
    });
    print(currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
          actions: <Widget>[
            IconButton(
              icon: Icon(
                Icons.save,
                color: Colors.white,
              ),
              onPressed: () async {
                await _writeToCsv();
                // do something
              },
            ),
            IconButton(
              icon: Icon(
                Icons.share,
                color: Colors.white,
              ),
              onPressed: () async {
                final path = await _localPath;
                Share.shareFiles(['$path/images.csv']);
                // do something
              },
            )
          ],
        ),
        body: Center(
            child: (imageData.length < 1)
                ? CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.network(
                        imageData[currentIndex][1],
                        errorBuilder:
                            (BuildContext context, Object exception, _) {
                          return Text(
                              'issue loading image, please go to the next image');
                        },
                      ),
                      Text('Is this image a photograph?'),
                      (imageData[currentIndex][3] != null)
                          ? Text(
                              'Current Choice ${imageData[currentIndex][3].toString()}')
                          : SizedBox(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                              icon: Icon(Icons.skip_previous),
                              onPressed: () {
                                if (currentIndex != 0) {
                                  setState(() {
                                    currentIndex--;
                                  });
                                }
                                ;
                              }),
                          ElevatedButton.icon(
                              onPressed: () async {
                                await _classifyImage(true);
                              },
                              icon: Icon(Icons.check),
                              label: Text('Yes')),
                          ElevatedButton.icon(
                              onPressed: () async {
                                await _classifyImage(false);
                              },
                              icon: Icon(Icons.close),
                              label: Text('No')),
                          IconButton(
                              icon: Icon(Icons.skip_next),
                              onPressed: () {
                                if (currentIndex != imageData.length - 1) {
                                  setState(() {
                                    currentIndex++;
                                  });
                                }
                                ;
                              }),
                        ],
                      )
                    ],
                  )));
  }
}
