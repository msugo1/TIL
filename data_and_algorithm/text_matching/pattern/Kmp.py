def create_kmp_table(string):
    i = 1
    j = 0

    pi = [0 for _ in range(len(string))]
    while i < len(string):
        if string[i] == string[j]:
            pi[i] = j + 1
            i = i + 1
            j = j + 1
        elif j > 0:
            j = pi[j - 1]
        else:
            pi[i] = 0
            i = i + 1

    return pi


def kmp(text, pattern):
    matching_start_indice = []
    kmp_table = create_kmp_table(pattern)

    i = 0
    j = 0
    while i < len(text):
        if text[i] == pattern[j]:
            if len(pattern) - 1 == j:
                matching_start_indice.append(i - j)
                i += 1
                j = 0
            else:
                i += 1
                j += 1
        elif j > 0:
            j = kmp_table[j - 1]
        else:
            i += 1

    return matching_start_indice
