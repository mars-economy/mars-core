// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StructuredLinkedList {
    struct Node {
        uint256 dueDate;
        address market;
        uint256 next;
    }

    struct List {
        mapping(uint256 => Node) nodes;
        uint256 size;
    }

    function pushFront(
        List storage self,
        uint256 _date,
        address _market
    ) internal {
        self.size += 1;
        uint256 _count = self.size;
        self.nodes[_count] = Node(_date, _market, self.nodes[0].next);

        self.nodes[0].next = _count;
    }

    function pushSorted(
        List storage self,
        uint256 _date,
        address _market
    ) internal {
        uint256 id;
        uint256 lastId;
        Node memory tmp;

        while (true) {
            lastId = id;
            id = self.nodes[id].next;
            tmp = self.nodes[id];

            if (tmp.dueDate > _date || tmp.next == 0) {
                self.size += 1;
                uint256 _count = self.size;
                self.nodes[_count] = Node(_date, _market, self.nodes[lastId].next);
                self.nodes[lastId].next = _count;

                break;
            }
        }
    }

    function getFirstDate(List storage self) internal view returns (uint256) {
        uint256 id = self.nodes[0].next;
        return self.nodes[id].dueDate;
    }

    function deleteByAddress(List storage self, address _addr) internal {
        uint256 id;
        uint256 lastId;
        Node memory tmp;

        while (true) {
            lastId = id;
            id = self.nodes[id].next;

            if (id == 0) break;

            tmp = self.nodes[id];

            if (tmp.market == _addr) {
                self.size -= 1;

                self.nodes[lastId].next = tmp.next;
                delete self.nodes[id];

                break;
            }
        }
    }
}
