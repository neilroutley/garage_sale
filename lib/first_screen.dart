import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:neil_final/login_page.dart';
import 'package:neil_final/post_page.dart';
import 'package:neil_final/review_post_page.dart';
import 'package:neil_final/sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;

class FirstScreen extends StatefulWidget {
  @override
  _FirstScreenState createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  final TextStyle _style = TextStyle(color: Colors.black, fontSize: 20);
  final TextStyle _styleSub = TextStyle(color: Colors.grey, fontSize: 14);
  final TextStyle _styleTime =
      TextStyle(color: Colors.blueAccent[100], fontSize: 12);

  int numOfPosts = 0;
  bool initialLoad = false;

  Future<void> _showSignoutDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(email),
            content: Text("Do you want to sign out?"),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("No")),
              FlatButton(
                  onPressed: () {
                    signOutGoogle();
                    Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) {
                      return LoginPage();
                    }), ModalRoute.withName('/'));
                  },
                  child: Text("Yes")),
            ],
          );
        });
  }

  void initState() {
    super.initState();
  }

  Widget _titleWidget(DocumentSnapshot document) {
    String title = "Untitled...";
    if (document.data.containsKey("Title")) {
      title = document["Title"].length < 15
          ? document["Title"]
          : (document["Title"].substring(0, 13) + "...");
    }
    return Center(
      child: Container(
          padding:
              // const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
              const EdgeInsets.all(8.0),
          child: Text(title, style: _style)),
    );
  }

  Widget _descriptionWidget(DocumentSnapshot document) {
    String title = "No description...";
    if (document.data.containsKey("Description")) {
      title = document["Description"].length < 25
          ? document["Description"]
          : (document["Description"].substring(0, 22) + "...");
    }
    return Center(
      child: Container(
          padding:
              // const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 32, right: 32),
              const EdgeInsets.all(8.0),
          child: Text(title, style: _styleSub)),
    );
  }

  Future<void> _showDeleteDialog(
      BuildContext context, DocumentSnapshot document) {
    String _title = document["Title"];
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Delete post?"),
            content: Text("$_title"),
            actions: <Widget>[
              FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("No")),
              FlatButton(
                  onPressed: () {
                    print("Going to delete the object.");
                    Navigator.pop(context);
                    _deletePost(document);
                  },
                  child: Text("Yes")),
            ],
          );
        });
  }

  Future<void> _deletePost(DocumentSnapshot document) async {
    // delete firebase database info
    await Firestore.instance.runTransaction((Transaction myTransaction) async {
      await myTransaction.delete(document.reference);
    });

    // delete all images in firebase storage
    String _title = document["Title"];
    if (document.data.containsKey("ImageFilename") &&
        document["ImageFilename"].length > 0) {
      for (int i = 0; i < document["ImagePath"].length; i++) {
        String _filename = document["ImageFilename"][i];

        final StorageReference firebaseStorageRef = FirebaseStorage.instance
            .ref()
            .child("images/$email/$_title/$_filename");
        await firebaseStorageRef.delete();
      }
    }
  }

  void _showSnackie(BuildContext context) {
    final snackBar = SnackBar(
      content: Text('You have a new post!'),
    );
    Scaffold.of(context).showSnackBar(snackBar);
  }

  _ago(Timestamp t) {
    return timeago.format(t.toDate(), locale: 'en_short');
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ReviewPostPage(
                    document: document,
                  )),
        );
      },
      child: Padding(
        padding:
            const EdgeInsets.only(top: 2.0, bottom: 2.0, left: 8, right: 8),
        child: Container(
          height: 100,
          child: Card(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                document["ImagePath"] != null &&
                        document["ImagePath"].length > 0
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CachedNetworkImage(
                          imageUrl: document["ImagePath"][0],
                          imageBuilder: (context, imageProvider) => Image(
                            image: imageProvider,
                            width: 60,
                          ),
                          placeholder: (context, url) =>
                              CircularProgressIndicator(),
                          errorWidget: (context, url, error) => Image(
                            image: AssetImage("assets/no-image-available.jpg"),
                            width: 60,
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image(
                          image: AssetImage("assets/no-image-available.jpg"),
                          width: 60,
                        ),
                      ),
                // 2nd in row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _titleWidget(document),
                    _descriptionWidget(document),
                  ],
                ),
                // 3rd in row
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        document["Price"] != null
                            ? document["Price"] is double
                                ? Text(
                                    "\$" + document["Price"].toStringAsFixed(0))
                                : Text("\$" + document["Price"].toString())
                            : Text(""),
                        document.data.containsKey("Date")
                            ? Text(
                                _ago(document["Date"]),
                                style: _styleSub,
                              )
                            : Container(),
                        email == document["SubmitterEmail"]
                            ? GestureDetector(
                                onTap: () {
                                  _showDeleteDialog(context, document);
                                },
                                child: Icon(
                                  Icons.delete_forever,
                                  color: Colors.red[900],
                                ),
                              )
                            : Container(),
                      ]),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Garage Sale"),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                _showSignoutDialog(context);
              },
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  imageUrl,
                ),
                radius: 20,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
          stream: Firestore.instance
              .collection("neil-posts")
              .orderBy('Date', descending: true)
              // .orderBy('Title', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text("Loading...");
            if (snapshot.data.documents.length > numOfPosts && initialLoad) {
              // delay snackbar so we don't cause an error inner nesting a build method
              Future.delayed(const Duration(milliseconds: 100), () {
                _showSnackie(context);
              });
              numOfPosts = snapshot.data.documents.length;
            } else {
              numOfPosts = snapshot.data.documents.length;
              initialLoad = true;
            }
            return ListView.builder(
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) =>
                    _buildListItem(context, snapshot.data.documents[index]));
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostPage()),
          );
        },
        tooltip: "New Post",
        child: Icon(Icons.library_add),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0))),
        mini: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
