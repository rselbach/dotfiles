# BPE Tokenizer Fixes Plan

## Summary
Fix bugs and add improvements to the BPE tokenizer: correct vocab size tracking, byte-level encoding, special tokens, serialization, and performance optimizations.

## Files to Modify
- `internal/tokenizer/bpe.go` - main implementation
- `internal/tokenizer/bpe_test.go` - tests

## Changes

### 1. Special Tokens (IDs 0-3)
Add constants and reserve IDs:
```go
const (
    UnknownToken = "<unk>"  // ID 0
    PadToken     = "<pad>"  // ID 1
    BOSToken     = "<bos>"  // ID 2
    EOSToken     = "<eos>"  // ID 3
)
var SpecialTokens = []string{UnknownToken, PadToken, BOSToken, EOSToken}
```
Update `buildBPE` to start regular tokens at ID 4.

### 2. Byte-Level Encoding (GPT-2 Style)
Replace `initialSymbols` rune-based splitting with byte-based:
- Base vocab: 256 byte tokens (0x00-0xFF represented as single-byte strings)
- `initialSymbols(word)` → split into bytes, append `</w>`
- Guarantees any input is encodable without `<unk>` (except for actual unknown merged tokens during encode)

### 3. Fix Vocab Size Bug (line 97)
Current: `initialVocabSize + len(merges) + 1 >= maxVocabSize`
Problem: merges don't simply add tokens; constituent tokens may disappear

Fix: track actual vocab size by counting unique symbols across all words after each merge:
```go
currentVocabSize := len(tallyTokenFrequency(wordSymbols, wordFreq)) + len(SpecialTokens)
if maxVocabSize > 0 && currentVocabSize >= maxVocabSize {
    break
}
```

### 4. Fix Decode Unknown ID Handling (line 165)
Change from silently skipping to emitting `<unk>`:
```go
token, ok := b.IDToToken[id]
if !ok {
    sb.WriteString(UnknownToken)
    continue
}
```

### 5. Serialization (JSON + Gob)
Add methods to `BPE`:
```go
func (b *BPE) SaveJSON(w io.Writer) error
func LoadJSON(r io.Reader) (*BPE, error)
func (b *BPE) SaveGob(w io.Writer) error
func LoadGob(r io.Reader) (*BPE, error)
```
New file: `internal/tokenizer/serialize.go`

### 6. Performance: Incremental Pair Counts
Instead of rebuilding `countPairs` each iteration:
- Maintain `pairCounts map[SymbolPair]int` across iterations
- After merge: for each word containing the merged pair:
  - Decrement counts for pairs destroyed (left-of-merge + left, right + right-of-merge)
  - Increment counts for new pairs formed (left-of-merge + merged, merged + right-of-merge)
- Use `container/heap` for O(log n) max extraction instead of O(n) scan

### 7. Performance: Faster Encode
Build merge lookup during training:
```go
type BPE struct {
    // ... existing fields
    mergeRank map[SymbolPair]int  // pair -> priority (lower = merge first)
}
```
Encode algorithm:
- Split word into bytes
- Repeatedly find lowest-rank adjacent pair and merge
- Stop when no mergeable pairs remain
- O(n log n) per word instead of O(merges × n)

### 8. Documentation
- Add doc comment noting `BPE` is safe for concurrent `Encode`/`Decode`
- Export `EndOfWordToken` constant

## Implementation Order
1. Special tokens (foundation for other changes)
2. Byte-level encoding
3. Vocab size fix
4. Decode unknown ID fix
5. Performance: incremental pair counts + heap
6. Performance: faster encode with merge ranks
7. Serialization (new file: serialize.go)
8. Tests for all new behaviour

## Questions Resolved
- Byte handling: GPT-2 style (256 byte base vocab)
- Special tokens: <unk>, <pad>, <bos>, <eos> at IDs 0-3
- Serialization: both JSON and Gob
