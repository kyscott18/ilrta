// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ILRTA } from "src/ILRTA.sol";
import { SignatureVerification } from "permit2/libraries/SignatureVerification.sol";

abstract contract ILRTAFungibleToken is ILRTA {
    /*(((((((((((((((((((((((((((EVENTS)))))))))))))))))))))))))))*/

    event Transfer(address from, address to, uint256 amount);

    /*(((((((((((((((((((((((((((ERRORS)))))))))))))))))))))))))))*/

    error SignatureExpired(uint256 signatureDeadline);

    error InvalidAmount(uint256 maxAmount);

    /*((((((((((((((((((((((METADATA STORAGE))))))))))))))))))))))*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*(((((((((((((((((((((((((((STORAGE))))))))))))))))))))))))))*/

    uint256 public totalSupply;

    mapping(address owner => uint256 balance) public dataOf;

    /*((((((((((((((((((((((SIGNATURE STORAGE)))))))))))))))))))))*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*(((((((((((((((((((((((((CONSTRUCTOR))))))))))))))))))))))))*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*(((((((((((((((((((((((((ILRTA LOGIC))))))))))))))))))))))))*/

    function balanceOf(address owner) external view returns (uint256 balance) {
        return dataOf[owner];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        dataOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            dataOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    struct TransferData {
        uint256 amount;
        uint256 nonce;
        uint256 deadline;
    }

    struct TransferDetails {
        address to;
        uint256 requestedAmount;
    }

    /// @custom:team look at unordered nonces
    function transferBySignature(
        address from,
        TransferData memory transferData,
        TransferDetails calldata transferDetails,
        bytes calldata signature
    )
        external
        returns (bool)
    {
        uint256 requestedAmount = transferDetails.requestedAmount;

        if (block.timestamp > transferData.deadline) revert SignatureExpired(transferData.deadline);
        if (requestedAmount > transferData.amount) revert InvalidAmount(transferData.amount);

        bytes32 signatureHash;

        unchecked {
            signatureHash = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "Transfer(address from,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                            ),
                            from,
                            msg.sender,
                            transferData.amount,
                            nonces[from]++,
                            transferData.deadline
                        )
                    )
                )
            );
        }

        SignatureVerification.verify(signature, signatureHash, from);

        dataOf[from] -= requestedAmount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            dataOf[transferDetails.to] += requestedAmount;
        }

        emit Transfer(from, transferDetails.to, requestedAmount);

        return true;
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /*(((((((((((((((((((((((INTERNAL LOGIC)))))))))))))))))))))))*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            dataOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        dataOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}
