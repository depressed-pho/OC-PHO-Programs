# tap

This package implements
[Test Anything Protocol](https://testanything.org/) version 13
specification. Test suites use the module [tap/test](man/test) to
produce TAP output, and the program [prove](man/prove) runs those
tests and parses the result.

## Modules

* [prove](man/prove)
* [tap/harness](man/harness)
* [tap/parser](man/parser)
* [tap/parser/result](man/parser/result)
* [tap/statistics](man/statistics)
* [tap/test](man/test)

## Supported OSes

The following modules are OS-independent and should work on any
OpenComputers OSes:

* tap/parser
* tap/parser/result
* tap/statistics

The following modules, however, currently depends on OpenOS:

* prove
* tap/harness
* tap/test

## License

[CC0](https://creativecommons.org/share-your-work/public-domain/cc0/)
