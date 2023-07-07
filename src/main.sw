contract;
use std::constants::ZERO_B256;
use std::call_frames::msg_asset_id;
use std::context::msg_amount;
use std::storage::storage_vec::StorageVec;

struct InitParams {
    discount_factor: Option<u64>,
    market_needs: [Option<(ContractId, u64)>; 5],
    base_discount_rates: [Option<(ContractId, u64)>; 5],
}

struct Vesting {
    owner: Identity,
    spark_amount: u64,
    start_timestamp: u64,
    duration: u64,
    is_claimed: bool,
}

configurable {
    SPARK_ADDRESS: ContractId = ContractId::from(ZERO_B256),
    ADMIN: Address = Address::from(ZERO_B256),
}

storage {
    discount_factor: u64 = 100, //decimals = 2
    base_discount_rates: StorageMap<ContractId, u64> = StorageMap {}, //decimals = 2
    market_needs: StorageMap<ContractId, u64> = StorageMap {}, //decimals = 2
    vestings: StorageVec<Vesting> = StorageVec {}, //todo make as a struct
}

abi BondingContract {
    #[storage(write)]
    fn init(params: InitParams);

    #[storage(read, write)]
    fn bond(market: ContractId);

    // #[storage(read, write)]
    // fn claim(index: u64);

    // //calculations
    #[storage(read)]
    fn is_claimed(index: u64) -> bool;
    #[storage(read)]
    fn calc_discount(market: ContractId) -> u64; //decimals 2
    #[storage(read)]
    fn calc_vesting_time(market: ContractId) -> u64; //decimals 2
    fn calc_max_bond_amount(market: ContractId) -> u64; //decimals 9

    //getters
    #[storage(read)]
    fn get_base_discount_rate(market: ContractId) -> u64; //decimals 2
    #[storage(read)]
    fn get_market_needs(market: ContractId) -> u64; //decimals 2
    #[storage(read)]
    fn get_discount_factor() -> u64; //decimals 2
    fn get_spread_factor(market: ContractId) -> u64; //decimals 2
}

impl BondingContract for Contract {
    #[storage(write)]
    fn init(params: InitParams) {
        if params.discount_factor.is_some() {
            storage.discount_factor.write(params.discount_factor.unwrap())
        }
        let mut i = 0;
        while i < 5 {
            if params.market_needs[i].is_some() {
                let (market, percentage) = params.market_needs[i].unwrap();
                storage.market_needs.insert(market, percentage)
            }
            if params.base_discount_rates[i].is_some() {
                let (market, percentage) = params.base_discount_rates[i].unwrap();
                storage.base_discount_rates.insert(market, percentage)
            }
            i = i + 1;
        }
    }

    #[storage(read, write)]
    fn bond(market: ContractId) { //todo
        assert(ADMIN != Address::from(ZERO_B256));
        assert(msg_asset_id() == market);

        let amount = msg_amount();
        let max_bond_amount = _calc_max_bond_amount(market);
        assert(amount <= max_bond_amount);

        let spark_price = _get_price(SPARK_ADDRESS);
        let market_asset_price = _get_price(market);
        // ❌ Compiler error: thread 'main' panicked at 'called `Option::unwrap()` on a `None` value', sway-ir/src/optimize/dce.rs:93:60
        //              note: run with `RUST_BACKTRACE=1` environment variable to display a backtrace
        let discount = _calc_discount(market);
        let spark_amount = 0; // todo calculate
        let vesting_time = _calc_vesting_time(market);
        //❌ Error: No method named "len" found for type "StorageKey<StorageVec<Vesting>>".
        // let index = storage.vestings.len();
        let vesting = Vesting {
            owner: msg_sender().unwrap(),
            spark_amount,
            duration: vesting_time,
            is_claimed: false,
            start_timestamp: 0,
        };
 
        //❌ Error: No method named "push" found for type "StorageKey<StorageVec<Vesting>>".
        // storage.vestings.push(vesting);
        _mint_spark(spark_amount);
    }
   
    //calculations
 #[storage(read)]
    fn is_claimed(_index: u64) -> bool { //todo
        false
    }
    #[storage(read)]
    fn calc_discount(market: ContractId) -> u64 {
        _calc_discount(market)
    }
    #[storage(read)]
    fn calc_vesting_time(market: ContractId) -> u64 {
        _calc_vesting_time(market)
    }
    fn calc_max_bond_amount(market: ContractId) -> u64 { //todo
        _calc_max_bond_amount(market)
    }
   
    //getters
 #[storage(read)]
    fn get_discount_factor() -> u64 {
        storage.discount_factor.read()
    }
    #[storage(read)]
    fn get_base_discount_rate(market: ContractId) -> u64 {
        _get_base_discount_rate(market)
    }
    #[storage(read)]
    fn get_market_needs(market: ContractId) -> u64 {
        _get_market_needs(market)
    }
    fn get_spread_factor(market: ContractId) -> u64 {
        _get_spread_factor(market)
    }
}
//internal funcs
#[storage(read)]
fn _calc_discount(market: ContractId) -> u64 {
    let base_discount_rate = storage.base_discount_rates.get(market).read();
    let market_needs = storage.market_needs.get(market).read();
    let discount_factor = storage.discount_factor.read();
    base_discount_rate * discount_factor * market_needs //todo bring to a denominator
}
fn _mint_spark(_spark_amount: u64) {} //todo
// #[storage(read)]
fn _calc_vesting_time(market: ContractId) -> u64 {
    1 + (365 - 1) * (1 - _get_spread_factor(market)) //todo bring to a denominator
}
fn _calc_max_bond_amount(_market: ContractId) -> u64 { //todo
    // let price = _get_price(market);
    // let spread_factor = _get_spread_factor(market);
    // let tvl=_get_tvl_amount(market);
    1000
}
//todo
fn _get_spread_factor(_market: ContractId) -> u64 { //decimals 2
    //ETH(bid)-USDC(ask)
    // if ask_price > bid_price {
    //     (ask_price - bid_price) / ask_price 
    // }else {
    //     0
    // }
    0
}
//todo
// fn _get_tvl_amount(_market: ContractId) -> u64 { //decimals of usdc 6
//     100_000_000_000 //100k
// }
#[storage(read)]
fn _get_base_discount_rate(market: ContractId) -> u64 {
    storage.base_discount_rates.get(market).read()
}
#[storage(read)]
fn _get_market_needs(market: ContractId) -> u64 {
    storage.market_needs.get(market).read()
}
fn _get_price(asset: ContractId) -> u64 { //decimals 9
    1900_000_000_000
}
