from collections import deque


class TrieNode:

    def __init__(self):
        self.children = {}
        self.failure_link = None
        self.output = []
        self.is_terminal = False  # TODO: requirement?


class Trie:

    def __init__(self):
        self.root = TrieNode()

    def insert(self, word):
        node = self.root
        for c in word:
            child = node.children.get(c)
            if not child:
                child = TrieNode()
                node.children[c] = child

            node = child

        node.output.append(word)
        node.is_terminal = True

    def construct_failure_link(self):
        queue = deque()
        queue.append(self.root)

        # p: 현재 위치, q: 가리키는 노드
        while queue:
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


trie = Trie()
trie.insert("ab")
trie.insert("c")
trie.insert("a")
trie.insert("acd")

trie.construct_failure_link()
