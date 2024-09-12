# two_tag

An implementation of an arbitrarily-bounded
[2-tag system](https://en.wikipedia.org/wiki/Tag_system) in Noir

## Why?

2-tag systems are Turing-complete, i.e. they can simulate any deterministic
program, given sufficient space and time.

## Definition of a tag system

An `m`-tag system is a triplet `(m, A, P)`, where

- `m` is a positive integer, the number of symbols to delete from the FIFO each step
- `A` is a finite alphabet of symbols
    + All finite strings of symbols from `A` are called words.
    + A halting word has `length < m` or begins with the halting symbol
- `P` is a set of production rules
    + A production rule assigns a word P(x) to each symbol x in A.
    + A production on a halting symbol 'H' must be `P(H) = H`

To evaluate an `m`-tag system:
1. Begin with an initial word, considered to be the `Tape`
2. Perform a single step:
    a. Find the production rule `P` for the first symbol on the `Tape` `x`
    b. Delete the first `m` symbols on the tape
    c. Append `P`'s word (`P(x)`) to the `Tape`
3. If the first symbol of the current word is a halting symbol, stop execution,
    otherwise go back to step 2.
4. The final word is considered the output of the system

## Implementation

The core of the implementation is two structs and a single method:

```rust
// A bounded FIFO where we can:
// - Push to the end
// - Pop from the front
// - Know:
//   + Has execution halted?
//   + Has the amount of space ran out?
//
// N is the maximum number of values that can be pushed to the Tape
struct Tape<let N: u32> { .. }

// 2-tag program, i.e. a tag system:
// - The halting symbol is N
// - Symbols > N are no-ops
// - The maximum production length is M
// 
// (N+1), a no-op, can be used to pad rules to length M
struct TagSystem<let N: u32, let M: u32> { .. }

impl<let N: u32, let M: u32> TagSystem<N, M> {
    // Perform one step of simulating a 2-tag system
    fn step<let P: u32>(self, tape: &mut Tape<P>) { .. }
}
```

## Usage

The `main()` function currently implements the Collatz function for `25` steps and with a `Tape` size of `64`.
- You can modify the input by editing [`./Prover.toml`](./Prover.toml)

The following example can be run with `nargo test`:

```rust
#[test]
fn example_two_tag_system() {
    //     Alphabet: {a,b,c,H}
    //     Production rules:
    //          a  -->  ccbaH
    //          b  -->  cca
    //          c  -->  cc
    //
    // Initial word:                     b  a  a
    let mut tape: Tape<32> = Tape::new(&[1, 0, 0]);

    // 'X' is the NULL marker, i.e. N+1
    let tag_system = TagSystem {
        rules: [
    //  a -> c  c  b  a  H
            [2, 2, 1, 0, 3],
    
    //  b -> c  c  a  X  X
            [2, 2, 0, 4, 4],
    
    //  c -> a  a  a  X  X
            [0, 0, 0, 4, 4],
        ],
    };

    // Computation
    //                   100
    //     Initial word: baa
    //                     0220
    //                     acca
    //                       2022103
    //                       caccbaH
    //                         2210322
    //                         ccbaHcc
    //                           1032222
    //                           baHcccc
    //                             32222220
    //                             Hcccccca (halt).
    for _ in 0..25 {
        tag_system.step(&mut tape);
        println(tape.show());
    }

    // The program halted
    assert(tape.running == false);

    // The program didn't halt because it ran out of space
    assert(tape.more_space == true);
}
```

