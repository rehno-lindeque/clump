# clump
Forwards the stdin pipe to stdout in clumps separated by a time interval in the incoming data.

```
$ clump --help
Usage: clump --interval <seconds>[s] [--prefix <string>] [--suffix <string>]

Options:
  --interval <interval>   Time (in seconds) of no input before flushing.
                          Suffix 's' for seconds is optional (e.g., 5 or 5s).
  --prefix <string>       String to print before each flushed block.
  --suffix <string>       String to print after each flushed block.
  --help                  Display this help and exit.
```

```
$ ( printf "abc" ; sleep 2 ; printf "def" ) | clump --interval 1s --prefix "[" --suffix "]"
[abc][def]
```

## Disclaimer

This is a quick hacked together version of this concept. Don't expect much maintainership.

Please let me know if you know of an existing command-line tool that is able to accomplish this.
