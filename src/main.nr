
/// A bounded FIFO where we can:
/// - Push to the end
/// - Pop from the front
/// - Know:
///   + Has execution halted?
///   + Has the amount of space ran out?
///
/// N is the maximum number of values that can be pushed to the Tape
struct Tape<let N: u32> {
    inner: [Field; N],
    start_position: u32, // first valid position
    end_position: u32,   // last valid position
    running: bool,       // running or halted?
    more_space: bool,    // did we run out of tape?
}

impl<let N: u32> Tape<N> {
    /// Initial_tape must be non-empty
    fn new(initial_tape: [Field]) -> Self {
        assert(initial_tape.len() != 0);
        let mut inner = [0; N];
        let mut i = 0;
        for x in initial_tape {
            inner[i] = x;
            i += 1;
        }
        Self {
            inner,
            start_position: 0,
            end_position: initial_tape.len() - 1,
            running: true,
            more_space: true,
        }
    }

    /// Show the Tape for printing
    fn show(self) -> str<N> {
        let mut output: [u8; N] = [32; N]; // all spaces
        let mut i = 0;
        let mut o = 0;
        for x in self.inner {
            if (self.start_position <= i) & (i <= self.end_position) {
                output[o] = (x as u8) + 97;
                o += 1;
            }
            i += 1;
        }
        From::from(output)
    }

    /// Get the next 2 value or set to not running
    fn get_2(&mut self) -> Option<(Field, Field)> {
        let i = self.start_position;
        if i + 1 <= self.end_position {
            self.start_position += 2;
            Option::some((self.inner[i], self.inner[i+1]))
        } else {
            self.running = false;
            Option::none()
        }
    }

    /// Push a Field onto the Tape
    ///
    /// Returns [successful]
    fn push(&mut self, x: Field) -> bool {
        if self.end_position + 1 >= N {
            false
        } else {
            self.end_position += 1;
            self.inner[self.end_position] = x;
            true
        }
    }

    /// Append xs to self until end_marker is reached
    fn append<let M: u32>(&mut self, xs: [Field; M], end_marker: Field) {
        let mut running = true;
        for x in xs {
            if running {
                if x == end_marker {
                    running = false;
                } else {
                    // stop running and no more_space if push fails
                    running = self.push(x);
                    self.more_space = running;
                }
            }
        }
    }
}

/// 2-tag program, i.e. a tag system:
/// - The halting symbol is N
/// - Symbols > N are no-ops
/// - The maximum production length is M
///
/// (N+1), a no-op, can be used to pad rules to length M
struct TagSystem<let N: u32, let M: u32> {
    rules: [[Field; M]; N],
}

impl<let N: u32, let M: u32> TagSystem<N, M> {
    /// Perform one step of simulating a 2-tag system
    fn step<let P: u32>(self, tape: &mut Tape<P>) {
        let opt_xy = tape.get_2();
        if tape.running {
            let (x, _y) = opt_xy.unwrap_unchecked();
            if (x as u32) == N {
                tape.running = false;
            } else {
                tape.append(self.rules[x], (N+1) as Field);
            }
        }
    }

    /// Perform self.step(tape) num_steps times
    fn steps<let P: u32>(self, tape: &mut Tape<P>, num_steps: u32) {
        for _ in 0..num_steps {
            self.step(tape)
        }
    }
}

/// Simulate the Collatz conjecture on a Tape of size 64 for 57 (== 25 + 32) steps
///
/// Only use the first `elements_to_keep` values from the initial_tape_array
fn main(initial_tape_array: [Field; 64], elements_to_keep: u32) {
    // We represent symbols by their 0-indexed position in the alphabet:
    // a -> 0
    // b -> 1
    // ..
    //
    // Or by 
    //
    // Collatz Conjecture
    // https://en.wikipedia.org/wiki/Tag_system#Example:_Computation_of_Collatz_sequences
    //
    // a  -->  bc
    // b  -->  a
    // c  -->  aaa
    // 
    // Computation
    //     Initial word: aaa <--> n=3
    //                     abc 
    //                       c..
    //
    //                                      a  a  a
    // let mut tape: Tape<64> = Tape::new(&[0, 0, 0]);

    println("Simulating with a Tape of size 64..");
    assert(elements_to_keep <= 64, "main(): too many elements to keep");
    let mut tape = Tape {
        inner: initial_tape_array,
        start_position: 0,
        end_position: elements_to_keep - 1,
        running: true,
        more_space: true,
    };

    // 'X' is the NULL marker, i.e. N+1
    let tag_system = TagSystem {
        rules: [
    //  a -> b  c  X
            [1, 2, 4],

    //  b -> a  X  X
            [0, 4, 4],

    //  c -> a  a  a
            [0, 0, 0],
        ],
    };

    println("Simulating 25 steps..");
    for _ in 0..25 {
        tag_system.step(&mut tape);
        println(tape.show());
    }

    println(".. 32 steps later ..");
    tag_system.steps(&mut tape, 32);
    println(tape.show());
    println("");

    if !tape.more_space {
        println("Ran out of tape!");
    } else {
        println("Leftover space in tape:");
        println(tape.inner.len() - tape.start_position);
    }
    println("");

    if tape.running {
        println("Still running..");
    } else {
        println("Halted.");
    }
}

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

