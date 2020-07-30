import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_scraper/web_scraper.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoder/geocoder.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // MEMO: 渋谷駅
  final LatLng _center = const LatLng(35.6580382, 139.6994471);
  final Map<String, Marker> _markers = {};

  Future<void> _onMapCreated(GoogleMapController controller) async {
    final icon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(size: Size(32, 32)), 'assets/marker.png');
    List<Store> stores = [];
    final documents = await firestoreInstance
        .collection('store')
        .snapshots()
        .map((event) => event.documents)
        .first;

    for (int i = 0; i < documents.length; i++) {
      final data = documents[i].data;
      var address =
          await Geocoder.local.findAddressesFromQuery(data['address']);
      var coordinates = address.first.coordinates;
      print("$coordinates");
      stores.add(Store(data['name'], data['address'], coordinates.latitude,
          coordinates.longitude));
    }

    setState(() {
      _markers.clear();
      for (var store in stores) {
        final marker = Marker(
          markerId: MarkerId(store.name),
          position: LatLng(store.latitude, store.longitude),
          icon: icon,
          infoWindow: InfoWindow(
            title: store.name,
            snippet: store.address,
            onTap: () =>  _launchURL(store.address)
          ),
        );
        _markers[store.name] = marker;
      }
    });
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.add_circle_outline)),
                Tab(icon: Icon(Icons.map)),
              ],
            ),
            title: Text('Share Store')),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildAddBody(context),
            _buildMapBody(context),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildAddBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreInstance.collection('store').orderBy('sort').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return LinearProgressIndicator();

        return _buildContainer(context, snapshot.data.documents);
      },
    );
  }

  Widget _buildContainer(
      BuildContext context, List<DocumentSnapshot> snapshotList) {
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

  Widget _buildMapBody(BuildContext context) {
    return GoogleMap(
      myLocationButtonEnabled: false,
      zoomGesturesEnabled: true,
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _center,
        zoom: 11.0,
      ),
      markers: _markers.values.toSet(),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        var inputText = textEditingController.text;
        final storeInfoList = await scrapingPage(inputText);

        await firestoreInstance.collection("store").add({
          'url': inputText,
          'name': storeInfoList[0],
          'address': storeInfoList[1],
          'hours': storeInfoList[2],
          'sort': FieldValue.serverTimestamp()
        });

        textEditingController.clear();
      },
      child: Icon(Icons.add),
    );
  }

  Future<List<String>> scrapingPage(String inputText) async {
    final webScraper = WebScraper(inputText);
    if (await webScraper.loadWebPage('/')) {
      final storeInfo =
          webScraper.getElement('.rstinfo-table__table>tbody>tr>td', []);
      if (storeInfo.isEmpty) {
        return ["", "", ""];
      }

      final storeName = (storeInfo[0]['title'] as String).trim();
      final storeAddress =
          (storeInfo[4]['title'] as String).trim().split(' ')[0];
      final storeHours =
          (storeInfo[6]['title'] as String).trim().split('営業時間・')[0];
      return [storeName, storeAddress, storeHours];
    }
    return ["", "", ""];
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot snapshot) {
    assert(snapshot.data['name'] != null);
    assert(snapshot.data['address'] != null);
    assert(snapshot.data['hours'] != null);
    final name = snapshot.data['name'];
    final address = snapshot.data['address'];
    final hours = snapshot.data['hours'];

    return Padding(
      key: ValueKey(name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: Dismissible(
          key: Key(name),
          onDismissed: (_) async {
            print(name + ' がdismissされたよ');
            await firestoreInstance
                .collection('store')
                .where('name', isEqualTo: name)
                .getDocuments()
                .then((value) => value.documents[0].reference.delete());
          },
          child: ListTile(
              title: Text(name),
              subtitle: Text(address + '\n\n' + hours),
              isThreeLine: true,
              onTap: () {
                _launchURL(address);
                print(name + ' がtapされたよ');
              }),
        ),
      ),
    );
  }
}

class Store {
  String name;
  String address;
  double latitude;
  double longitude;

  Store(this.name, this.address, this.latitude, this.longitude);
}
