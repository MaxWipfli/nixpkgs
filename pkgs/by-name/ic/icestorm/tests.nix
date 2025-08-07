# Run the examples from $src/examples/ as simple integration tests. They require
# yosys and nextpnr (which itself depends on this package), so they cannot be
# ran during the check phase.
{
  runCommand,
  icestorm,
  nextpnr,
  yosys,

  pname,
  src,
}:

runCommand "${pname}-test-examples"
  {
    nativeBuildInputs = [
      icestorm
      nextpnr
      yosys
    ];
  }
  ''
    cp -r ${src}/examples .
    chmod -R +w examples
    for example in examples/*; do
      make -C $example
    done

    # smoke test icebox_vlog manually
    pushd examples/icestick
    set -x
    icebox_vlog -p icestick.pcf example.asc > example_out.v
    grep "^module chip" example_out.v
    set +x
    popd

    touch $out
  ''
