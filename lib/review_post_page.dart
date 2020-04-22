import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:neil_final/image_view.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReviewPostPage extends StatefulWidget {
  final DocumentSnapshot document;

  const ReviewPostPage({
    Key key,
    this.document,
  }) : super(key: key);

  @override
  _ReviewPostPageState createState() => _ReviewPostPageState();
}

class _ReviewPostPageState extends State<ReviewPostPage> {
  @override
  void initState() {
    super.initState();
    if (widget.document.data.containsKey("Lat") &&
        widget.document.data.containsKey("Long") &&
        widget.document["Lat"] != null &&
        widget.document["Long"] != null) {
      _lat = double.parse(widget.document["Lat"]);
      _long = double.parse(widget.document["Long"]);
    }
    _updateMap();
  }

  File imageFile;
  double _lat;
  double _long;
  final TextStyle _style = TextStyle(color: Colors.black, fontSize: 24);
  final TextStyle _stylePrice = TextStyle(color: Colors.red[900], fontSize: 16);
  final TextStyle _styleDesc = TextStyle(fontSize: 16);

  final Map<String, Marker> _markers = {};
  Completer<GoogleMapController> _controller = Completer();

  static const LatLng _center = const LatLng(11.5504, 92.2335);

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  LatLng _location() {
    if (_lat != null && _long != null) {
      print("Location found!");
      return LatLng(_lat, _long);
    } else {
      print("Using default location since none was found...");
      return _center;
    }
  }

  Future<void> _updateMap() async {
    setState(() {
      _markers.clear();
      final marker = Marker(
        markerId: MarkerId("curr_loc"),
        position: _location(),
        infoWindow: InfoWindow(title: 'Your Location'),
      );
      _markers["Current Location"] = marker;
    });
  }

  Widget _generateImageWidgets() {
    List<Widget> list = new List<Widget>();

    if (widget.document["ImagePath"] != null) {
      for (var i = 0; i < widget.document["ImagePath"].length; i++) {
        list.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ImageViewPage(
                            imageLocation: widget.document["ImagePath"][i],
                            labels: widget.document["ImageLabel"][i],
                          )),
                );
              },
              child: CachedNetworkImage(
                imageUrl: widget.document["ImagePath"][i],
                imageBuilder: (context, imageProvider) => Image(
                  image: imageProvider,
                  height: 100,
                ),
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Image(
                  image: AssetImage("assets/no-image-available.jpg"),
                  height: 70,
                ),
              )),
        ));
      }
    }

    if (widget.document["ImagePath"] == null ||
        widget.document["ImagePath"].length < 1) {
      list.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: new GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ImageViewPage(
                        imageLocation: "assets/no-image-available.jpg",
                      )),
            );
          },
          child: Image(
            image: AssetImage("assets/no-image-available.jpg"),
            height: 100,
          ),
        ),
      ));
    }

    return new Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: list);
  }

  Widget _titleWidget() {
    String title = "Untitled...";
    if (widget.document.data.containsKey("Title")) {
      title = widget.document["Title"];
    }
    return Center(
      child: Container(
          padding:
              const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
          child: Text(
            title,
            style: _style,
          )),
    );
  }

  Widget _priceWidget() {
    String price = "No price...";
    if (widget.document.data.containsKey("Price")) {
      if (widget.document["Price"] is double) {
        price = "\$" + widget.document["Price"].toStringAsFixed(0);
      } else {
        price = "\$" + widget.document["Price"].toString();
      }
    }
    return Center(
      child: Container(
          padding:
              const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
          child: Text(
            price,
            style: _stylePrice,
          )),
    );
  }

  Widget _descriptionWidget() {
    String desc = "No description...";
    if (widget.document.data.containsKey("Description")) {
      desc = widget.document["Description"];
    }
    return Center(
      child: Container(
          padding:
              const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
          child: Text(
            desc,
            style: _styleDesc,
          )),
    );
  }

  Widget _posterWidget() {
    String email = "No attribution...";
    if (widget.document.data.containsKey("SubmitterEmail")) {
      email = widget.document["SubmitterEmail"];
    }
    return Center(
      child: Container(
          padding:
              const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
          child: Text(email)),
    );
  }

  Widget _dateWidget() {
    if (widget.document.data.containsKey("Date")) {
      return Center(
          child: Container(
        padding:
            const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
        child: Text(_ago(widget.document["Date"])),
      ));
    } else {
      return Container();
    }
  }

  _ago(Timestamp t) {
    return timeago.format(t.toDate(), locale: 'en');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Review Post"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _titleWidget(),
            _priceWidget(),
            _descriptionWidget(),
            _generateImageWidgets(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 300.0,
                height: 200.0,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _location(),
                    zoom: 9.0,
                  ),
                  markers: _markers.values.toSet(),
                ),
              ),
            ),
            _posterWidget(),
            _dateWidget(),
          ],
        ),
      ),
    );
  }
}
