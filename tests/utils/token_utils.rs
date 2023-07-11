use fuels::accounts::wallet::WalletUnlocked;
use src20_sdk::{deploy_token_contract, DeployTokenConfig, TokenContract};
use std::collections::HashMap;

const FRC20_BIN_PATH: &str = "artefacts/FRC20.bin";

pub async fn deploy_tokens(
    admin: &WalletUnlocked,
) -> HashMap<String, TokenContract<WalletUnlocked>> {
    let deploy_config_json_str = std::fs::read_to_string("tests/tokens.json").unwrap();
    let deploy_configs: [DeployTokenConfig; 5] =
        serde_json::from_str(deploy_config_json_str.as_str()).unwrap();
    let mut tokens: HashMap<String, TokenContract<WalletUnlocked>> = HashMap::new();
    for config in deploy_configs {
        let token = deploy_token_contract(&admin, &config, FRC20_BIN_PATH).await;
        tokens.insert(config.symbol.clone(), token);
    }
    tokens
}
