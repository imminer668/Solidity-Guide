# 第 8 课：数组、结构体与映射

## 1. 本节目标

学完这节课，你能：
- 理解 Solidity 的两种数据结构（数组和结构体）
- 能在合约中声明、创建、访问和修改数组和结构体
- 理解定长数组和变长数组的区别
- 学会结构体的封装用法

## 2. 前置知识

- 第 5 课：理解基本值类型和枚举
- 第 6 课：理解函数的基本结构

## 3. 先讲结论

**当一个变量只能存一个值时，用基本类型（uint256、address）；当需要存一组相关数据时，用数组或结构体。**

- **数组**：适合存"同类型的一批数据"，比如 10 个代币 ID
- **结构体**：适合存"一个事物的多种属性"，比如一个人的姓名、年龄、地址

## 4. 概念解释

### 数组

#### 声明方式

```solidity
// 变长数组（可以随时增减长度）
uint256[] public dynamicArray;

// 定长数组（长度固定，不能超过初始化时的长度）
uint256[5] public fixedArray;

// 初始化定长数组
uint256[3] public numbers = [1, 2, 3];
```

#### 数组常用操作

```solidity
uint256[] public arr = [1, 2, 3];

arr.push(4);        // 末尾添加元素，arr 变成 [1,2,3,4]
arr.pop();          // 移除末尾元素，arr 变回 [1,2,3]
arr.length;         // 长度：3
arr[0];             // 访问第一个元素：1
arr[1] = 99;       // 修改第二个元素：arr 变成 [1,99,3]
```

#### 内存数组的创建

```solidity
function createMemoryArray() external pure returns (uint256[] memory) {
    uint256[] memory memArr = new uint256[](3); // 创建长度 3 的内存数组
    memArr[0] = 10;
    memArr[1] = 20;
    memArr[2] = 30;
    return memArr;
}
```

**注意**：`new uint256[](3)` 创建了一个长度为 3 的内存数组，初始值都是 0。

### 结构体

#### 定义结构体

```solidity
struct Person {
    string name;
    uint256 age;
    address wallet;
}
```

#### 创建结构体实例

```solidity
Person public alice = Person("Alice", 30, 0x123...);

// 或者用命名方式
Person public bob = Person({name: "Bob", age: 25, wallet: 0x456...});
```

#### 修改结构体成员

```solidity
// 直接通过成员修改
alice.age = 31;

// 或者用命名方式
bob.age = 26;
```

#### 结构体数组

```solidity
Person[] public people; // 变长数组，元素类型是 Person

function addPerson(string memory _name, uint256 _age, address _wallet) external {
    people.push(Person(_name, _age, _wallet));
}
```

## 5. 代码拆解

### 综合示例：NFT 收藏品管理

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract NFTCreator {
    // 定义 NFT 结构体
    struct NFT {
        string name;       // NFT 名称
        uint256 tokenId;   // 代币 ID
        address creator;    // 创建者地址
        bool isTransferable; // 是否可转账
    }

    // NFT 数组：存储所有 NFT
    NFT[] public nfts;

    // 添加新 NFT
    function mintNFT(string memory _name, uint256 _tokenId, bool _transferable) external {
        nfts.push(NFT({
            name: _name,
            tokenId: _tokenId,
            creator: msg.sender,
            isTransferable: _transferable
        }));
    }

    // 获取 NFT 总数
    function getNFTCounter() external view returns (uint256) {
        return nfts.length;
    }

    // 根据 tokenId 查找 NFT（通过数组遍历）
    function getNFTByTokenId(uint256 _tokenId) external view returns (NFT memory) {
        for (uint256 i = 0; i < nfts.length; i++) {
            if (nfts[i].tokenId == _tokenId) {
                return nfts[i];
            }
        }
        revert("NFT not found");
    }
}
```

**代码拆解**：
- `struct NFT` — 定义了一个 NFT 数据结构，包含 4 个字段
- `NFT[] public nfts` — 声明一个 NFT 数组（变长）
- `nfts.push(...)` — 往数组末尾添加新 NFT
- `for` 循环遍历数组，找到匹配的 tokenId 后返回

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/08_ArrayAndStruct.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract ArrayAndStruct {
    // ========== 数组 ==========
    uint256[] public dynamicArr;

    // 添加元素
    function pushNumber(uint256 _num) external {
        dynamicArr.push(_num);
    }

    // 获取数组长度
    function getLength() external view returns (uint256) {
        return dynamicArr.length;
    }

    // 删除最后一个元素
    function popNumber() external {
        require(dynamicArr.length > 0, "Array is empty");
        dynamicArr.pop();
    }

    // ========== 结构体 ==========
    struct Student {
        string name;
        uint256 score;
        bool isActive;
    }

    Student[] public students;

    function addStudent(string memory _name, uint256 _score) external {
        students.push(Student(_name, _score, true));
    }

    function getStudent(uint256 _index) external view returns (Student memory) {
        require(_index < students.length, "Index out of bounds");
        return students[_index];
    }

    function updateScore(uint256 _index, uint256 _newScore) external {
        require(_index < students.length, "Index out of bounds");
        students[_index].score = _newScore;
    }
}
EOF
```

### 步骤 2：编译

```bash
forge build
```

### 步骤 3：写测试

```bash
cat > test/08_ArrayAndStruct.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/08_ArrayAndStruct.sol";

contract ArrayAndStructTest is Test {
    ArrayAndStruct public contract_;

    function setUp() public {
        contract_ = new ArrayAndStruct();
    }

    // 数组测试
    function testPushAndGetLength() public {
        contract_.pushNumber(10);
        contract_.pushNumber(20);
        assertEq(contract_.getLength(), 2);
    }

    function testPop() public {
        contract_.pushNumber(10);
        contract_.pushNumber(20);
        contract_.popNumber();
        assertEq(contract_.getLength(), 1);
    }

    // 结构体测试
    function testAddStudent() public {
        contract_.addStudent("Alice", 95);
        (, uint256 score, bool isActive) = contract_.students(0);
        assertEq(score, 95);
        assertEq(isActive, true);
    }

    function testUpdateScore() public {
        contract_.addStudent("Bob", 80);
        contract_.updateScore(0, 99);
        (, uint256 newScore, ) = contract_.students(0);
        assertEq(newScore, 99);
    }
}
EOF
```

### 步骤 4：运行测试

```bash
forge test
```

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 4 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：编译报 `Index access is immutable`

- **常见原因**：试图修改 storage 数组中某个索引的值，但数组是 `public` 的（Solidity 自动为 public 数组生成只读的 getter）
- **解决步骤**：确保修改数组的函数不是只读的，或者使用 storage 指针方式修改
- **验证方式**：`forge test` 通过

### 错误 2：数组越界（Index out of bounds）

- **常见原因**：访问数组时用了超出范围的索引（如 `arr[10]` 但数组只有 3 个元素）
- **解决步骤**：
  1. 访问前先检查 `require(_index < arr.length, "Index out of bounds")`
  2. 或者用 `arr.length` 确认长度后再访问
- **验证方式**：`forge test` 中覆盖边界条件的测试

### 错误 3：修改结构体时整个数组被修改

- **常见原因**：把 storage 数组复制到 memory 后修改 memory，但预期修改 storage
- **解决步骤**：如果需要修改数组元素，用 storage 指针方式访问，不要先复制到 memory
  ```solidity
  function updateScore(uint256 _index, uint256 _newScore) external {
      students[_index].score = _newScore; // 直接修改 storage
  }
  ```
- **验证方式**：`forge test` 确认修改后 storage 值已变

## 9. 本节总结

- 数组适合存"同类型批量数据"，有定长和变长两种
- `push()` 末尾添加，`pop()` 末尾删除，`length` 查长度
- 结构体适合存"一个对象的多种属性"，用 `struct` 定义
- 创建结构体：`Person("Alice", 30, addr)` 或 `Person({name:"Alice", age:30, wallet:addr})`
- public 数组的 getter 是只读的，不能通过 getter 修改数组元素

## 10. 课后练习

### 练习 1
写一个 `ProductStore` 合约：
- 定义 `struct Product { string name; uint256 price; address seller; }`
- `Product[] public products`
- `function addProduct(string memory _name, uint256 _price) external` — 添加商品（自动填 seller = msg.sender）
- `function getProduct(uint256 _index) external view returns (Product memory)` — 获取商品
- `function getProductCount() external view returns (uint256)` — 获取商品总数

### 练习 2
在上面的 `ProductStore` 中添加：
- `mapping(address => uint256[]) public sellerProducts` — 记录每个卖家上架的商品索引列表
- 修改 `addProduct`，同时更新 `sellerProducts[msg.sender]`
- `function getMyProducts() external view returns (Product[] memory)` — 返回当前调用者的所有商品（从 sellerProducts 取出索引，再从 products 取数据）

## 11. 官方参考

- [数组（Arrays）](https://docs.soliditylang.org/en/v0.8.35/types.html#arrays)
- [结构体（Structs）](https://docs.soliditylang.org/en/v0.8.35/types.html#structs)
- [字节数组（Bytes）](https://docs.soliditylang.org/en/v0.8.35/types.html#fixed-size-byte-arrays)