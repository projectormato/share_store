import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_scraper/web_scraper.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Share Store',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final textEditingController = TextEditingController();
  final firestoreInstance = Firestore.instance;

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Share Store')),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreInstance.collection('store').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildContainer(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildContainer(BuildContext context,
      List<DocumentSnapshot> snapshotList) {
    return Container(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(hintText: 'URLを共有しよう'),
                controller: textEditingController,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 20.0),
                children: snapshotList
                    .map((snapshot) => _buildListItem(context, snapshot))
                    .toList(),
              ),
            )
          ],
        ));
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        final webScraper = WebScraper('https://example.com');
        if (await webScraper.loadWebPage('/')) {
          final elements = webScraper.getPageContent();
          print(elements);
        }

        await firestoreInstance
            .collection("store")
            .add({'name': textEditingController.text});

        textEditingController.clear();
      },
      child: Icon(Icons.add),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot snapshot) {
    assert(snapshot.data['name'] != null);
    final name = snapshot.data['name'];

    return Padding(
      key: ValueKey(name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
            title: Text(name),
            onTap: () {
              // TODO: 詳細ページへ繊維など(無いかも)
              print(name + ' がtapされたよ');
            }),
      ),
    );
  }
}
