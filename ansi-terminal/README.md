# ansi-terminal

This package provides a collection of functions to generate
[ANSI terminal escape sequences](http://en.wikipedia.org/wiki/ANSI_escape_code).

The ANSI escape sequences provide a rich range of functionality for
terminal control, which includes:

* Colored text output, with control over both foreground and
  background colors
* Hiding or showing the cursor
* Moving the cursor around
* Clearing parts of the screen

This package is modeled after
[ansi-terminal](http://hackage.haskell.org/package/ansi-terminal).

## Modules

* [ansi-terminal](man/ansi-terminal)

## Supported OSes

This module is OS-independent and should work on any OpenComputers
OSes. But due to the current limitation of OC, most of SGR commands
don't work at all. In particular, none of OC GPUs can display bold or
underlined characters.

## License

[CC0](https://creativecommons.org/share-your-work/public-domain/cc0/)
