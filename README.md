### mint

`mint` is a hand-written opinionated code formatter for Zig. It is inspired by formatters like [prettier](https://prettier.io/) and [rustfmt](https://github.com/rust-lang/rustfmt). 

`mint` supports all of Zig 0.16.0 syntax. It is also able to format itself. However, it's still in a very early stage so expect bugs. 

### Building
```
zig build -Doptimize=ReleaseSafe
```

### Testing
```
zig build test --summary all
```

### Usage
```
❯ ./zig-out/bin/mint

Usage:
  mint <command> [<args>]
    init                        -  create a `mint.zon` config file
    fmt [filename|directory]    -  format a file or directory of files
    watch [filename|directory]  -  format in watch mode
    help                        -  display usage information
```

### Configuration
Even though `mint` is an opinionated formatter, it provides two configuration options that could potentially influence formatting: maximum print width and indentation width/size.

By default, `mint` uses a maximum print width of 85 characters and an indentation size of 2. However, this is configurable. `mint` uses a `mint.zon` configuration file for specifying these options:
```zig
.{
  .width = <your-width>, // print width
  .indent = <your-indent>, // indentation size
  .ignore = .{} // directories/files to ignore
}
```

### Contributing
All of `mint`'s code is purely hand-written, nothing is AI-generated, and I'd like to keep it that way. Please do not submit vibe-coded or AI-generated patches. Contributions are welcome, provided they adhere to this guideline.

### License
MIT
