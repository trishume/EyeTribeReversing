txt = IO.read("eyetribelog.txt")

txt.scan(/\(\(uint64_t\*\)\$rbx\)\[0\]\n\(uint64_t\) \$\d+ = (\d+)/) do |m|
  n = m[0].to_i
  x = {
    bmRequestType: (n & 0xFF),
    bRequest: (n >> 8) & 0xFF,
    wValue: (n >> 16) & 0xFFFF,
    wIndex: (n >> (16*2)) & 0xFFFF,
    wLength: (n >> (16*3)) & 0xFFFF,
    selector: (n >> (16+8)) & 0xFF,
    unitId: (n >> (16*2+8)) & 0xFF,
  }
  p x
end
