import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restalltech/API/UpLoadDDT/upload.dart';

class ImagePickerWidget extends StatefulWidget {
  final String t;
  const ImagePickerWidget({Key? key, required this.t}) : super(key: key);

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  List<XFile> _selectedImages = [];
  var _isLoading = false;
  Future<void> _pickImages() async {
    List<XFile>? images = await ImagePicker().pickMultiImage(
      imageQuality: 85,
    );

    if (images != null) {
      // Check the total number of selected images and their sizes
      int totalSize = 0;
      for (var image in images) {
        final file = await image.readAsBytes();
        totalSize += file.lengthInBytes;
      }

      if (images.length + _selectedImages.length > 10 ||
          totalSize > 10 * 1024 * 1024) {
        // Handle error: too many images or total size exceeds limit
        return;
      }

      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _takePhoto() async {
    XFile? image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages(String t) async {
    setState(() => _isLoading = true);
    int status = await UploadDDTApi().uploadImages(t, _selectedImages);
    if (status == 201) {
      setState(() => _isLoading = false);

      FlutterPlatformAlert.showAlert(
        windowTitle: 'Caricamento Completato',
        text: 'Il caricamento del DDT avvenuto con successo',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.information,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          height: 300, // Imposta un'altezza fissa o limitata al contenitore
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(
                    File(_selectedImages[index].path),
                    fit: BoxFit.cover,
                  ),
                  IconButton(
                    onPressed: () => _removeImage(index),
                    icon: Icon(
                      Icons.remove_circle,
                      color: Colors.red,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                //onPressed: _isLoading: null ? _onSubmit,
                onPressed: (!_isLoading && _selectedImages.isNotEmpty)
                    ? () {
                        _uploadImages(widget.t);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16.0)),
                icon: _isLoading
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Icon(Icons.upload_rounded),
                label: const Text('Carica'),
              ),
            ),
            if (Platform.isAndroid || Platform.isIOS)
              IconButton(
                onPressed: _takePhoto,
                icon: Icon(Icons.camera_alt_rounded),
              ),
            IconButton(
              onPressed: _pickImages,
              icon: Icon(Icons.image_rounded),
            ),
          ],
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
