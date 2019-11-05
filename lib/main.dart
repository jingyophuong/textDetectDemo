import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mlkit/mlkit.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  initState() {
    super.initState();
  }

  File _file;
  List<VisionText> _currentLabels = [];
  FirebaseVisionTextDetector detector = FirebaseVisionTextDetector.instance;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text("TextRecognition Demo"),
        ),
        body: _buildBody(),
        floatingActionButton: new FloatingActionButton(
          onPressed: () async{
            try{
              var file = await ImagePicker.pickImage(
                source: ImageSource.gallery
              );
              setState(() {
               _file = file; 
              });
              try{
                var currentLabels = await detector.detectFromPath(_file?.path);
                setState(() {
                 _currentLabels = currentLabels; 
                });
              }
              catch(e){
                print(e.toString());
              }
    
            }
            catch(e)
            {
              print(e.toString());
            }
          },
          child: new Icon(Icons.camera),
        ),
      ),
    );
  }

  Widget _buildBody(){
    return Container(
      child: Column(children: <Widget>[
        _buildImage(),
        _buildList(_currentLabels)
      ],),);
  }
  Widget _buildList(List<VisionText> texts)
  {
    if(texts.length == 0){
      return Text('empty');
    }
    return Expanded(
      child: Container(child: ListView.builder(
        padding: const EdgeInsets.all(1.0),
        itemCount: texts.length,
        itemBuilder: (context, i){
          return _buildRow(texts[i].text);
        },
      ),),
    );
  }

  Widget _buildRow(String text){
    return ListTile(
      title: Text(
        "Text: ${text}"
      ),
      dense: true,
    );
  }

  
  Widget _buildImage(){
    return SizedBox(
      height: 500.0,
      child:  new Center(
        child: _file == null? Text('No Image'): new FutureBuilder<Size>(
          future: _getImageSize(Image.file(_file, fit: BoxFit.fitWidth)),
          builder: (BuildContext context, AsyncSnapshot<Size>snapshot){
            if(snapshot.hasData){
              return Container(
                foregroundDecoration: TextDetectDecoration(_currentLabels, snapshot.data),
                child: Image.file(_file, fit: BoxFit.fitWidth),
                );
            }else{
              return new Text('Detecting....');
            }

          },),
      ),);
  }
  
  Future<Size> _getImageSize(Image image){
    Completer<Size> completer = new Completer<Size>();
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _)
      {
        completer.complete(Size(info.image.width.toDouble(), info.image.height.toDouble()));
      }));
    return completer.future;
  }
}

class TextDetectDecoration extends Decoration{
  final Size _originalImageSize;
  final List<VisionText> _texts;
  TextDetectDecoration(List<VisionText> texts, Size originalImageSize):
     _texts = texts,
      _originalImageSize = originalImageSize;
  
  @override
  BoxPainter createBoxPainter([onChanged]) {
    // TODO: implement createBoxPainter
    return new _TextDetectPainter(_texts, _originalImageSize);
  }
}
    
class _TextDetectPainter extends BoxPainter{
  final Size _originalImageSize;
  final List<VisionText> _texts;
  _TextDetectPainter(List<VisionText> texts, Size originalImageSize):
     _texts = texts,
      _originalImageSize = originalImageSize;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    // TODO: implement paint
    final paint = new Paint()
        ..strokeWidth = 2.0
        ..color = Colors.red
        ..style = PaintingStyle.stroke;
    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for(var text in _texts){
      final _rect = Rect.fromLTRB(
        offset.dx +text.rect.left / _widthRatio,
        offset.dy + text.rect.top /_heightRatio,
        offset.dx + text.rect.right / _widthRatio,
        offset.dy + text.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
    final rect = offset & configuration.size;
    canvas.restore();
  }
  
}