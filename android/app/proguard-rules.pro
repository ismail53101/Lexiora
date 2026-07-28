# PDFBox-Android references an optional JPEG2000 (JP2) codec (the Gemalto
# JP2 library) for a rarely-used image filter. That codec is a separate,
# non-bundled dependency we don't include — the app only ever decodes plain
# rendered PNG pages for OCR, never JP2 images — so these classes are
# genuinely absent and unused, not a real problem. Without this, R8 aborts
# the release build entirely on the missing reference instead of just
# dropping the unreachable code path.
-dontwarn com.gemalto.jp2.JP2Decoder
-dontwarn com.gemalto.jp2.JP2Encoder
-dontwarn com.gemalto.jp2.**

# Same situation for PDFBox's optional encryption support (BouncyCastle) —
# we only ever write plain, unencrypted OCR text into unencrypted PDFs, so
# this optional codepath is unreachable at runtime.
-dontwarn org.bouncycastle.**
