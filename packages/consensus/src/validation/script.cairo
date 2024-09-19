use shinigami_engine::engine::EngineImpl;
use shinigami_engine::transaction::{
    EngineTransactionInputTrait, EngineTransactionOutputTrait, EngineTransactionTrait
};
use script::dummy::{HashCacheDummy, HashCacheDummyImpl};
use crate::types::transaction::{Transaction, TxIn, TxOut};

impl EngineTransactionInputImpl of EngineTransactionInputTrait<TxIn> {
    fn get_prevout_txid(self: @TxIn) -> u256 {
        0
    }

    fn get_prevout_vout(self: @TxIn) -> u32 {
        0
    }

    fn get_signature_script(self: @TxIn) -> @ByteArray {
        @""
    }

    fn get_witness(self: @TxIn) -> Span<ByteArray> {
        array![].span()
    }

    fn get_sequence(self: @TxIn) -> u32 {
        0
    }
}

impl EngineTransactionOutputDummyImpl of EngineTransactionOutputTrait<TxOut> {
    fn get_publickey_script(self: @TxOut) -> @ByteArray {
        @""
    }

    fn get_value(self: @TxOut) -> i64 {
        0
    }
}

impl EngineTransactionDummyImpl of EngineTransactionTrait<Transaction, TxIn, TxOut,> {
    fn get_version(self: @Transaction) -> i32 {
        Into::<u32, i64>::into(*self.version).try_into().unwrap()
    }

    fn get_transaction_inputs(self: @Transaction) -> Span<TxIn> {
        *self.inputs
    }

    fn get_transaction_outputs(self: @Transaction) -> Span<TxOut> {
        *self.outputs
    }

    fn get_locktime(self: @Transaction) -> u32 {
        *self.lock_time
    }
}

pub fn validate_authorization(tx: @Transaction) -> Result<(), ByteArray> {
    let cache: HashCacheDummy = HashCacheDummyImpl::new(tx);

    let mut result: Option<ByteArray> = Option::None;
    for i in 0
        ..(*tx.inputs)
            .len() {
                let previous_output = *tx.inputs[i].previous_output;
                let mut engine = EngineImpl::<
                    TxIn, TxOut, Transaction
                >::new(
                    previous_output.data.pk_script,
                    tx,
                    i,
                    0, //TODO: flags
                    Into::<u64, i128>::into(previous_output.data.value).try_into().unwrap(),
                    @cache
                )
                    .unwrap(); //TODO: handle error

                match EngineImpl::<TxIn, TxOut, Transaction, HashCacheDummy>::execute(ref engine) {
                    Result::Ok(stack) => if stack.len() != 0 {
                        result =
                            Option::Some(format!("Script returned with nonempty stack: {}", stack));
                        break;
                    },
                    Result::Err(err) => {
                        result = Option::Some(format!("Error executing script: {}", err));
                        break;
                    }
                }
            };

    match result {
        Option::Some(err) => Result::Err(err),
        Option::None => Result::Ok(())
    }
}
