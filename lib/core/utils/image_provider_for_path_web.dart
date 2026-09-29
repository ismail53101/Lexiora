import 'package:flutter/widgets.dart';

ImageProvider<Object> imageProviderForPath(String path) =>
    NetworkImage(path) as ImageProvider<Object>;
