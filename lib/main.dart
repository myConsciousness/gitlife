import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:github/github.dart';
import 'package:http/http.dart';
import 'package:oauth2_client/github_oauth2_client.dart';
import 'package:oauth2_client/oauth2_helper.dart';

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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String content = '';

  Future<void> _incrementCounter() async {
    OAuth2Helper oauth2Helper = OAuth2Helper(
      GitHubOAuth2Client(
        redirectUri: 'org.gitlife.oauth://callback/',
        customUriScheme: 'org.gitlife.oauth',
      ),
      grantType: OAuth2Helper.authorizationCode,
      clientId: const String.fromEnvironment('github_client_id'),
      clientSecret: const String.fromEnvironment('github_client_secret'),
      scopes: ['repo', 'user'],
    );

    final authorized = await oauth2Helper.getToken();

    final github = GitHub(
      auth: Authentication.withToken(authorized!.accessToken),
    );

    final me = await github.users.getCurrentUser();
    await github.repositories.createFile(
      RepositorySlug(
        me.login ?? '',
        'myConsciousness-git-life',
      ),
      CreateFile(
        path: 'test.md',
        content: base64Encode('test'.codeUnits),
        message: 'test',
        committer: CommitUser(
          me.login,
          me.email,
        ),
      ),
    );

    final contents = await github.repositories.getContents(
      RepositorySlug(
        me.login ?? '',
        'myConsciousness-git-life',
      ),
      'diary/src/2022/02/03',
    );

    final downloadedContent = await get(
      Uri.parse(contents.tree!.first.downloadUrl ?? ''),
    );

    super.setState(() {
      content = downloadedContent.body;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 60),
          child: MarkdownBody(
            data: content,
            selectable: true,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _incrementCounter();
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
