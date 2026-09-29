import 'dart:io';
import 'package:flutter/widgets.dart';

ImageProvider<Object> imageProviderForPath(String path) =>
    FileImage(File(path)) as ImageProvider<Object>;
