module OSC
  module TCP
    CHAR_END     = 0300 # indicates end of packet
    CHAR_ESC     = 0333 # indicates byte stuffing
    CHAR_ESC_END = 0334 # ESC ESC_END means END data byte
    CHAR_ESC_ESC = 0335 # ESC ESC_ESC means ESC data byte

    CHAR_END_ENC     = [0300].pack('C') # indicates end of packet
    CHAR_ESC_ENC     = [0333].pack('C') # indicates byte stuffing
    CHAR_ESC_END_ENC = [0334].pack('C') # ESC ESC_END means END data byte
    CHAR_ESC_ESC_ENC = [0335].pack('C') # ESC ESC_ESC means ESC data byte
  end
end

