`ifndef DATAPATH_MACROS_SVH
`define DATAPATH_MACROS_SVH

    `ifndef SYNTHESIS
        
        // Why assert #0?
        // 1. Delta-Cycle Race Condition Prevention:
        //    Immediate assertions evaluated without delay execute in the active region,
        //    risking evaluation against unstable or transient signals (glitches) within 
        //    the same delta cycle.
        // 2. Deferral Mechanism:
        //    The #0 delay defers the assertion evaluation to the inactive/observed region,
        //    ensuring all combinational logic, signal updates, and delta-cycle transitions 
        //    have completely settled before the condition is tested. This eliminates false 
        //    alarms caused by race conditions in functions and complex blocks.
        `define ASSERT(cond, actions) \
            assert #0 (cond) else begin \
                actions; \
            end
    `else
        `define ASSERT(cond, actions)
    `endif

`endif
