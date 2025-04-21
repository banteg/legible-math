pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {
    LM,
    z,
    o,
    n,
    e,
    r,
    t,
    w,
    h,
    f,
    u,
    s,
    x,
    g,
    l,
    a,
    i,
    v,
    NotInteger,
    OutOfRange,
    Overflow,
    LegibleMath
} from "../lib/LegibleMath.sol";

contract LegibleMathTest is Test {
    function test_one_plus_two() public pure {
        LM lhs = o * n * e;
        LM rhs = t * w * o;
        assertEq((lhs + rhs).literally(), 3, "o*n*e + t*w*o should equal 3");
    }

    function test_spell_zero() public pure {
        LM res = z * e * r * o;
        assertEq(res.literally(), 0);
    }

    function test_spell_one() public pure {
        LM res = o * n * e;
        assertEq(res.literally(), 1);
    }

    function test_spell_two() public pure {
        LM res = t * w * o;
        assertEq(res.literally(), 2);
    }

    function test_spell_three() public pure {
        LM res = t * h * r * e * e;
        assertEq(res.literally(), 3);
    }

    function test_spell_four() public pure {
        LM res = f * o * u * r;
        assertEq(res.literally(), 4);
    }

    function test_spell_five() public pure {
        LM res = f * i * v * e;
        assertEq(res.literally(), 5);
    }

    function test_spell_six() public pure {
        LM res = s * i * x;
        assertEq(res.literally(), 6);
    }

    function test_spell_seven() public pure {
        LM res = s * e * v * e * n;
        assertEq(res.literally(), 7);
    }

    function test_spell_eight() public pure {
        LM res = e * i * g * h * t;
        assertEq(res.literally(), 8);
    }

    function test_spell_nine() public pure {
        LM res = n * i * n * e;
        assertEq(res.literally(), 9);
    }

    function test_spell_ten() public pure {
        LM res = t * e * n;
        assertEq(res.literally(), 10);
    }

    function test_spell_eleven() public pure {
        LM res = e * l * e * v * e * n;
        assertEq(res.literally(), 11);
    }

    function test_spell_negative_four() public pure {
        LM negative = n * e * g * a * t * i * v * e;
        LM four = f * o * u * r;
        LM result = negative * four;
        assertEq(result.literally(), -4, "negative * four should equal -4");
    }

    function test_spell_one_plus_one_equals_two() public pure {
        LM one = o * n * e;
        LM two = t * w * o;
        assertEq((one + one).literally(), two.literally());
    }

    function test_spell_two_times_three_equals_six() public pure {
        LM two = t * w * o;
        LM three = t * h * r * e * e;
        LM six = s * i * x;
        assertEq((two * three).literally(), six.literally());
    }

    function test_spell_ten_minus_one_equals_nine() public pure {
        LM ten = t * e * n;
        LM one = o * n * e;
        LM nine = n * i * n * e;
        assertEq((ten - one).literally(), nine.literally());
    }

    /* OutOfRange Tests for literally() */
    function test_out_of_range_positive() public {
        // Create 12/1, which is outside the -11..11 range for literally()
        LM twelve = LM.wrap(0x000c0001);
        vm.expectRevert(abi.encodeWithSelector(OutOfRange.selector, 12));
        this.callLiterally(twelve);
    }

    function test_out_of_range_negative() public {
        // Create -12/1, which is outside the -11..11 range for literally()
        LM negative_twelve = LM.wrap(0xfff40001); // -12 signed 16-bit is 0xFFF4
        vm.expectRevert(abi.encodeWithSelector(OutOfRange.selector, -12));
        this.callLiterally(negative_twelve);
    }

    // Helper wrapper to ensure revert depth is deeper than cheatcode
    function callLiterally(LM _f) public pure returns (int256) {
        return _f.literally();
    }

    // Tests for denominator range fix
    function test_large_denominator_encoding() public pure {
        // Create a fraction with denominator = 40000 (between 32767 and 65535)
        // 1/40000 should now be valid after the fix
        LM fraction = LM.wrap(uint32(1) << 16 | uint32(40000));

        // Extract the numerator and denominator to verify
        (int256 num, int256 den) = fraction.toFraction();

        assertEq(num, 1, "Numerator should be 1");
        assertEq(den, 40000, "Denominator should be 40000");
    }

    function test_max_denominator_encoding() public pure {
        // Create a fraction with denominator = 65535 (maximum uint16 value)
        LM fraction = LM.wrap(uint32(1) << 16 | uint32(65535));

        // Extract the numerator and denominator to verify
        (int256 num, int256 den) = fraction.toFraction();

        assertEq(num, 1, "Numerator should be 1");
        assertEq(den, 65535, "Denominator should be 65535");
    }

    function test_arithmetic_with_large_denominator() public pure {
        // Test arithmetic operations with large denominators (> 32767)

        // Create 1/40000
        LM frac1 = LM.wrap(uint32(1) << 16 | uint32(40000));
        // Create 1/1
        LM frac2 = LM.wrap(uint32(1) << 16 | uint32(1));

        // Calculate frac1 * frac2 = (1/40000) * (1/1) = 1/40000
        LM result = frac1 * frac2;

        // Extract and verify the result
        (int256 num, int256 den) = result.toFraction();
        assertEq(num, 1, "Numerator should be 1");
        assertEq(den, 40000, "Denominator should be 40000");
    }

    function test_reduction_with_large_denominator() public pure {
        // First use arithmetic operations to trigger reduction

        // Create 5/8 and 1/5000
        LM frac1 = LM.wrap((5 << 16) | 8);
        LM frac2 = LM.wrap((1 << 16) | 5000);

        // Calculate frac1 * frac2 = (5/8) * (1/5000) = 5/40000, should reduce to 1/8000
        LM result = frac1 * frac2;

        // Extract and verify results
        (int256 num_out, int256 den_out) = result.toFraction();

        assertEq(num_out, 1, "Numerator should be reduced to 1");
        assertEq(den_out, 8000, "Denominator should be reduced to 8000");
    }

    function test_denominator_overflow_reverts() public {
        // Try to create a fraction with denominator = 65536 (exceeds uint16 max)
        // This should cause an Overflow error

        // Create fractions that will cause overflow when multiplied
        LM frac1 = LM.wrap((1 << 16) | 32768); // 1/32768
        LM frac2 = LM.wrap((1 << 16) | 2); // 1/2

        vm.expectRevert(abi.encodeWithSelector(Overflow.selector));
        // Call through helper function to ensure proper call depth
        this.multiplyFractions(frac1, frac2);
    }

    // Helper function to trigger overflow check
    function multiplyFractions(LM frac1, LM frac2) public pure returns (LM) {
        // This operation will try to create 1/65536, should throw Overflow
        return frac1 * frac2;
    }
}
