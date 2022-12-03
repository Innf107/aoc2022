# These definitions are part of the standard library, but the module system
# is kind of broken since I introduced types, so we need to redefine them here
let foldr(f, z, list) = match list {
    [] -> z
    (x : xs) -> f(x, foldr(f, z, xs))
}

let map(f, list) = foldr(\x r -> cons(f(x), r), [], list)

let max(x, y) = if x >= y then x else y

let maximum1(list) = match list {
    [] -> fail("maximum1 called on an empty list")
    [x] -> x
    (x : xs) -> max(x, maximum1(xs))
}

let sum(list) = foldr(\x y -> x + y, 0, list)


let inputs = lines(!cat "input.txt")


let groups = {
    let go(list, current) = match list {
        [] -> []
        (x : xs) -> 
            # I really need to implement string patterns
            if x == "" then
                # Same for a (:) operator for cons (this one should be really easy, I just need to do it!)
                cons(current, go(xs, []))
            else 
                go(xs, cons(x, current))
    }
    go(inputs, [])
}
let inputSums = map(\xs -> sum(map(parseInt, xs)), groups)

print(maximum1(inputSums))


