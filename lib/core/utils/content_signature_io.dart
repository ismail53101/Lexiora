import 'dart:convert';

String contentSignature(Iterable<String> chunks) {
  int hash = 0xcbf29ce484222325;
  const int prime = 0x100000001b3;
  for (final String chunk in chunks) {
    for (final int byte in utf8.encode(chunk)) {
      hash ^= byte;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
  }
  return hash.toUnsigned(64).toRadixString(16);
}
