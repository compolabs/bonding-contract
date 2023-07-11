mod utils;
use fuels::{
    prelude::BASE_ASSET_ID,
    test_helpers::{launch_custom_provider_and_get_wallets, WalletsConfig},
    types::ContractId,
};

use crate::utils::*;

#[tokio::test]
async fn main_test() {
    let config = WalletsConfig::new(Some(1), Some(1), Some(1_000_000_000));
    let wallets = launch_custom_provider_and_get_wallets(config, None, None).await;
    let admin = wallets[0].clone();

    let tokens = token_utils::deploy_tokens(&admin).await;

    let bonding = bonding_utils::deploy_bonding_contract(&admin).await;
    let oracle = oracle_utils::deploy_oracle_contract(&admin).await;
    oracle_utils::init_oracle(&oracle, &tokens).await;

    //FIXME calculate on a contract side
    let config = bonding_utils::BondingContractInitConfig {
        market_needs: [
            Some((tokens.get("BTC").unwrap().contract_id().into(), 400)), //BTC market: 40%
            Some((ContractId::from(*BASE_ASSET_ID), 200)),                //ETH market: 20%
            Some((tokens.get("LTC").unwrap().contract_id().into(), 300)), //LTC market: 30%
            Some((tokens.get("XRP").unwrap().contract_id().into(), 250)), //XRP market: 25%
            Some((tokens.get("TRX").unwrap().contract_id().into(), 150)), //TRON market: 15%
        ],
        base_discount_rates: [
            Some((tokens.get("BTC").unwrap().contract_id().into(), 100)), //BTC market: 10% base discount
            Some((ContractId::from(*BASE_ASSET_ID), 80)), //ETH market: 8% base discount
            Some((tokens.get("LTC").unwrap().contract_id().into(), 70)), //LTC market: 7% base discount
            Some((tokens.get("XRP").unwrap().contract_id().into(), 90)), //XRP market: 9% base discount
            Some((tokens.get("TRX").unwrap().contract_id().into(), 60)), //TRON market: 6% base discount
        ],
    };
    bonding.methods().init(config).call().await.unwrap();

    //todo
    // orderbook deploy
    // main test case
}
