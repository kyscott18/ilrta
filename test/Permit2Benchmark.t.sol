// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Permit2} from "permit2/src/Permit2.sol";
import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockERC20 is ERC20("Test ERC20", "TEST", 18) {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

contract Permit2BenchmarkTest is Test {
    Permit2 private permit2;
    MockERC20 private erc20;

    bytes32 public constant TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        // solhint-disable-next-line max-line-length
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    function setUp() external {
        permit2 = new Permit2();
        erc20 = new MockERC20();
    }

    function testGasTransferBySignature() external {
        vm.pauseGasMetering();
        uint256 privateKey = 0xC0FFEE;
        address owner = vm.addr(privateKey);
        erc20.mint(address(owner), 1e18);

        vm.prank(owner);
        erc20.approve(address(permit2), 1e18);

        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: address(erc20), amount: 1e18}),
            nonce: 0,
            deadline: block.timestamp
        });

        ISignatureTransfer.SignatureTransferDetails memory transferDetails =
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: 1e18});

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    permit2.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            PERMIT_TRANSFER_FROM_TYPEHASH,
                            keccak256(abi.encode(TOKEN_PERMISSIONS_TYPEHASH, permit.permitted)),
                            address(this),
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bytes memory signature = abi.encodePacked(r, s, v);

        vm.resumeGasMetering();

        permit2.permitTransferFrom(permit, transferDetails, owner, signature);
    }
}
