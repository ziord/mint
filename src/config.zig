pub const FmtConfig = struct {
  width: u32 = 80,
  indent: u8 = 2,
  writer: enum (u3) {
    file,
    out,
    mem,
  } = .mem,
};
