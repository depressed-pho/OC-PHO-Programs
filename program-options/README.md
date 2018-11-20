# program-options

**NOTE: A config file parser and an envvar parser are planned but have
not been implemented yet.**

This package allows program developers to obtain program options, that
is (name, value) pairs from the user, via conventional methods such as
command line and config file.

Why would you use such a library, and why is it better than parsing
your command line by straightforward hand-written code, or
```shell.parse()``` from OpenOS?

* It's easier. The syntax for declaring options is simple. Things like
  conversion of option values to desired type and storing into program
  variables are handled automatically whenever possible.
* Error reporting is better. All the problems with the command line
  are reported, while hand-written code can just misparse the
  input. In addition, the usage message can be automatically
  generated, to avoid falling out of sync with the real list of
  options.
* Options can be read from anywhere. Sooner or later the command line
  will be not enough for your users, and you'll want config files or
  maybe even environment variables. These can be added without
  significant effort on your part.
* The library is extensible in many ways. It can handle GNU style long
  options as well as positional options by default, but when it's not
  enough, you can write your own handlers and plug them into the
  parser. Adding a support for custom data types is also
  straightforward.

This package is modeled after
[Boost.Program_options](http://www.boost.org/libs/program_options).

## Modules

* [program-options](man/program-options)
* [program-options/command-line-help](man/command-line-help)
* [program-options/command-line-parser](man/command-line-parser)
* [program-options/option-description](man/option-description)
* [program-options/options-description](man/options-description)
* [program-options/positional-options-description](man/positional-options-description)
* [program-options/value-semantic](man/value-semantic)
* [program-options/variable-value](man/variable-value)
* [program-options/variables-map](man/variables-map)

## Supported OSes

This package is OS-independent and should work on any OpenComputers
OSes.

## License

[CC0](https://creativecommons.org/share-your-work/public-domain/cc0/)
