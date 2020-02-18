# pavisualizer

A PulseAudio music visualizer in your terminal!

## Compilation

You'll need Swift. You can get it from https://swift.org.

You'll also need [KissFFT](https://github.com/mborgerding/kissfft) --
just run `git submodule update` to pull it in.

Then run `make kissfft` to build KissFFT, then `make` to build the program itself.

## Usage

```
pavisualizer [source]
```

pavisualizer can take a PulseAudio source name to listen to; if you want to
monitor an output, append `.monitor` to the output sink name. You can get
the available outputs with this command:

```
pacmd list-sinks | grep 'name:' | sed -Ee 's/.*<(.*)>.*/\1.monitor/'
```

If no source is given, it defaults to whatever source you have set as default,
typically your microphone input.

## License

This is free and unencumbered software released into the public domain.
See [COPYING.md](COPYING.md) for more information.
