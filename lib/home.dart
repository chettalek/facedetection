import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

class homepage extends StatefulWidget {
  _homepageState createState() => _homepageState();
}

class _homepageState extends State<homepage> {
  final ImagePicker imgpicker = ImagePicker();
  File? _pickedImage;

  final faceDetector = FaceDetector(options: FaceDetectorOptions());

  List<Face>? _faces;
  bool isLoading = true;
  ui.Image? _image;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      appBar: AppBar(
        backgroundColor: Colors.purple[100],
      ),
      body:
          Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        SizedBox(
          height: 10,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 70,
              width: 210,
              child: Center(
                child: Text(
                  "Face Detection",
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.purple[400],
                  boxShadow: [
                    BoxShadow(
                        color: const ui.Color.fromARGB(255, 93, 5, 109),
                        offset: Offset(2, 2),
                        blurRadius: 10)
                  ]),
            ),
          ],
        ),
        SizedBox(
          height: 10,
        ),
        Expanded(
          child: Container(
            child: (_pickedImage == null)
                ? Icon(
                    Icons.person,
                    size: 200,
                  )
                : isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Center(
                        child: FittedBox(
                        child: SizedBox(
                          width: _image?.width.toDouble(),
                          height: _image?.height.toDouble(),
                          child: CustomPaint(
                            painter: FacePainter(_image!, _faces!),
                          ),
                        ),
                      )),
            height: double.infinity,
            width: double.infinity,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                    onPressed: () {
                      openCamera().then((val) {
                        if (val != null) {
                          setState(() {
                            _pickedImage = File(val.path);
                          });
                        }
                      });
                      ;
                    },
                    child: Text("Camera")),
                ElevatedButton(
                    onPressed: () {
                      openPhoto().then((val) async {
                        if (val != null) {
                          final List<Face> faces = await faceDetector
                              .processImage(InputImage.fromFilePath(val.path));

                          // for (Face face in faces) {
                          //   final Rect boundingBox = face.boundingBox;

                          //   final double? rotX = face
                          //       .headEulerAngleX; // Head is tilted up and down rotX degrees
                          //   final double? rotY = face
                          //       .headEulerAngleY; // Head is rotated to the right rotY degrees
                          //   final double? rotZ = face
                          //       .headEulerAngleZ; // Head is tilted sideways rotZ degrees
                          //   print("x = $rotX, y = $rotY, z = $rotZ");
                          //   // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
                          //   // eyes, cheeks, and nose available):
                          //   final FaceLandmark? leftEar =
                          //       face.landmarks[FaceLandmarkType.leftEar];
                          //   if (leftEar != null) {
                          //     final Point<int> leftEarPos = leftEar.position;
                          //   }

                          //   // If classification was enabled with FaceDetectorOptions:
                          //   if (face.smilingProbability != null) {
                          //     final double? smileProb = face.smilingProbability;
                          //   }

                          //   // If face tracking was enabled with FaceDetectorOptions:
                          //   if (face.trackingId != null) {
                          //     final int? id = face.trackingId;
                          //   }
                          // }
                          // faceDetector.close();

                          getImageSize(File(val.path));
                          await _loadImage(File(val.path));
                          setState(() {
                            _pickedImage = File(val.path);
                            _faces = faces;

                            isLoading = false;
                          });
                        }
                      });
                    },
                    child: Text("Uploadfile")),
                ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _pickedImage = null;
                      });
                    },
                    child: Text("Remove")),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  openCamera() async {
    try {
      var pickedfile = await imgpicker.pickImage(source: ImageSource.camera);
      if (pickedfile != null) {
        return pickedfile;
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      print("error while picking file.");
    }
  }

  openPhoto() async {
    try {
      var pickedfile = await imgpicker.pickImage(
          source: ImageSource.gallery,
          maxHeight: 480,
          maxWidth: 640,
          imageQuality: 50);
      if (pickedfile != null) {
        return pickedfile;
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      print("error while picking file.");
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then((value) => setState(() {
          _image = value;
        }));
  }

  Future<void> getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    print(imageSize);
    // setState(() {
    //   _imageSize = imageSize;
    // });
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter old) {
    return image != old.image || faces != old.faces;
  }
}
