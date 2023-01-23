pragma solidity ^0.8.10;

interface DelegationRegistry {
    event DelegateForAll(address vault, address delegate, bool value);
    event DelegateForContract(address vault, address delegate, address contract_, bool value);
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);
    event RevokeAllDelegates(address vault);
    event RevokeDelegate(address vault, address delegate);

    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    struct DelegationInfo {
        uint8 type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    function checkDelegateForAll(address delegate, address vault) external view returns (bool);
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
    function delegateForAll(address delegate, bool value) external;
    function delegateForContract(address delegate, address contract_, bool value) external;
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory contractDelegations);
    function getDelegatesForAll(address vault) external view returns (address[] memory delegates);
    function getDelegatesForContract(address vault, address contract_)
        external
        view
        returns (address[] memory delegates);
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory delegates);
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory info);
    function getTokenLevelDelegations(address vault)
        external
        view
        returns (TokenDelegation[] memory tokenDelegations);
    function revokeAllDelegates() external;
    function revokeDelegate(address delegate) external;
    function revokeSelf(address vault) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

