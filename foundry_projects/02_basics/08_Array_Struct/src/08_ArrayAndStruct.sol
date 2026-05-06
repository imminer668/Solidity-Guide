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
