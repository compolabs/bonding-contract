use fuels::{
    accounts::wallet::WalletUnlocked,
    prelude::{abigen, Contract, LoadConfiguration, TxParameters, BASE_ASSET_ID},
    test_helpers::{launch_custom_provider_and_get_wallets, WalletsConfig},
    types::{AssetId, ContractId},
};
use src20_sdk::{deploy_token_contract, DeployTokenConfig};

// Load abi from json
abigen!(Contract(
    name = "BondingContract",
    abi = "out/debug/bonding-abi.json"
));
const FRC20_BIN_PATH: &str = "artefacts/FRC20.bin";

#[tokio::test]
async fn can_get_contract_id() {
    let config = WalletsConfig::new(Some(1), Some(1), Some(1_000_000_000));
    let wallets = launch_custom_provider_and_get_wallets(config, None, None).await;
    let admin = wallets[0].clone();
    //
    let btc_config = &DeployTokenConfig {
        name: "Bitcoin".to_owned(),
        symbol: "BTC".to_owned(),
        decimals: 8,
    };
    let btc = deploy_token_contract(&admin, btc_config, FRC20_BIN_PATH).await;
    let btc_asset_id = AssetId::from(*ContractId::from(btc.contract_id()));

    let ltc_config = &DeployTokenConfig {
        name: "Litecoin".to_owned(),
        symbol: "LTC".to_owned(),
        decimals: 9,
    };
    let ltc = deploy_token_contract(&admin, ltc_config, FRC20_BIN_PATH).await;
    let ltc_asset_id = AssetId::from(*ContractId::from(ltc.contract_id()));

    let xrp_config = &DeployTokenConfig {
        name: "XRP Token".to_owned(),
        symbol: "XRP".to_owned(),
        decimals: 9,
    };
    let xrp = deploy_token_contract(&admin, xrp_config, FRC20_BIN_PATH).await;
    let xrp_asset_id = AssetId::from(*ContractId::from(xrp.contract_id()));

    let trx_config = &DeployTokenConfig {
        name: "TRON Token".to_owned(),
        symbol: "XRP".to_owned(),
        decimals: 6,
    };
    let trx = deploy_token_contract(&admin, trx_config, FRC20_BIN_PATH).await;
    let trx_asset_id = AssetId::from(*ContractId::from(trx.contract_id()));

    let spark_config = &DeployTokenConfig {
        name: "Spark Token".to_owned(),
        symbol: "SPARK".to_owned(),
        decimals: 9,
    };
    let spark = deploy_token_contract(&admin, spark_config, FRC20_BIN_PATH).await;
    let spark_asset_id = AssetId::from(*ContractId::from(spark.contract_id()));

    //
    let configurables = BondingContractConfigurables::new().set_ADMIN(admin.address().into());
    let id = Contract::load_from(
        "./out/debug/bonding.bin",
        LoadConfiguration::default().set_configurables(configurables),
    )
    .unwrap()
    .deploy(&admin, TxParameters::default())
    .await
    .unwrap();
    let bonding_methods: BondingContractMethods<WalletUnlocked> =
        BondingContract::new(id.clone(), admin.clone()).methods();

    let config = BondingContractInitConfig {
        market_needs: [
            Some((btc.contract_id().into(), 400)),         //BTC market: 40%
            Some((ContractId::from(*BASE_ASSET_ID), 200)), //ETH market: 20%
            Some((ltc.contract_id().into(), 300)),         //LTC market: 30%
            Some((xrp.contract_id().into(), 250)),         //XRP market: 25%
            Some((trx.contract_id().into(), 150)),         //TRON market: 15%
        ],
        base_discount_rates: [
            Some((btc.contract_id().into(), 100)), //BTC market: 10% base discount
            Some((ContractId::from(*BASE_ASSET_ID), 80)), //ETH market: 8% base discount
            Some((ltc.contract_id().into(), 70)),  //LTC market: 7% base discount
            Some((xrp.contract_id().into(), 90)),  //XRP market: 9% base discount
            Some((trx.contract_id().into(), 60)),  //TRON market: 6% base discount
        ],
    };
    bonding_methods.init(config).call().await.unwrap();
}
