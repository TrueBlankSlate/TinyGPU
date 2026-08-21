// decode_output.cpp
//
// Takes the 256-character '0'/'1' ASCII stream that comes back in PuTTY
// (produced by tx_translator.v / UART_TX) and converts it back into 4
// human-readable 64-bit numbers: v00, v01, v11, v10.
//
// Frame order (matches tx_translator.v exactly):
//   v00, v01, v11, v10   (4 values, 64 bits each = 256 bits total)
//
// Bit order WITHIN each field: MSB first. tx_translator.v sends
// v00[63] first, walking down to v00[0], then repeats for v01, v11, v10.
// (Note: this is the OPPOSITE bit order from the input encoder, which is
// LSB-first -- that's correct, rx_assembly.v and tx_translator.v just use
// different conventions.)
//
// Paste the raw text PuTTY showed you (just the 0s and 1s -- any stray
// whitespace/newlines get ignored automatically) and it prints each value
// as unsigned decimal, signed decimal (two's complement), and hex.
//
// Build:   g++ -std=c++17 -O2 -o decode_output decode_output.cpp
// Run:     ./decode_output

#include <cstdint>
#include <iostream>
#include <string>
#include <vector>

// Reads from stdin until it has collected 'count' characters that are
// '0' or '1', ignoring everything else (spaces, newlines, stray text).
static std::string collect_bits(size_t count) {
    std::string bits;
    bits.reserve(count);
    char c;
    while (bits.size() < count && std::cin.get(c)) {
        if (c == '0' || c == '1') {
            bits += c;
        }
    }
    return bits;
}

static uint64_t bits_to_value_msb_first(const std::string& bits, size_t start) {
    uint64_t v = 0;
    for (int i = 0; i < 64; ++i) {
        v <<= 1;
        v |= (bits[start + i] == '1') ? 1ULL : 0ULL;
    }
    return v;
}

static void print_value(const std::string& name, uint64_t v) {
    int64_t signed_v = static_cast<int64_t>(v);
    std::cout << name << " = " << v
              << "  (signed: " << signed_v << ")"
              << "  (hex: 0x" << std::hex << v << std::dec << ")\n";
}

int main() {
    std::cout << "==============================================\n";
    std::cout << " UART output decoder for tx_translator.v\n";
    std::cout << "==============================================\n";
    std::cout << "Paste the 256-character 0/1 stream PuTTY showed you,\n";
    std::cout << "then press Enter (and Ctrl+D / Ctrl+Z if needed):\n\n";

    std::string bits = collect_bits(256);

    if (bits.size() < 256) {
        std::cerr << "\nOnly found " << bits.size()
                  << " binary characters, expected 256. "
                  << "Paste the full output and try again.\n";
        return 1;
    }

    uint64_t v00 = bits_to_value_msb_first(bits, 0);
    uint64_t v01 = bits_to_value_msb_first(bits, 64);
    uint64_t v11 = bits_to_value_msb_first(bits, 128);
    uint64_t v10 = bits_to_value_msb_first(bits, 192);

    std::cout << "\n----- Decoded values -----\n";
    print_value("v00", v00);
    print_value("v01", v01);
    print_value("v11", v11);
    print_value("v10", v10);
    std::cout << "---------------------------\n";

    return 0;
}
