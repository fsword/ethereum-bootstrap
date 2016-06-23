# Ethereum Bootstrap

基于![Ethereum Bootstrap](https://github.com/janx/ethereum-bootstrap)项目，通过一个简单的docker镜像为以太坊编程提供开发环境。
开发者使用自己的私链进行开发测试。

仓库中包含的工具有：

* 一个测试账户导入脚本，在首次部署时将五个测试账户私钥导入以太坊节点。
* 一个genesis.json配置文件，为对应的五个测试账户提供初始资金（以太币），方便开发测试。
* 一个快速启动私有链节点并进入交互模式的脚本。
* 一个合约样例：`contracts/Token.sol`。这是一个使用合约语言[Solidity](http://solidity.readthedocs.org/en/latest/)编写的智能合约。Token合约的功能是发行一种token（可以理解为货币，积分等等），只有合约的创建者有发行权，token的拥有者有使用权，并且可以自由转账。

**测试账户私钥是放在Github上的公开数据，千万不要用于正式环境中或者公有链上。如果在测试环境之外的地方使用这些私钥，你的资金将会被窃取！**

## 构建自己的docker镜像

* git clone https://github.com/fsword/ethereum-bootstrap.git
* cd ethereum-bootstrap
* docker build -t image-name .

## 环境准备

* docker run -v "/your-data-folder:/data" fsword/ethdev

## 使用以太坊控制台编译和部署智能合约

在`contracts`目录下有一个智能合约样例文件`Token.sol`, 通过Solidity语言实现了基本的代币功能, 合约持有者可以发行代币, 使用者可以互相转账.

我们可以使用以太坊控制台来编译部署这个合约．以太坊控制台是最基本的工具，使用会比较繁琐．社区也提供了其他更加方便的部署工具，此处不做讨论．

第一步，我们先把合约代码压缩为一行．新建一个ssh session, 切换到geth用户环境`su - geth`, 然后输入：`cat contracts/Token.sol | tr '\n' ' '`.

切换到以太坊控制台，把合约代码保存为一个变量:

```javascript
var tokenSource = 'contract Token {     address issuer;     mapping (address => uint) balances;      event Issue(address account, uint amount);     event Transfer(address from, address to, uint amount);      function Token() {         issuer = msg.sender;     }      function issue(address account, uint amount) {         if (msg.sender != issuer) throw;         balances[account] += amount;     }      function transfer(address to, uint amount) {         if (balances[msg.sender] < amount) throw;          balances[msg.sender] -= amount;         balances[to] += amount;          Transfer(msg.sender, to, amount);     }      function getBalance(address account) constant returns (uint) {         return balances[account];     } }';
```

然后编译合约代码：

```javascript
var tokenCompiled = web3.eth.compile.solidity(tokenSource);
```

通过`tokenCompiled.Token.code`可以看到编译好的二进制代码，通过`tokenCompiled.Token.info.abiDefinition`可以看到合约的[ABI](https://github.com/ethereum/wiki/wiki/Ethereum-Contract-ABI)．

接下来我们要把编译好的合约部署到网络上去．

首先我们用ABI来创建一个javascript环境中的合约对象：

```javascript
var contract = web3.eth.contract(tokenCompiled.Token.info.abiDefinition);
```

我们通过合约对象来部署合约：

```javascript
var initializer = {from: web3.eth.accounts[0], data: tokenCompiled.Token.code, gas: 300000};

var callback = function(e, contract){
    if(!e) {
      if(!contract.address) {
        console.log("Contract transaction send: TransactionHash: " + contract.transactionHash + " waiting to be mined...");
      } else {
        console.log("Contract mined!");
        console.log(contract);
      }
    }
};

var token = contract.new(initializer, callback);
```

`contract.new`方法的第一个参数设置了这个新合约的创建者地址`from`, 这个新合约的代码`data`, 和用于创建新合约的费用`gas`．`gas`是一个估计值，只要比所需要的gas多就可以，合约创建完成后剩下的gas会退还给合约创建者．

`contract.new`方法的第二个参数设置了一个回调函数，可以告诉我们部署是否成功．

`contract.new`执行时会提示输入钱包密码．执行成功后，我们的合约Token就已经广播到网络上了．此时只要等待矿工把我们的合约打包保存到以太坊区块链上，部署就完成了．

在公有链上，矿工打包平均需要15秒，在私有链上，我们需要自己来做这件事情．首先开启挖矿：

```javascript
miner.start(1)
```

此时需要等待一段时间，以太坊节点会生成挖矿必须的数据，这些数据都会放到内存里面．在数据生成好之后，挖矿就会开始，稍后就能在控制台输出中看到类似：

```
:hammer:Mined block
```

的信息，这说明挖到了一个块，合约已经部署到以太坊网络上了！此时我们可以把挖矿关闭：

```javascript
miner.stop(1)
```

接下来我们就可以调用合约了．先通过`token.address`获得合约部署到的地址, 以后新建合约对象时可以使用．这里我们直接使用原来的contract对象：

```
// 本地钱包的第一个地址所持有的token数量
> token.getBalance(web3.eth.accounts[0])
0

// 发行100个token给本地钱包的第一个地址
> token.issue.sendTransaction(web3.eth.accounts[0], 100, {from: web3.eth.accounts[0]});
I1221 11:48:30.512296   11155 xeth.go:1055] Tx(0xc0712460a826bfea67d58a30f584e4bebdbb6138e7e6bc1dbd6880d2fce3a8ef) to: 0x37dc85ae239ec39556ae7cc35a129698152afe3c
"0xc0712460a826bfea67d58a30f584e4bebdbb6138e7e6bc1dbd6880d2fce3a8ef"

// 发行token是一个transaction, 因此需要挖矿使之生效
> miner.start(1)
:hammer:Mined block
> miner.stop(1)

// 再次查询本地钱包第一个地址的token数量
> token.getBalance(web3.eth.accounts[0])
100

// 从第一个地址转30个token给本地钱包的第二个地址
> token.transfer.sendTransaction(web3.eth.accounts[1], 30, {from: web3.eth.accounts[0]})
I1221 11:53:31.852541   11155 xeth.go:1055] Tx(0x1d209cef921dea5592d8604ac0da680348987b131235943e372f8df35fd43d1b) to: 0x37dc85ae239ec39556ae7cc35a129698152afe3c
"0x1d209cef921dea5592d8604ac0da680348987b131235943e372f8df35fd43d1b"
> miner.start(1)
> miner.stop(2)
> token.getBalance(web3.eth.accounts[0])
70
> token.getBalance(web3.eth.accounts[1])
30
```

## 其他

私有链的所有数据都会放在仓库根目录下的`data`目录中，删除这个目录可以清除所有数据，重新启动新环境。

获取关于以太坊的更多信息请访问[EthFans](http://ethfans.org).

