# 42. SimpleSwap - DEX (Constant Product AMM)

## Overview

This project implements a Simple Decentralized Exchange (DEX) based on Constant Product Automated Market Maker (CPAMM).

## Contract

The main contract `SimpleSwap` inherits from ERC20 and provides:
- **addLiquidity**: Add liquidity to the pool and mint LP tokens
- **removeLiquidity**: Remove liquidity and burn LP tokens
- **swap**: Swap between two tokens
- **getAmountOut**: Calculate the amount out for a given amount in

## Key Formulas

- **LP Share (First liquidity)**: `L = sqrt(x * y)`
- **LP Share (Subsequent)**: `L = min(amount0/reserve0, amount1/reserve1) * totalSupply`
- **Swap**: `k = x * y` (constant product), `amountOut = amountIn * reserveOut / (reserveIn + amountIn)`

## References

- Uniswap V2 Core: https://github.com/Uniswap/v2-core