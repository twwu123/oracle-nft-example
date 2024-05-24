use aiken/list
use aiken/transaction.{
  DatumHash, InlineDatum, Input, NoDatum, Output, ScriptContext,
}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{AssetName, PolicyId, lovelace_of, quantity_of}

type OracleDatum {
  script1_address: Address,
  script2_address: Address,
}

// Script 2 will have practically identical code to script 1 for this example
// except at the end, we ensure that there is an output with 5 ADA to script 1
// and so the two scripts reference each other in this manner.
validator(oracle_nft: (PolicyId, AssetName)) {
  fn script2(_datum: Data, _redeemer: Data, ctx: ScriptContext) -> Bool {
    let ref_inputs: List<Input> = ctx.transaction.reference_inputs

    let ref_inputs_with_oracle_nft: List<Input> =
      list.filter(
        ref_inputs,
        fn(ref_input: Input) -> Bool {
          quantity_of(ref_input.output.value, oracle_nft.1st, oracle_nft.2nd) == 1
        },
      )

    expect Some(oracle_input) =
      when list.length(ref_inputs_with_oracle_nft) is {
        0 -> fail @"Oracle NFT not found in any reference inputs"
        1 -> list.head(ref_inputs_with_oracle_nft)
        _ -> fail @"There are multiple reference inputs with Oracle NFT"
      }

    let oracle_input_data: Data =
      when oracle_input.output.datum is {
        NoDatum -> fail @"Oracle input does not contain any datum"
        DatumHash(_) -> fail @"Oracle input datum must be inlined"
        InlineDatum(data) -> data
      }

    expect oracle_input_datum: OracleDatum = oracle_input_data

    list.any(
      ctx.transaction.outputs,
      fn(output: Output) -> Bool {
        output.address == oracle_input_datum.script1_address && lovelace_of(
          output.value,
        ) > 5000000
      },
    )
  }
}
