# Dookey4All

Dookey4All is a smart contract that is designed to trustlessly custody a SewerPass so that anyone may add themselves as a delegate of the smart contract and play the Dookey Dash game. 

Dookey4All is designed to trustlessly custody a single Sewer Pass when transferred to the smart contract via `safeTransferFrom`. The `onERC721Received` callback registers the original owner of the Sewer Pass as the "sponsor" as well as the token ID. The smart contract rejects all other tokens, and will reject subsequent attempts to transfer in additional Sewer Passes sent via `safeTransferFrom`.

The "sponsor" may withdraw their Sewer Pass at any time by calling `withdrawSewerPass`. This will transfer the Sewer Pass back to the sponsor, and the smart contract will again accept a single Sewer Pass via `safeTransferFrom`.

In the event that a Sewer Pass (or any other ERC20 or ERC721 token) is sent to the smart contract without calling `safeTransferFrom`, which registers the "sponsor" so that they may withdraw the token the original deployer has the ability to withdraw those tokens via `withdrawERC721`. This is a safety feature to prevent tokens from becoming locked in the smart contract, smart contract from being locked up with tokens that cannot be withdrawn. 

In the event a token is mistakenly sent using `transferFrom` and not `safeTransferFrom`, the mistaken sender must trust that the original deployer will withdraw the token and return it to them. If you are considering sponsoring Dookey4All, please be aware of this risk, and be especially careful to call the correct `safeTransferFrom` method when sending a Sewer Pass to the smart contract.