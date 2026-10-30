`include "macros.svh"

package math_pkg;

    virtual class math #(parameter WIDTH = 16);

        static function automatic logic signed [WIDTH-1:0] twos_comp( input logic signed [WIDTH-1:0] data_in);
            
            `ASSERT(!$isunknown(data_in), 
                    $warning("[MATH-PKG] twos_comp: Input contains X or Z bits!");)
            
            `ASSERT(data_in != {1'b1, {(WIDTH-1){1'b0}}}, 
                    $error("[MATH-PKG] twos_comp: Overflow! Cannot negate minimum negative value.");)

            return ~data_in + 1'sb1;

        endfunction

     static function automatic logic signed [WIDTH-1:0] shl(
            input logic signed [WIDTH-1:0] data_in,
            input int shamt
        );

            `ASSERT(!$isunknown(data_in) && !$isunknown(shamt), 
                $warning("[MATH-PKG] shl: Input data or shift amount contains X or Z bits!");
            )
            `ASSERT(shamt >= 0 && shamt < WIDTH, 
                $error("[MATH-PKG] shl: Shift amount %0d out of bounds for width %0d", shamt, WIDTH);
            )
            if (shamt > 0) begin
                `ASSERT((data_in >> (WIDTH - shamt)) == (data_in[WIDTH-1] ? {shamt{1'b1}} : {shamt{1'b0}}), 
                    $error("[MATH-PKG] shl: Overflow! Significant bits lost during left shift. data = %b, shamt = %0d", data_in, shamt);
                )
            end

            return data_in <<< shamt;
        endfunction


        static function automatic logic signed [WIDTH-1:0] shr_arith(
            input logic signed [WIDTH-1:0] data_in,
            input int shamt
        );
            `ASSERT(!$isunknown(data_in) && !$isunknown(shamt), 
                $warning("[MATH-PKG] shr_arith: Input data or shift amount contains X or Z bits!");
            )
            
            `ASSERT(shamt >= 0 && shamt < WIDTH, 
                $error("[MATH-PKG] shr_arith: Shift amount %0d out of bounds for width %0d", shamt, WIDTH);
            )

            return data_in >>> shamt;
        endfunction


        static function automatic logic signed [WIDTH-1:0] shr_logic(
            input logic signed [WIDTH-1:0] data_in,
            input int shamt
        );
            `ASSERT(!$isunknown(data_in) && !$isunknown(shamt), 
                $warning("[MATH-PKG] shr_logic: Input data or shift amount contains X or Z bits!");
            )
            `ASSERT(shamt >= 0 && shamt < WIDTH, 
                $error("[MATH-PKG] shr_logic: Shift amount %0d out of bounds for width %0d", shamt, WIDTH);
            )

            return $signed(unsigned'(data_in) >> shamt);
        endfunction

        static function automatic logic signed [WIDTH-1:0] abs(
            input logic signed [WIDTH-1:0] data_in
        );
            `ASSERT(!$isunknown(data_in),
                $warning("[MATH-PKG] abs: Input contains X or Z bits!");
                )
            `ASSERT(data_in != {1'b1, {(WIDTH-1){1'b0}}},
                $error("[MATH-PKG] abs: Overflow! Cannot negate minimum negative value %0d", data_in);
                )

            return (data_in < 0) ? -data_in : data_in;
        endfunction

        static function automatic logic signed [WIDTH-1:0] sat_add(
            input logic signed [WIDTH-1:0] a,
            input logic signed [WIDTH-1:0] b
        );
            logic signed [WIDTH:0] full_sum;
            localparam logic signed [WIDTH-1:0] MAX_POS = {1'b0, {(WIDTH-1){1'b1}}};
            localparam logic signed [WIDTH-1:0] MIN_NEG = {1'b1, {(WIDTH-1){1'b0}}};

            `ASSERT(!$isunknown(a) && !$isunknown(b),
                $warning("[MATH-PKG] sat_add: Inputs contain X or Z bits!");)

            full_sum = {a[WIDTH-1], a} + {b[WIDTH-1], b};

            if (a[WIDTH-1] == 1'b0 && b[WIDTH-1] == 1'b0 && full_sum[WIDTH-1] == 1'b1)
                return MAX_POS;
            else if (a[WIDTH-1] == 1'b1 && b[WIDTH-1] == 1'b1 && full_sum[WIDTH-1] == 1'b0)
                return MIN_NEG;
            else
                return full_sum[WIDTH-1:0];
        endfunction

        // Count Leading Zeros
        static function automatic int clz(
            input logic [WIDTH-1:0] data_in
        );
            int count;
            `ASSERT(!$isunknown(data_in),
                $warning("[MATH-PKG] clz: Input contains X or Z bits!");)

            count = 0;
            for (int i = WIDTH - 1; i >= 0; i--) begin
                if (data_in[i] == 1'b1) break;
                count++;
            end
            return count;
        endfunction

        // 1-one Population Count
        static function automatic int popcount1(
            input logic [WIDTH-1:0] data_in
        );
            int count;
            `ASSERT(!$isunknown(data_in),
                $warning("[MATH-PKG] popcount1: Input contains X or Z bits!");)

            count = 0;
            for (int i = 0; i < WIDTH; i++) begin
                if (data_in[i] == 1'b1) count++;
            end
            return count;
        endfunction

        // 0-zero Population Count
        static function automatic int popcount0(
            input logic [WIDTH-1:0] data_in
        );
            int count;
            `ASSERT(!$isunknown(data_in),
                $warning("[MATH-PKG] popcount0: Input contains X or Z bits!");)

            count = 0;
            for (int i = 0; i < WIDTH; i++) begin
                if (data_in[i] == 1'b0) count++;
            end
            return count;
        endfunction

        static function automatic logic [WIDTH-1:0] bit_reverse(
            input logic [WIDTH-1:0] data_in
        );
            logic [WIDTH-1:0] data_out;
            `ASSERT(!$isunknown(data_in),
                $warning("[MATH-PKG] bit_reverse: Input contains X or Z bits!");)

            for (int i = 0; i < WIDTH; i++) begin
                data_out[i] = data_in[WIDTH - 1 - i];
            end
            return data_out;
        endfunction

        static function automatic logic signed [WIDTH-1:0] clamp(
            input logic signed [WIDTH-1:0] val,
            input logic signed [WIDTH-1:0] min_val,
            input logic signed [WIDTH-1:0] max_val
        );
            `ASSERT(!$isunknown(val) && !$isunknown(min_val) && !$isunknown(max_val),
                $warning("[MATH-PKG] clamp: Inputs contain X or Z bits!");)
            `ASSERT(min_val <= max_val,
                $error("[MATH-PKG] clamp: min_val (%0d) must be <= max_val (%0d)", min_val, max_val);)

            if (val < min_val)      return min_val;
            else if (val > max_val) return max_val;
            else                    return val;
        endfunction

        static function automatic logic signed [WIDTH-1:0] sat_sub(
            input logic signed [WIDTH-1:0] a,
            input logic signed [WIDTH-1:0] b
        );
            logic signed [WIDTH:0] full_sub;
            localparam logic signed [WIDTH-1:0] MAX_POS = {1'b0, {(WIDTH-1){1'b1}}};
            localparam logic signed [WIDTH-1:0] MIN_NEG = {1'b1, {(WIDTH-1){1'b0}}};

            `ASSERT(!$isunknown(a) && !$isunknown(b),
                $warning("[MATH-PKG] sat_sub: Inputs contain X or Z bits!");)

            full_sub = {a[WIDTH-1], a} - {b[WIDTH-1], b};

            if (a[WIDTH-1] != b[WIDTH-1] && a[WIDTH-1] != full_sub[WIDTH-1])
                return a[WIDTH-1] ? MIN_NEG : MAX_POS;
            else
                return full_sub[WIDTH-1:0];
        endfunction


        static function automatic logic signed [WIDTH-1:0] sat_mul(
            input logic signed [WIDTH-1:0] a,
            input logic signed [WIDTH-1:0] b
        );
            logic signed [2*WIDTH-1:0] full_mul;
            localparam logic signed [WIDTH-1:0] MAX_POS = {1'b0, {(WIDTH-1){1'b1}}};
            localparam logic signed [WIDTH-1:0] MIN_NEG = {1'b1, {(WIDTH-1){1'b0}}};

            `ASSERT(!$isunknown(a) && !$isunknown(b),
                $warning("[MATH-PKG] sat_mul: Inputs contain X or Z bits!");)

            full_mul = a * b;

            if (full_mul > $signed(MAX_POS))
                return MAX_POS;
            else if (full_mul < $signed(MIN_NEG))
                return MIN_NEG;
            else
                return full_mul[WIDTH-1:0];
        endfunction


        // Count Trailing Zeros
        static function automatic int ctz(
            input logic [WIDTH-1:0] data_in
        );
            int count;
            `ASSERT(!$isunknown(data_in),
                $warning("[MATH-PKG] ctz: Input contains X or Z bits!");)

            count = 0;
            for (int i = 0; i < WIDTH; i++) begin
                if (data_in[i] == 1'b1) break;
                count++;
            end
            return count;
        endfunction


        // Find First Set
        static function automatic int ffs(
            input logic [WIDTH-1:0] data_in
        );
            `ASSERT(!$isunknown(data_in),
                $warning("[MATH-PKG] ffs: Input contains X or Z bits!");)

            for (int i = 0; i < WIDTH; i++) begin
                if (data_in[i] == 1'b1) return i;
            end
            $warning("[MATH-PKG] fls: Every bits are 0!");
            return -1;
        endfunction


        // Find Last Set
        static function automatic int fls(
            input logic [WIDTH-1:0] data_in
        );
            `ASSERT(!$isunknown(data_in),
                $warning("[MATH-PKG] fls: Input contains X or Z bits!");)

            for (int i = WIDTH - 1; i >= 0; i--) begin
                if (data_in[i] == 1'b1) return i;
            end
            $warning("[MATH-PKG] fls: Every bits are 0!");
            return -1;
        endfunction


        static function automatic logic signed [WIDTH-1:0] min(
            input logic signed [WIDTH-1:0] a,
            input logic signed [WIDTH-1:0] b
        );
            `ASSERT(!$isunknown(a) && !$isunknown(b),
                $warning("[MATH-PKG] min: Inputs contain X or Z bits!");)
            return (a < b) ? a : b;
        endfunction


        static function automatic logic signed [WIDTH-1:0] max(
            input logic signed [WIDTH-1:0] a,
            input logic signed [WIDTH-1:0] b
        );
            `ASSERT(!$isunknown(a) && !$isunknown(b),
                $warning("[MATH-PKG] max: Inputs contain X or Z bits!");)
            return (a > b) ? a : b;
        endfunction

    endclass

endpackage
