import 'dart:async';
import 'dart:io';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neil_final/sign_in.dart';
import 'package:neil_final/text_input_formatter.dart';
import 'package:path/path.dart' as path;

class PostPage extends StatefulWidget {
  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  List<File> _imageFiles = [];
  List<String> _imageFilenames = [];
  List<String> _imageLocations = [];
  List<String> _imageLabels = [];

  File imageFile;
  String _imageLocation = "";

  String _title;
  double _price = -1;
  String _description = "";
  final Map<String, Marker> _markers = {};
  Completer<GoogleMapController> _controller = Completer();
  final databaseReference = Firestore.instance;
  final _amountValidator =
      RegExInputFormatter.withRegex('^[0-9]{0,6}(\\.[0-9]{0,2})?\$');

  var currentLocation;
  CameraPosition initialCameraPosition =
      CameraPosition(zoom: 2, target: LatLng(42.747932, -71.167889));

  @override
  void initState() {
    super.initState();
    _updateMap();
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  Future<void> _getLabels(File image, [int i]) async {
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(image);

    // final ImageLabeler cloudLabeler =
    //     FirebaseVision.instance.cloudImageLabeler();
    final ImageLabeler labeler = FirebaseVision.instance.imageLabeler();

    // final List<ImageLabel> cloudLabels =
    //     await cloudLabeler.processImage(visionImage);
    final List<ImageLabel> labels = await labeler.processImage(visionImage);

    // for (ImageLabel cloutLabel in cloudLabels) {
    //   final String text = cloutLabel.text;
    //   // final String entityId = cloutLabel.entityId;
    //   final double confidence = cloutLabel.confidence;

    //   print("Cloud Label: " + text + ", " + confidence.toString());
    // }

    String justLabels = "";
    for (ImageLabel label in labels) {
      final String text = label.text;
      // final String entityId = label.entityId;
      final double confidence = label.confidence;
      justLabels = justLabels + text + " ";

      print("Local Label: " + text + ", " + confidence.toString());
    }
    if (i != null) {
      _imageLabels[i] = justLabels;
    } else {
      _imageLabels.add(justLabels);
    }

    // cloudLabeler.close();
    labeler.close();
  }

  Future<void> _updateMap() async {
    GoogleMapController cont = await _controller.future;
    currentLocation = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

    if (!mounted) return;
    setState(() {
      _markers.clear();
      final marker = Marker(
        markerId: MarkerId("curr_loc"),
        position: LatLng(currentLocation.latitude, currentLocation.longitude),
        infoWindow: InfoWindow(title: 'Your Location'),
      );
      _markers["Current Location"] = marker;
      CameraPosition newtPosition = CameraPosition(
        target: LatLng(currentLocation.latitude, currentLocation.longitude),
        zoom: 11,
      );
      cont.animateCamera(CameraUpdate.newCameraPosition(newtPosition));
    });
  }

  void _savePost(BuildContext context) async {
    if (_title != null) {
      Navigator.of(context).pop();
      if (_imageLocation != null) {
        _uploadFiles().then((value) => _commitToFBDB());
      } else {
        _commitToFBDB();
      }
    } else {
      _showTitleRequiredDialog(context);
    }
  }

  Future<void> _commitToFBDB() async {
    DocumentReference ref =
        await databaseReference.collection("neil-posts").add({
      'Date': new DateTime.now(),
      'Title': _title,
      'Description': _description,
      'Price': _price,
      'ImagePath': _imageLocations,
      'ImageFilename': _imageFilenames,
      'ImageLabel': _imageLabels,
      'SubmitterEmail': email,
      'Lat': currentLocation.latitude.toString(),
      'Long': currentLocation.longitude.toString(),
    });
    print("Commit to Firebase DB: ref# " + ref.documentID);
  }

  Future<void> _uploadFiles() async {
    for (int i = 0; i < _imageFiles.length; i++) {
      String filename = path.basename(_imageFiles[i].path);

      StorageReference storageReference = FirebaseStorage.instance
          .ref()
          .child("images/$email/$_title/$filename");

      final StorageUploadTask uploadTask =
          storageReference.putFile(_imageFiles[i]);
      final StorageTaskSnapshot downloadUrl = (await uploadTask.onComplete);
      final String url = (await downloadUrl.ref.getDownloadURL());
      _imageLocations[i] = url;
      _imageFilenames[i] = filename;
    }
  }

  Future<void> _showTitleRequiredDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Title required"),
            content: Text("Please go back and enter a title before posting."),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Okay")),
            ],
          );
        });
  }

  _openCamera(BuildContext context, [int image]) async {
    var picture = await ImagePicker.pickImage(source: ImageSource.camera);

    this.setState(() {
      if (picture != null) {
        if (image != null) {
          _imageFiles[image] = picture;
          _imageLocations[image] = picture.path;
          _getLabels(picture, image);
        } else {
          _imageFiles.add(picture);
          _imageLocations.add(picture.path);
          _imageFilenames.add(path.basename(picture.path));
          _getLabels(picture);
        }
      }
    });
  }

  Widget _generateImageWidgets() {
    List<Widget> list = new List<Widget>();

    for (var i = 0; i < _imageFiles.length; i++) {
      list.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () {
            _openCamera(context, i);
            print("This is object: " + i.toString());
          },
          child: Image.file(
            _imageFiles[i],
            height: 100,
          ),
        ),
      ));
    }
    if (list.length < 4) {
      list.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: new GestureDetector(
          onTap: () {
            _openCamera(context);
          },
          child: Image(
            image: AssetImage("assets/add_image_asset.png"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New Post"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.only(
                  top: 8.0, bottom: 8.0, left: 32, right: 32),
              child: TextField(
                decoration:
                    InputDecoration(hintText: 'Enter title of the item'),
                onChanged: (text) {
                  _title = text;
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(
                  top: 8.0, bottom: 8.0, left: 32, right: 32),
              child: TextField(
                decoration:
                    InputDecoration(hintText: 'Enter price of the item'),
                inputFormatters: [_amountValidator],
                keyboardType: TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                onChanged: (text) {
                  _price = double.parse(text);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(
                  top: 8.0, bottom: 8.0, left: 32, right: 32),
              child: TextField(
                decoration:
                    InputDecoration(hintText: 'Enter description of the item'),
                onChanged: (text) {
                  _description = text;
                },
              ),
            ),
            _generateImageWidgets(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: 300.0,
                height: 200.0,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: initialCameraPosition,
                  markers: _markers.values.toSet(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _savePost(context);
        },
        tooltip: 'Post For Sale',
        label: Text('POST'),
        icon: Icon(Icons.share),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0))),
      ),
    );
  }
}
