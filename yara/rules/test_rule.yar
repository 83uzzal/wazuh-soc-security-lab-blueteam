rule TestRule {
    strings:
        $a = "test file"
    condition:
        $a
}
