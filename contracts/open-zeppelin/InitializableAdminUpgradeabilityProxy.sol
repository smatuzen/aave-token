// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.10;

import "./BaseAdminUpgradeabilityProxy.sol";
import "./InitializableUpgradeabilityProxy.sol";

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer for
 *      setting the implementation, admin, and initialization data.
 */
contract InitializableAdminUpgradeabilityProxy is
  BaseAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  /**
   * @notice Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _admin Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   *        It should include the signature and the parameters of the function to be called, as described in
   *        https://docs.soliditylang.org/en/v0.6.12/abi-spec.html#function-selector-and-argument-encoding.
   *        This parameter is optional; if no data is provided, the initialization call to the proxied contract will be skipped.
   */
  function initialize(
    address _logic,
    address _admin,
    bytes memory _data
  ) public payable {
    require(_implementation() == address(0), "Already initialized");
    InitializableUpgradeabilityProxy.initialize(_logic, _data);
    // EIP-1967 admin slot check
    assert(ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
    _setAdmin(_admin);
  }

  /**
   * @dev Only fallback when the sender is not the admin.
   */
  function _willFallback()
    internal
    override(BaseAdminUpgradeabilityProxy, Proxy)
  {
    BaseAdminUpgradeabilityProxy._willFallback();
  }
}
