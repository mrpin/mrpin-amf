module AMF
  # AMF3 Type Markers
  AMF3_UNDEFINED_MARKER = 0x00 #"\000"
  AMF3_NULL_MARKER      = 0x01 #"\001"

  AMF3_FALSE_MARKER = 0x02 #"\002"
  AMF3_TRUE_MARKER  = 0x03 #"\003"

  AMF3_INTEGER_MARKER    = 0x04 #"\004"
  AMF3_DOUBLE_MARKER     = 0x05 #"\005"
  AMF3_STRING_MARKER     = 0x06 #"\006"
  AMF3_XML_DOC_MARKER    = 0x07 #"\a"   not supported
  AMF3_DATE_MARKER       = 0x08 #"\b"
  AMF3_ARRAY_MARKER      = 0x09 #"\t"
  AMF3_OBJECT_MARKER     = 0x0A #"\n"
  AMF3_XML_MARKER        = 0x0B #"\v"   not supported
  AMF3_BYTE_ARRAY_MARKER = 0x0C #"\f"

  AMF3_VECTOR_INT_MARKER    = 0x0D #"\r"    not supported
  AMF3_VECTOR_UINT_MARKER   = 0x0E #"\016"  not supported
  AMF3_VECTOR_DOUBLE_MARKER = 0x0F #"\017"  not supported
  AMF3_VECTOR_OBJECT_MARKER = 0x10 #"\020"  not supported

  AMF3_DICT_MARKER  = 0x11 #"\021"

  # Other AMF3 Markers
  AMF3_EMPTY_STRING = 0x01

  AMF3_CLOSE_DYNAMIC_OBJECT = 0x01
  AMF3_CLOSE_DYNAMIC_ARRAY  = 0x01

  # Other Constants
  MAX_INTEGER               = 268_435_455
  MIN_INTEGER               = -268_435_456
end
