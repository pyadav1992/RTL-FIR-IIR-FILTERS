# RTL-FIR-IIR-FILTERS
RTL design and implementation of a fixed-point parametric FIR and IIR filters using Verilog HDL.

Designed and implemented fixed point parametric FIR and IIR filters using Verilog HDL. FIR implementations:
- Direct mode that is using M adders and M+1 multipliers.
- Time multiplexing one adder and multiplier.

IIR filter was designed using Second Order Section (SOS) developed in a direct form-1 structure with scaling factors. IIR implementations:
- Direct mode that uses cascading of multiple SOS.
- Time‐multiplexing a single SOS
