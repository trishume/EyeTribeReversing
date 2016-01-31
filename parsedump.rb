txt = IO.read("log2.txt")

REG = /\(\(uint64_t\*\)\$rbx\)\[0\]
\(uint64_t\) \$\d+ = (\d+)
\(lldb\)  p \*\(uint32_t\(\*\)\[15\]\)\(\(\(uint32_t\*\*\)\$rbx\)\[1\]\)
\(uint32_t \[15\]\) \$\d+ = \((.*)\)/

bRequestMapping = {
 0x01 => "UVC_SET_CUR",
 0x81 => "UVC_GET_CUR",
 0x82 => "UVC_GET_MIN",
 0x83 => "UVC_GET_MAX",
}

unitMapping = {
  0x01 => "VC_HEADER",
  0x02 => "VC_INPUT_TERMINAL",
  0x03 => "VC_OUTPUT_TERMINAL",
  0x04 => "VC_SELECTOR_UNIT",
  0x05 => "VC_PROCESSING_UNIT",
  0x06 => "VC_EXTENSION_UNIT",
}

outputControlMapping = {
  0x00 => "VS_CONTROL_UNDEFINED",
  0x01 => "VS_PROBE_CONTROL",
  0x02 => "VS_COMMIT_CONTROL",
  0x03 => "VS_STILL_PROBE_CONTROL",
  0x04 => "VS_STILL_COMMIT_CONTROL",
  0x05 => "VS_STILL_IMAGE_TRIGGER_CONTROL",
  0x06 => "VS_STREAM_ERROR_CODE_CONTROL",
  0x07 => "VS_GENERATE_KEY_FRAME_CONTROL",
  0x08 => "VS_UPDATE_FRAME_SEGMENT_CONTROL",
  0x09 => "VS_SYNCH_DELAY_CONTROL",
}

inputControlMapping = {
  0x00 => "CT_CONTROL_UNDEFINED",
  0x01 => "CT_SCANNING_MODE_CONTROL",
  0x02 => "CT_AE_MODE_CONTROL",
  0x03 => "CT_AE_PRIORITY_CONTROL",
  0x04 => "CT_EXPOSURE_TIME_ABSOLUTE_CONTROL",
  0x05 => "CT_EXPOSURE_TIME_RELATIVE_CONTROL",
  0x06 => "CT_FOCUS_ABSOLUTE_CONTROL",
  0x07 => "CT_FOCUS_RELATIVE_CONTROL",
  0x08 => "CT_FOCUS_AUTO_CONTROL",
  0x09 => "CT_IRIS_ABSOLUTE_CONTROL",
  0x0A => "CT_IRIS_RELATIVE_CONTROL",
  0x0B => "CT_ZOOM_ABSOLUTE_CONTROL",
  0x0C => "CT_ZOOM_RELATIVE_CONTROL",
  0x0D => "CT_PANTILT_ABSOLUTE_CONTROL",
  0x0E => "CT_PANTILT_RELATIVE_CONTROL",
  0x0F => "CT_ROLL_ABSOLUTE_CONTROL",
  0x10 => "CT_ROLL_RELATIVE_CONTROL",
  0x11 => "CT_PRIVACY_CONTROL",
}

def bytes(n)
  [n & 0xFF, (n >> 8) & 0xFF, (n >> 16) & 0xFF, (n >> 24) & 0xFF]
end

txt.scan(REG) do |m|
  # NOTE: this is little endian - least significant byte is lowest memory address
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
  x[:req] = bRequestMapping[x[:bRequest]]
  x[:sel] = unitMapping[x[:unitId]]
  x[:outMsg] = outputControlMapping[x[:selector]] if [3,4].include? x[:unitId]
  x[:inMsg] = inputControlMapping[x[:selector]] if x[:unitId] == 2
  p x

  ints = m[1].split(',').map {|s| s[/= \d+/][2..-1].to_i}
  bytes = ints.flat_map {|i| bytes(i) }
  p bytes.take(x[:wLength])
end
