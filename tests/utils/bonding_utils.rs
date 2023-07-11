use fuels::{
    accounts::wallet::WalletUnlocked,
    prelude::{abigen, Contract, LoadConfiguration, TxParameters},
};

abigen!(Contract(
    name = "BondingContract",
    abi = "out/debug/bonding-abi.json"
),);

pub async fn deploy_bonding_contract(admin: &WalletUnlocked) -> BondingContract<WalletUnlocked> {
    let configurables = BondingContractConfigurables::new().set_ADMIN(admin.address().into());
    let id = Contract::load_from(
        "./out/debug/bonding.bin",
        LoadConfiguration::default().set_configurables(configurables),
    )
    .unwrap()
    .deploy(admin, TxParameters::default())
    .await
    .unwrap();
    BondingContract::new(id.clone(), admin.clone())
}
