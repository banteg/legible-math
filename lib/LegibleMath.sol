// SPDX‑License‑Identifier: MIT
pragma solidity ^0.8.24;

/*──────────── 16‑bit signed numerator | 16‑bit unsigned denominator ──────────*/
type LM is uint32;
uint32  constant _DEN_MASK = 0xFFFF;
int256  constant _NUM_MAX  = 32_767;
int256  constant _NUM_MIN  = -32_768; // Minimum value of int16
int256  constant _DEN_MAX  = 65_535;  // Maximum value of uint16

/*─────────── custom errors ───────────*/
error NotInteger(int256 num, int256 den);
error OutOfRange(int256 value);
error Overflow();

/*─────────── helpers ───────────*/
function _split(LM _f) pure returns (int256 num, int256 den) {
    uint32 raw = LM.unwrap(_f);
    // high 16 bits → signed numerator
    num = int256(int16(uint16(raw >> 16)));
    // low 16 bits  → unsigned denominator, then widen safely
    den = int256(uint256(uint16(raw & _DEN_MASK)));
}

function _gcd(int256 _x, int256 _y) pure returns (int256) {
    while (_y != 0) { (_x, _y) = (_y, _x % _y); }
    return _x >= 0 ? _x : -_x;
}

function _encode(int256 _n, int256 _d) pure returns (LM) {
    // Denominator must be positive and within uint16 range (1 to 65535)
    if (_d <= 0 || _d > _DEN_MAX) revert Overflow();
    // Numerator must be within int16 range (-32768 to 32767)
    if (_n < _NUM_MIN || _n > _NUM_MAX) revert Overflow();
    // pack a 16-bit signed numerator and 16-bit unsigned denominator into 32 bits
    // ensure shift occurs on a 32-bit value so bits are not truncated
    uint32 numBits = uint32(uint16(int16(_n)));
    uint32 denBits = uint32(uint16(uint256(_d)));
    uint32 packed = (numBits << 16) | denBits;
    return LM.wrap(packed);
}

function _reduce(int256 _n, int256 _d) pure returns (LM) {
    int256 _g = _gcd(_n, _d);
    return _encode(_n / _g, _d / _g);
}

/*─────────── operator overloads ───────────*/
function _plus(LM _x, LM _y) pure returns (LM) {
    (int256 nx, int256 dx) = _split(_x);
    (int256 ny, int256 dy) = _split(_y);
    return _reduce(nx*dy + ny*dx, dx*dy);
}
function _minus(LM _x, LM _y) pure returns (LM) {
    (int256 nx, int256 dx) = _split(_x);
    (int256 ny, int256 dy) = _split(_y);
    return _reduce(nx*dy - ny*dx, dx*dy);
}
function _times(LM _x, LM _y) pure returns (LM) {
    (int256 nx, int256 dx) = _split(_x);
    (int256 ny, int256 dy) = _split(_y);
    return _reduce(nx*ny, dx*dy);
}
function _over(LM _x, LM _y) pure returns (LM) {
    (int256 nx, int256 dx) = _split(_x);
    (int256 ny, int256 dy) = _split(_y);
    if (ny == 0) revert();
    return _reduce(nx*dy, dx*ny);
}

/* Make the symbols work everywhere */
using {_plus as +, _minus as -, _times as *, _over as /} for LM global;

/*─────────── public helpers ───────────*/
library LegibleMath {
    struct Fraction { int256 num; int256 den; }

    function literally(LM _f) internal pure returns (int256) {
        (int256 _n, int256 _d) = _split(_f);
        if (_n % _d != 0) revert NotInteger(_n, _d);
        int256 val = _n / _d;
        if (val < -11 || val > 11) revert OutOfRange(val);
        return val;
    }

    function toFraction(LM _f) internal pure returns (int256 num, int256 den) {
        (num, den) = _split(_f);
    }
}
using LegibleMath for LM global;

/*─────────── compile‑time packed constants ──────────*/
/* (num << 16) | den */
LM constant a = LM.wrap(0xfffd0050);  // -3 / 80
LM constant e = LM.wrap(0x00010001);  //  1 / 1
LM constant f = LM.wrap(0x00050009);  //  5 / 9
LM constant g = LM.wrap(0x0008001b);  //  8 / 27
LM constant h = LM.wrap(0x0003000a);  //  3 / 10
LM constant i = LM.wrap(0x00090001);  //  9 / 1
LM constant l = LM.wrap(0x000b0001);  // 11 / 1
LM constant n = LM.wrap(0x00010001);  //  1 / 1
LM constant o = LM.wrap(0x00010001);  //  1 / 1
LM constant r = LM.wrap(0x00010001);  //  1 / 1
LM constant s = LM.wrap(0x00070001);  //  7 / 1
LM constant t = LM.wrap(0x000a0001);  // 10 / 1
LM constant u = LM.wrap(0x00240005);  // 36 / 5
LM constant v = LM.wrap(0x00010001);  //  1 / 1
LM constant w = LM.wrap(0x00010005);  //  1 / 5
LM constant x = LM.wrap(0x00020015);  //  2 / 21
LM constant z = LM.wrap(0x00000001);  //  0 / 1
