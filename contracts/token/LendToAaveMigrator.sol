// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.10;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "../open-zeppelin/SafeMath.sol";
import {VersionedInitializable} from "../utils/VersionedInitializable.sol";

/**
 * @title LendToAaveMigrator
 * @notice Implements the migration from LEND to AAVE
 * @dev Proxy-initialized via VersionedInitializable
 */
contract LendToAaveMigrator is VersionedInitializable {
  using SafeMath for uint256;

  IERC20 public immutable AAVE;
  IERC20 public immutable LEND;
  uint256 public immutable LEND_AAVE_RATIO;
  uint256 public constant REVISION = 1;

  uint256 public _totalLendMigrated;

  /**
   * @dev Emitted on every migration call
   * @param sender Caller performing the migration
   * @param amount Amount of LEND migrated (in LEND units)
   * @param aaveOut Amount of AAVE sent (in AAVE units)
   */
  event LendMigrated(address indexed sender, uint256 indexed amount, uint256 indexed aaveOut);

  /**
   * @param aave The AAVE token address
   * @param lend The LEND token address
   * @param lendAaveRatio The exchange rate LEND:AAVE (e.g. 100 means 100 LEND -> 1 AAVE)
   */
  constructor(IERC20 aave, IERC20 lend, uint256 lendAaveRatio) public {
    require(address(aave) != address(0), "AAVE_ZERO");
    require(address(lend) != address(0), "LEND_ZERO");
    require(lendAaveRatio > 0, "RATIO_ZERO");
    AAVE = aave;
    LEND = lend;
    LEND_AAVE_RATIO = lendAaveRatio;
  }

  /**
   * @dev Initializes the implementation (proxy pattern)
   */
  function initialize() public initializer {}

  /**
   * @dev Returns true if migration has started (contract initialized via proxy)
   */
  function migrationStarted() external view returns (bool) {
    return lastInitializedRevision != 0;
  }

  /**
   * @dev Executes migration from LEND to AAVE
   *      Caller must approve this contract to spend their LEND beforehand
   * @param amount Amount of LEND to migrate
   */
  function migrateFromLEND(uint256 amount) external {
    require(lastInitializedRevision != 0, "MIGRATION_NOT_STARTED");
    require(amount > 0, "ZERO_AMOUNT");

    // Pull LEND from user
    require(LEND.transferFrom(msg.sender, address(this), amount), "LEND_PULL_FAIL");

    // Calculate AAVE out (integer division truncates dust by design)
    uint256 aaveOut = amount.div(LEND_AAVE_RATIO);
    require(aaveOut > 0, "INSUFFICIENT_FOR_1_AAVE");

    // Send AAVE to user
    require(AAVE.transfer(msg.sender, aaveOut), "AAVE_SEND_FAIL");

    // Bookkeeping
    _totalLendMigrated = _totalLendMigrated.add(amount);

    emit LendMigrated(msg.sender, amount, aaveOut);
  }

  /**
   * @dev Implementation revision
   */
  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }
}
