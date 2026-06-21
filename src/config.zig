pub const FmtConfig = struct {
  width: u32 = 85,
  indent: u8 = 2,
  write_mode: enum (u3) {
    file,
    out,
    mem,
  } = .mem,
};
