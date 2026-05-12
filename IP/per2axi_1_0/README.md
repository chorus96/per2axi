# per2axi AMD Vivado IP

This directory contains an AMD Vivado-compatible custom IP package for the
`per2axi` SystemVerilog module.

The RTL sources are intentionally **referenced by relative path** from
`component.xml`; they are not copied into this IP directory.  The referenced
files live in `../../src` relative to this directory.

To rebuild the IP metadata with Vivado, run from the repository root:

```tcl
vivado -mode batch -source IP/per2axi_1_0/package_ip.tcl
```

The `per2axi` RTL also instantiates the `axi_slice` buffer modules provided by
this repository's Bender dependency.  Make sure those dependency sources are
available in the Vivado project that consumes this IP.
