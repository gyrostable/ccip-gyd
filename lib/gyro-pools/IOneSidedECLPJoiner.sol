// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/concentrated-lps>.

// pragma solidity ^0.7.6;

/// @notice A stateless helper contract to join an ECLP pool with only one of the two assets.
///
/// This is slightly inaccurate right now, i.e., not all assets are used due incomplete accounting for fees.
interface IOneSidedECLPJoiner {
    /** @notice Perform a swap-join combination to join the pool only with the `tokenInAddress`
     * asset. LP shares and leftover assets are sent to `beneficiary`. An approval needs to be
     * set up.
     *
     * @param poolAddress Address of the pool to join
     * @param tokenInAddress Address of the token to deposit. Must be one of the tokens of the
     * pool.
     * @param tokenInAmountRaw Token amount to deposit. Not scaled by decimals or rates.
     * @param beneficiary Address to receive the LP shares and any leftover tokens.
     */
    function joinECLPOneSided(
        address poolAddress,
        address tokenInAddress,
        uint256 tokenInAmountRaw,
        address beneficiary
    ) external;

    /** @notice Variant of `joinECLPOneSided()` where (1) this contract needs to be prefunded with
     * the amount of `tokenInAddress` and the whole amount will be used and (2) this never reverts
     * unless something is wrong with the `tokenInAddress` or the transfer functions of the involved
     * tokens are broken. In case an inner function reverts, all token amounts held are sent to
     * `beneficiary`.
     *
     * This is to be used as together with the GYD CCIP bridge's function call feature.
     */
    function joinECLPOneSidedCCIP(
        address poolAddress,
        address tokenInAddress,
        address beneficiary
    ) external;

    /// @notice Emitted by `joinECLPOneSidedCCIP` if execution failed in an inner call.
    event ExecutionFailed(string reason, address beneficiary);
    event ExecutionFailed(bytes data, address beneficiary);
}
