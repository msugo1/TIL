from collections import deque


class TrieNode:

    def __init__(self):
        self.children = {}
        self.failure_link = None
        self.output = []
        self.is_terminal = False  # TODO: requirement?


class AhoCorasickTrie:

    def __init__(self, patterns):
        self.root = TrieNode()

        # build trie
        for pattern in patterns:
            node = self.root
            for c in pattern:
                child = node.children.get(c)
                if not child:
                    child = TrieNode()
                    node.children[c] = child

                node = child

            node.output.append(pattern)
            node.is_terminal = True

        # build links
        queue = deque()
        queue.append(self.root)

        while queue:
            # p: 현재 위치, q: 가리키는 노드
            p = queue.popleft()
            for c, q in p.children.items():
                queue.append(q)
                if p == self.root:
                    q.failure_link = self.root
                    continue

                # p가 루트가 아니면, p의 실패링크(pf)에서 q와 같은 문자로 이어지는 노드(r)가 있는지 확인한다.
                # 그런 r이 존재한다면 q의 실패링크는 r을 가리키고,
                # 그런 r이 존재하지 않는다면, p에 pf를 대입하고 다시 과정을 반복한다.
                link_node = p.failure_link
                while link_node and c not in link_node.children:
                    link_node = link_node.failure_link

                if link_node is None:
                    q.failure_link = self.root
                else:
                    q.failure_link = link_node.children[c]
                    q.output += q.failure_link.output  # 출력링크 연결

    def search(self, text: str):
        matching_patterns = set()

        node = self.root
        for c in text:
            while node != self.root and c not in node.children:
                node = node.failure_link

            if c in node.children:
                node = node.children[c]

            if node.is_terminal:
                matching_patterns.update(node.output)

        return matching_patterns


trie = AhoCorasickTrie(patterns=["he", "she", "his", "hers"])
print(trie.search("ushers"))

