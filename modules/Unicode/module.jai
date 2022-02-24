#load "utf8.jai";
#load "utf16.jai";
#load "utf32.jai";

UNICODE_INVALID : u32 : 0xfffd;
// @Note (stefan): End of input does not exist as a unicode codepoint.
// It is just symbolic, so we give it a value outside the range of
// possible unicode codepoints
UNICODE_EOI     : u32 : 0xffff_ffff;
UNICODE_MAX     : u32 : 0x0010_ffff;
