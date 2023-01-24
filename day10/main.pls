options {
    "--part2" as part2
}

module List = import("../../polaris/lib/list.pls")

let input = !cat (scriptLocal("input.txt"))


let instructions = lines(input)

let run : (List(String), ({ cycle : Number, registerX : Number } -> Bool)) -> ()
let run(instructions, onCycle) = {
    let go(cycle, registerX, instructions) = match instructions {
        [] -> {}
        (instruction :: rest) -> {
            let components = split(" ", instruction)
            match components {
                [ "noop" ] -> {
                    let continue = onCycle({ cycle = cycle, registerX = registerX })
                    if continue then {
                        go(cycle + 1, registerX, rest)
                    } else {}
                }
                [ "addx", amount ] -> {
                    let amount = parseInt(amount)
                    let continue1 = onCycle({ cycle = cycle, registerX = registerX })
                    let continue2 = onCycle({ cycle = cycle + 1, registerX = registerX })

                    if continue1 && continue2 then {
                        # registerX is incremented *after* two cycles
                        go(cycle + 2, registerX + amount, rest)
                    } else {}
                }
            }
        }
    }
    go(1, 1, instructions)

}


if not part2 then {
    let sum = 0
    run(instructions, \state -> {
        if List.contains(state.cycle, [20, 60, 100, 140, 180, 220]) then {
            let strength = state.cycle * state.registerX

            print("Cycle " ~ toString(state.cycle) ~ ": " ~ toString(strength))

            sum := sum + strength

            # Stop after the last cycle that we're interested in
            state.cycle != 220
        } else {
            true
        }
    })
    print("Sum: " ~ toString(sum))
} else {

}


