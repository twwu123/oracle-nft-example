use aiken/list
use aiken/transaction.{Input, OutputReference, ScriptContext}

validator(utxo: OutputReference) {
  // A simple one time minting policy, check if any inputs contains
  // parameterized utxo, we can use this as the oracle NFT
  fn one_time_token(_redeemer: Data, ctx: ScriptContext) -> Bool {
    list.any(
      ctx.transaction.inputs,
      fn(input: Input) -> Bool { input.output_reference == utxo },
    )
  }
}
