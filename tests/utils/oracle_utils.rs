use fuels::{
    accounts::wallet::WalletUnlocked,
    prelude::{abigen, Bech32ContractId, Contract, LoadConfiguration, TxParameters, BASE_ASSET_ID},
    types::ContractId,
};
use src20_sdk::TokenContract;
use std::collections::HashMap;

abigen!(Contract(
    name = "OracleContract",
    abi = "artefacts/oracle-abi.json"
));

pub async fn init_oracle(
    oracle: &OracleContract<WalletUnlocked>,
    tokens: &HashMap<String, TokenContract<WalletUnlocked>>,
) {
    let price_config_json_str = std::fs::read_to_string("tests/prices.json").unwrap();
    let price_configs: HashMap<String, f64> =
        serde_json::from_str(price_config_json_str.as_str()).unwrap();
    for (symbol, price) in price_configs {
        let asset_id: Bech32ContractId = if symbol == "ETH" {
            Bech32ContractId::from(ContractId::from(*BASE_ASSET_ID))
        } else {
            tokens.get(&symbol).unwrap().contract_id().clone()
        };
        let price = (price * 10f64.powf(9f64)) as u64;
        oracle
            .methods()
            .set_price(asset_id, price)
            .call()
            .await
            .unwrap();
    }
}

pub async fn deploy_oracle_contract(admin: &WalletUnlocked) -> OracleContract<WalletUnlocked> {
    let configurables = OracleContractConfigurables::new().set_ADMIN(admin.address().into());
    let id = Contract::load_from(
        "artefacts/oracle.bin",
        LoadConfiguration::default().set_configurables(configurables),
    )
    .unwrap()
    .deploy(admin, TxParameters::default())
    .await
    .unwrap();
    OracleContract::new(id.clone(), admin.clone())
}
