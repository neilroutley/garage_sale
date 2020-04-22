import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageViewPage extends StatefulWidget {
  final String imageLocation;
  final String labels;

  const ImageViewPage({
    Key key,
    this.imageLocation,
    this.labels,
  }) : super(key: key);

  @override
  _ImageViewPageState createState() => _ImageViewPageState();
}

class _ImageViewPageState extends State<ImageViewPage> {
  final TextStyle _style = TextStyle(
      color: Colors.white, fontSize: 14, backgroundColor: Colors.black);
  @override
  void initState() {
    super.initState();
  }

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CachedNetworkImage(
            imageUrl: widget.imageLocation,
            imageBuilder: (context, imageProvider) => Image(
              image: imageProvider,
              // height: 70,
              // width: 70,
            ),
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) => Image(
              image: AssetImage("assets/no-image-available.jpg"),
              // height: 70,
            ),
          ),
          widget.labels != null
              ? Container(
                  child: Material(
                    color: Colors.black,
                    child: Text(
                      widget.labels,
                      style: _style,
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                )
              : Container(),
        ],
      ),
    );
  }
}
