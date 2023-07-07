contract;
use std::constants::ZERO_B256;
use std::call_frames::msg_asset_id;
use std::context::msg_amount;

configurables {
    SPARK_ADDRESS = Address = Address::from(ZERO_B256);
}

storage {
    discount_factor: u64 = 100, //decimals = 2
    base_discount_rates: StorageMap<ContractId, u64> = StorageMap {}, //decimals = 2
    market_needs: StorageMap<ContractId, u64> = StorageMap {}, //decimals = 2
    admin: Address = Address::from(ZERO_B256),
    vestings: StorageVec<(Address, u64, u64, bool)> = StorageVec {}, //todo make as a struct
    vestings_by_address: StorageMap<Address, StorageVec<u64>> = StorageMap {}
}

struct InitParams {
    discount_factor: Option<u64>,
    market_needs: [Option<(ContractId, u64)>; 5],
    base_discount_rates: [Option<(ContractId, u64)>; 5],
}

abi BondingContract {
    #[storage(read, write)]
    fn init(params: InitParams);

    #[storage(read, write)]
    fn bond(market: ContractId);
    
    #[storage(read, write)]
    fn claim(index: u64);

    //calculations
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
    #[storage(read, write)]
    fn init(params: InitParams) {
        assert(storage.admin.read() == Address::from(ZERO_B256));
        let sender: Address= msg_sender().into();
        storage.admin.set(sender);

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

    #[storage(read, write)]
    fn bond(market: ContractId) { //todo
        assert(storage.admin.read() != Address::from(ZERO_B256));
        assert(msg_asset_id() == market);
        
        let amount = msg_amount();
        let max_bond_amount = _calc_max_bond_amount(market);
        assert(amount <= max_bond_amount);

        let spark_price = _get_price(SPARK_ADDRESS);
        let market_asset_price = _get_price(market);
        let discount = _calc_discount(market);
        let spark_amount = 0;// todo calculate
        let sender: Address = msg_sender().into();

        let vesting_time = _calc_vesting_time(market);
        let index = storage.vestings.len();
        storage.vestings.push((sender, spark_amount, vesting_time, false));
        let indexes = storage.vestings_by_address.get(sender).push(index);
        storage.vestings_by_address.insert(sender, indexes);

        _mint_spark(spark_amount);
    }

fn claim(index: u64);

    //calculations
    #[storage(read)]
    fn is_claimed(index: u64) -> bool{
        false
    };
    #[storage(read)]
    fn calc_discount(market: ContractId) -> u64 {
      _calc_discount(market)  
    }
    #[storage(read)]
    fn calc_vesting_time(market: ContractId) -> u64 {
       _calc_vesting_time(market) 
    }
    fn calc_max_bond_amount(market: ContractId) -> u64 {//todo
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

        base_discount_rate * discount_factor * market_needs //todo привести к знаменателю
    }
    #[storage(read)]
    fn _calc_vesting_time(market: ContractId) -> u64 {
        1 + (365 - 1) * (1 - _get_spread_factor(market))//todo привести к знаменателю
    }
    fn _calc_max_bond_amount(market: ContractId) -> u64 {//todo
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
fn _get_price(asset: ContractId) -> u64 {//decimals 9
        1900_000_000_000
}