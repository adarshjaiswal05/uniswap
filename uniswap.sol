// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./library.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract Uniswap {
    address private constant FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant UNISWAP_V2_ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private WETH = IUniswapV2Router02(UNISWAP_V2_ROUTER).WETH();
  
    event AddLiquidity(
        address indexed tokenA,
        address indexed tokenB,
        uint256 indexed amount0,
        uint256 amount1,
        uint256 liquidityTokens
    );
    event RemoveLiquidity(address indexed tokenA, address indexed tokenB);
    event Swap(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 indexed amountIn,
        uint256 amountOutMin,
        address to
    );
    event AddLiquidityETH(
        address indexed tokenA,
        uint256 indexed amountTokenDesired,
        uint256 indexed amountTokenMin,
        uint256 amountETHMin,
        address to
    );
    event RemoveLiquidityETH(address indexed tokenA, address indexed tokenB);

    function addLiquidity(
        address token1,
        address token2,
        uint256 amount1,
        uint256 amount2
    ) external returns (uint256) {
        require(amount1 > 0 && amount2 > 0, "Please deposite some amount");
        require(
            token1 != address(0) && token2 != address(0),
            "zero address sent"
        );

        // require(IERC20(token1).balanceOf(msg.sender)>=amount1,"no enough token1 in your account");
        // require(IERC20(token2).balanceOf(msg.sender)>=amount2,"no enough token2 in your account");

        IERC20(token1).transferFrom(msg.sender, address(this), amount1);
        IERC20(token2).transferFrom(msg.sender, address(this), amount2);

        IERC20(token1).approve(UNISWAP_V2_ROUTER, amount1);
        IERC20(token2).approve(UNISWAP_V2_ROUTER, amount2);

        (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        ) = IUniswapV2Router02(UNISWAP_V2_ROUTER).addLiquidity(
                token1,
                token2,
                amount1,
                amount2,
                1,
                1,
                msg.sender,
                block.timestamp + 5 minutes
            );

        emit AddLiquidity(token1, token2, amountA, amountB, liquidity);
        return liquidity;
    }

    function addLiquidityETH(
        address tokenIn,
        uint256 amountTokenInDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin
    ) external payable {
        IERC20(tokenIn).transferFrom(
            msg.sender,
            address(this),
            amountTokenInDesired
        );
        IERC20(tokenIn).approve(UNISWAP_V2_ROUTER, amountTokenInDesired);

        IUniswapV2Router02(UNISWAP_V2_ROUTER).addLiquidityETH{value: msg.value}(
            tokenIn,
            amountTokenInDesired,
            amountTokenMin,
            amountETHMin,
            msg.sender,
            block.timestamp
        );

        emit AddLiquidityETH(tokenIn, amountTokenInDesired, 0, 0, msg.sender);
    }

    function removeLiquidityETH(address tokenA, uint256 liquidity)
        external
        returns (uint256, uint256)
    {
        address pair = IUniswapV2Factory(FACTORY).getPair(tokenA, WETH);

        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(UNISWAP_V2_ROUTER, liquidity);

        (uint256 tokenAmount, uint256 ethAmount) = IUniswapV2Router02(
            UNISWAP_V2_ROUTER
        ).removeLiquidityETH(
                tokenA,
                liquidity,
                1,
                1,
                msg.sender,
                block.timestamp + 5 minutes
            );
        return (tokenAmount, ethAmount);
    }

    function removeLiquidity(
        address token1,
        address token2,
        uint256 liquidity
    ) public {
        require(liquidity > 0, "Please send some liquidity amount");
        require(
            token1 != address(0) && token2 != address(0),
            "zero address sent"
        );

        address pair = IUniswapV2Factory(FACTORY).getPair(token1, token2);
        // uint liquidity=IERC20(pair).balanceOf(msg.sender);

        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(UNISWAP_V2_ROUTER, liquidity);

        IUniswapV2Router02(UNISWAP_V2_ROUTER).removeLiquidity(
            token1,
            token2,
            liquidity,
            0,
            0,
            msg.sender,
            block.timestamp + 5 minutes
        );

        emit RemoveLiquidity(token1, token2);
    }

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        address pair = IUniswapV2Factory(FACTORY).getPair(tokenA, tokenB);
        IUniswapV2Pair(pair).permit(
            msg.sender,
            address(this),
            liquidity,
            deadline,
            v,
            r,
            s
        );
        removeLiquidity(tokenA, tokenB, liquidity);

        // IUniswapV2Router02(UNISWAP_V2_ROUTER).removeLiquidityWithPermit(
        //      tokenA, tokenB, liquidity, 0, 0, msg.sender, deadline,false,v,r,s);
    }

    function directSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutmin,
        address _to
    ) external {
        require(
            tokenIn != address(0) &&
                tokenOut != address(0) &&
                _to != address(0),
            "zero address sent"
        );
        require(amountIn > 0, "Please send some amount to swap");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(UNISWAP_V2_ROUTER, amountIn);

        address[] memory path;
        path = new address[](2);
        path[0] = tokenIn;
        //path[1]= WETH;
        path[1] = tokenOut;

        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            amountIn,
            amountOutmin,
            path,
            _to,
            block.timestamp + 5 minutes
        );
        emit Swap(tokenIn, tokenOut, amountIn, amountOutmin, _to);
    }

    function ethSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutmin,
        address _to
    ) external {
        require(
            tokenIn != address(0) &&
                tokenOut != address(0) &&
                _to != address(0),
            "zero address sent"
        );
        require(amountIn > 0, "Please send some amount to swap");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(UNISWAP_V2_ROUTER, amountIn);

        address[] memory path;
        path = new address[](3);
        path[0] = tokenIn;
        path[1] = WETH;
        path[2] = tokenOut;

        IUniswapV2Router02(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            amountIn,
            amountOutmin,
            path,
            _to,
            block.timestamp + 5 minutes
        );
        emit Swap(tokenIn, tokenOut, amountIn, amountOutmin, _to);
    }

    function getLPTokenBalance(address token1, address token2)
        external
        view
        returns (uint256)
    {
        address pair = IUniswapV2Factory(FACTORY).getPair(token1, token2);
        uint256 balance = IERC20(pair).balanceOf(msg.sender);
        return balance;
    }

    function getEthLPTokenBalance(address token1)
        external
        view
        returns (uint256)
    {
        address pair = IUniswapV2Factory(FACTORY).getPair(token1, WETH);
        uint256 balance = IERC20(pair).balanceOf(msg.sender);
        return balance;
    }

    function getPairAddress(address token1, address token2)
        external
        view
        returns (address)
    {
        address pair = IUniswapV2Factory(FACTORY).getPair(token1, token2);
        return pair;
    }

    function getEthPairAddress(address token1) external view returns (address) {
        address pair = IUniswapV2Factory(FACTORY).getPair(token1, WETH);
        return pair;
    }

    function getTokenbalance(address lpPair) external view returns (uint256) {
        return IERC20(lpPair).balanceOf(msg.sender);
    }
}
