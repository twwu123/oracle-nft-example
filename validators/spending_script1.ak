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

// We'll use a tuple of PolicyId, AssetName to identify NFTs
// Parameterize the oracle NFT.
validator(oracle_nft: (PolicyId, AssetName)) {
  // We can ignore datum and redeemer for this example, we only care
  // if the oracle NFT exists in any reference input
  fn script1(_datum: Data, _redeemer: Data, ctx: ScriptContext) -> Bool {
    // list of reference inputs taken from script context
    let ref_inputs: List<Input> = ctx.transaction.reference_inputs

    // filter list of ref inputs to try and find one with oracle NFT
    let ref_inputs_with_oracle_nft: List<Input> =
      list.filter(
        ref_inputs,
        fn(ref_input: Input) -> Bool {
          quantity_of(ref_input.output.value, oracle_nft.1st, oracle_nft.2nd) == 1
        },
      )
    // check that the filtered list of ref inputs with oracle nft has length 1
    // if it does have length 1, then we can set variable oracle_input to the head of the list
    expect Some(oracle_input) =
      when list.length(ref_inputs_with_oracle_nft) is {
        0 -> fail @"Oracle NFT not found in any reference inputs"
        1 -> list.head(ref_inputs_with_oracle_nft)
        _ -> fail @"There are multiple reference inputs with Oracle NFT"
      }

    // we look at the oracle input and check that there is some data inlined
    let oracle_input_data: Data =
      when oracle_input.output.datum is {
        NoDatum -> fail @"Oracle input does not contain any datum"
        DatumHash(_) -> fail @"Oracle input datum must be inlined"
        InlineDatum(data) -> data
      }

    // aiken's syntax to parse a generic data type as some specific type
    // it will cause the script to fail if the type is not exactly matching
    expect oracle_input_datum: OracleDatum = oracle_input_data
    // then we ensure that in order to spend at script1, there must be at least 1 output with
    // 5 ada to script2
    list.any(
      ctx.transaction.outputs,
      fn(output: Output) -> Bool {
        output.address == oracle_input_datum.script2_address && lovelace_of(
          output.value,
        ) > 5000000
      },
    )
  }
}
