contract;
use std::constants::ZERO_B256;

storage {
    discount_factor: u64 = 100, //decimals = 2
    base_discount_rates: StorageMap<ContractId, u64> = StorageMap {}, //decimals = 2
    //map of latest ask trades for markets
    // ask_prices: StorageMap<ContractId, u64> = StorageMap {}, //decimals = 2
    // map of latest bid trades for markets
    // bid_prices: StorageMap<ContractId, u64> = StorageMap {}, //decimals = 2
    market_needs: StorageMap<ContractId, u64> = StorageMap {}, //decimals = 2
    admin: Address = Address::from(ZERO_B256),
}

struct InitParams {
    discount_factor: Option<u64>,
    market_needs: [Option<(ContractId, u64)>; 5],
    base_discount_rates: [Option<(ContractId, u64)>; 5],
    // ask_prices: [Option<(ContractId, u64)>; 5],
    // bid_prices: [Option<(ContractId, u64)>; 5],
}

abi BondingContract {
    #[storage(write)]
    fn init(params: InitParams);

    #[storage(read)]
    fn bond();

    //calculations
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
            i +=1;
        }
    }

    #[storage(read)]
    fn bond() { //todo
        assert(storage.admin.read() != Address::from(ZERO_B256));
    }
    //calculations
    #[storage(read)]
    fn calc_discount(market: ContractId) -> u64 {
        let base_discount_rate = storage.base_discount_rates.get(market).read();
        let market_needs = storage.market_needs.get(market).read();
        let discount_factor = storage.discount_factor.read();

        base_discount_rate * discount_factor * market_needs //todo привести к знаменателю
    }
    #[storage(read)]
    fn calc_vesting_time(market: ContractId) -> u64 {
        1 + (365 - 1) * (1 - _get_spread_factor(market))//todo привести к знаменателю
    }
    fn calc_max_bond_amount(market: ContractId) -> u64 {
        let price = _get_price(market);
        let spread_factor = _get_spread_factor(market);
        let tvl=_get_tvl_amount(market);
        // tvl * spread_factor * price; //todo
        0
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
//todo
fn _get_spread_factor(_market: ContractId) -> u64 { //decimals 2
    // if ask_price > bid_price {
    //     (ask_price - bid_price) / ask_price 
    // }else {
    //     0
    // }
    50
}
//todo
fn _get_tvl_amount(_market: ContractId) -> u64 { //decimals of usdc 6
    100_000_000_000 //100k
}
#[storage(read)]
fn _get_base_discount_rate(market: ContractId) -> u64 {
        storage.base_discount_rates.get(market).read()
}
#[storage(read)]
fn _get_market_needs(market: ContractId) -> u64 {
        storage.market_needs.get(market).read()
}
#[storage(read)]
fn _get_price(asset: ContractId) -> u64 {//decimals 9
        1900_000_000_000;
}