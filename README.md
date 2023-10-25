# PDF-ISO_32000-Builder-raku

## Synopsis

### Push
```
$ cd PDF_ISO_32000-2-Builder-raku
$ make PDF=/my-copy/ISO_32000-2-2020_sponsored.pdf
$ cd ../PDF_ISO_32000-raku
$ git status
$ # etc...
```

### Pull

```
$ cd ../PDF_ISO_32000-2-raku
$ make PDF=/my-copy/ISO_32000-2-2020_sponsored.pdf
$ git status
$ # etc...
```


## Description

This repo is part of the Raku PDF Toolchain. It exists to rebuild the raku
PDF::ISO_32000-2 module for the PDF 2.0 specification.

You will need to supply your own copy of the PDF 2.0 specification as input. This can be obtained
from https://pdfa.org/resource/iso-32000-pdf/.
