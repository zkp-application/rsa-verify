pragma circom 2.0.0;

include "../circomlib/circuits/bitify.circom";
include "./div.circom";

template AsymmetricPolynomialMultiplier(d0, d1) {
    // Implementation of _xjSnark_'s multiplication.
    // Parameters/Inputs:
    //    * `in0` with degree less than `d0`
    //    * `in1` with degree less than `d1`
    // Uses a linear number of constraints ($d0 + d1 - 1$).
    signal input in0[d0];
    signal input in1[d1];

    // Output has degree less than `d`
    var d = d0 + d1 - 1;
    // Witness value.
    signal output out[d];

    // Witness computation.
    var acc;
    for (var i = 0; i < d; i++) {
        acc = 0;
        var start = 0;
        if (d1 < i + 1) {
            start = i + 1 - d1;
        }
        for (var j = start; j < d0 && j <= i; j++) {
            var k = i - j;
            acc += in0[j] * in1[k];
        }
        out[i] <-- acc;
    }

    // Conditions.
    var in0Val;
    var in1Val;
    var outVal;
    for (var c = 0; c < d; c++) {
        in0Val = 0;
        in1Val = 0;
        outVal = 0;
        for (var i = 0; i < d0; i++) {
            in0Val += (c + 1) ** i * in0[i];
        }

        for (var i = 0; i < d1; i++) {
            in1Val += (c + 1) ** i * in1[i];
        }

        for (var i = 0; i < d; i++) {
            outVal += (c + 1) ** i * out[i];
        }

        in0Val * in1Val === outVal;
    }
}

template mul_mod(w, n) {
    signal input a[n];
    signal input b[n];
    signal input modulus[n];

    signal output out[n];

    var lo_bit_var = (1 << w) - 1;
    // Witness
    // Asymmetric Polynomial Multiplier. Each slot are converted to 64bits.
    var d2 = 2 * n - 1;

    var result[d2];
    var carry = 0;
    var acc;

    component divisible = div(w, n);

    for (var i = 0; i < d2; i++) {
        var start = 0;
        var acc = carry;

        if (n < i + 1) {
            start = i + 1 - n;
        }

        for (var j = start; j < n && j <= i; j++) {
            var k = i - j;
            acc += a[j] * b[k];
        }
        
        carry = acc >> w;
        acc = acc & lo_bit_var;

        divisible.a[i] <-- acc;
    }

    divisible.a[2 * n - 1] <-- carry;

    for (var i = 0; i < n; i++) {
        divisible.b[i] <-- modulus[i];
    }


    component left = AsymmetricPolynomialMultiplier(n, n);
    component right = AsymmetricPolynomialMultiplier(n, n);
    for (var i = 0; i < n; i++) {
        left.in0[i] <== a[i];
        left.in1[i] <== b[i];

        right.in0[i] <== modulus[i];
        right.in1[i] <== divisible.quotient[i];
    }

    // TODO: group eq
 //   var doubleN = 2 * n;
 //   var maxWord = n * lo_bit_var * lo_bit_var + lo_bit_var;
 //   component carryR = EqualWhenCarriedRegroup(maxWord, w, doubleN - 1);
 //   for (var i = 0; i < doubleN - 1; i++) {
 //       if (i < n) {
 //           carryR.a[i] <-- left.out[i];
 //           carryR.b[i] <-- right.out[i] + out[i];
 //       } else {
 //           carryR.a[i] <-- left.out[i];
 //           carryR.b[i] <-- right.out[i];
 //       }
 //   }
    for (var i = 0; i < n; i++) {
        out[i] <-- divisible.remainder[i];
    }
}