### mint
`mint` is a hand-written opinionated code formatter for Zig. It is inspired by formatters like [prettier](https://prettier.io/) and [rustfmt](https://github.com/rust-lang/rustfmt). 

`mint` supports all of Zig 0.16.0 syntax. It is also able to format itself. However, it's still in a very early stage so expect bugs. 

### Why `mint`?
`mint` performs automatic line-wrapping when a document exceeds a specified print width without relying on syntactic hints (such as trailing commas) from the programmer. Additionally, it is possible to [configure](#configuration) the formatting print width and indentation size.

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
By default, `mint` uses a maximum print width of 85 characters and an indentation size of 2. However, this is configurable. You can specify configuration options in a `mint.zon` file within a Zig project:
```zig
.{
  .width = <your-width>, // print width
  .indent = <your-indent>, // indentation size
  .ignore = .{} // directories/files to ignore
}
```
Create a ready-to-use `mint.zon` file with: `mint init`.

### Contributing
All of `mint`'s code is purely hand-written, nothing is AI-generated, and I'd like to keep it that way. Please do not submit vibe-coded or AI-generated patches. Contributions are welcome, provided they adhere to this guideline.

### License
MIT
