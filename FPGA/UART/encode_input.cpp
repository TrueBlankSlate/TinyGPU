// encode_input.cpp
//
// Builds the exact 521-character '0'/'1' ASCII bitstream your rx_assembly.v
// expects, in the exact order it expects it in, and prints it as one line
// you can copy-paste straight into your PuTTY serial session.
//
// Frame order (matches rx_assembly.v's buffer[] assignments exactly):
//   a00, a01, a11, a10, b00, b01, b11, b10   (8 values, 64 bits each)
//   func3    (3 bits)
//   instr_id (6 bits)
//   -----------------------------------------
//   total: 8*64 + 3 + 6 = 521 bits
//
// Bit order WITHIN each field: LSB first. This is because rx_assembly.v
// fills buffer[bit_counter] with each incoming bit in arrival order, and
// then does e.g. "a00 <= buffer[63:0]" directly -- so the very first bit
// you send becomes a00's bit 0 (LSB), and the 64th bit you send becomes
// a00's bit 63 (MSB). Same pattern repeats for every field.
//
// Values can be entered as plain decimal, as hex with a 0x prefix, or as
// a negative decimal (e.g. -5) -- negative values are stored as their
// 64-bit two's complement bit pattern, same as the hardware will treat them.
//
// Build:   g++ -std=c++17 -O2 -o encode_input encode_input.cpp
// Run:     ./encode_input

#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <string>

static uint64_t read_field(const std::string& label) {
    while (true) {
        std::cout << label << ": ";
        std::string line;
        if (!std::getline(std::cin, line)) {
            std::cerr << "\nInput closed unexpectedly.\n";
            std::exit(1);
        }
        if (line.empty()) {
            std::cout << "  (please enter a value)\n";
            continue;
        }
        // strtoull with base 0 auto-detects "0x.." as hex, else decimal.
        // A leading '-' wraps around into two's complement, which is
        // exactly how the hardware will interpret a negative value.
        errno = 0;
        char* end = nullptr;
        bool negative = (line[0] == '-');
        std::string digits = negative ? line.substr(1) : line;
        unsigned long long parsed = std::strtoull(digits.c_str(), &end, 0);
        if (end == digits.c_str() || *end != '\0') {
            std::cout << "  Couldn't parse that as a number, try again.\n";
            continue;
        }
        uint64_t v = static_cast<uint64_t>(parsed);
        if (negative) v = static_cast<uint64_t>(-static_cast<int64_t>(v));
        return v;
    }
}

// Appends 'bits' bits of 'value', LSB first, as '0'/'1' characters.
static void append_lsb_first(std::string& out, uint64_t value, int bits) {
    for (int i = 0; i < bits; ++i) {
        out += ((value >> i) & 1ULL) ? '1' : '0';
    }
}

int main() {
    std::cout << "==============================================\n";
    std::cout << " UART frame builder for rx_assembly.v\n";
    std::cout << "==============================================\n";
    std::cout << "Enter each value as decimal, 0x hex, or negative decimal.\n\n";

    uint64_t a00 = read_field("a00");
    uint64_t a01 = read_field("a01");
    uint64_t a11 = read_field("a11");
    uint64_t a10 = read_field("a10");
    uint64_t b00 = read_field("b00");
    uint64_t b01 = read_field("b01");
    uint64_t b11 = read_field("b11");
    uint64_t b10 = read_field("b10");

    uint64_t func3, instr_id;
    while (true) {
        func3 = read_field("func3 (0-7)");
        if (func3 <= 7) break;
        std::cout << "  func3 must fit in 3 bits (0-7).\n";
    }
    while (true) {
        instr_id = read_field("instr_id (0-63)");
        if (instr_id <= 63) break;
        std::cout << "  instr_id must fit in 6 bits (0-63).\n";
    }

    std::string frame;
    frame.reserve(521);

    append_lsb_first(frame, a00, 64);
    append_lsb_first(frame, a01, 64);
    append_lsb_first(frame, a11, 64);
    append_lsb_first(frame, a10, 64);
    append_lsb_first(frame, b00, 64);
    append_lsb_first(frame, b01, 64);
    append_lsb_first(frame, b11, 64);
    append_lsb_first(frame, b10, 64);
    append_lsb_first(frame, func3, 3);
    append_lsb_first(frame, instr_id, 6);

    std::cout << "\nTotal bits: " << frame.size() << " (should be 521)\n\n";
    std::cout << "----- Copy everything between the lines below into PuTTY -----\n";
    std::cout << frame << "\n";
    std::cout << "----------------------------------------------------------------\n";

    return 0;
}
