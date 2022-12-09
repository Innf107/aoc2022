#!/usr/bin/env polaris

# This is *untyped* polaris, since typed polaris cannot represent sum types yet :/

let Set(lessThan) = {
    let empty = null

    let insertSet(value, set) = {
        if set == empty then
            #{ left: empty, value: value, right: empty }
        else if value == set.value then
            set
        else if lessThan(value, set.value) then
            #{ left: insertSet(value, set.left)
             , value: set.value
             , right: set.right    
             }
        else
            #{ left: set.left
             , value: set.value
             , right: insertSet(value, set.right)
             }
    }

    let contains(key, set) = {
        if set == empty then
            false
        else if key == set.value then
            true
        else if lessThan(key, set.value) then
            contains(key, set.left)
        else
            contains(key, set.right)
    }

    let size(set) = {
        if set == empty then 
            0
        else
            size(set.left) + 1 + size(set.right)
    }

    #{ empty: empty 
     , insert: insertSet
     , contains: contains 
     , size: size
     }
}

let iterateN(n, initial, f) = match n {
    0 -> initial
    n -> iterateN(n - 1, f(initial), f)
}

let PointSet = Set(\(pos1, pos2) -> pos1.x < pos2.x || (pos1.x == pos2.x && pos1.y < pos2.y))

let parseMovement() = {
    let line = readLine()

    if line == null then
        null
    else {

        let [direction, amountString] = split(" ", line)

        let amount = parseInt(amountString)

        let movement = if direction == "U" then
                #{ x: 0, y: 1 }
            else if direction == "D" then
                #{ x: 0, y: -1 }
            else if direction == "R" then
                #{ x: 1, y: 0 }
            else if direction == "L" then
                #{ x: -1, y: 0 }
            else
                fail("Invalid direction: " ~ direction)
    
        [movement, amount]
    }
}


let abs(x) = if x < 0 then 0 - x else x

let solve(state) = {
    let movement = parseMovement()
    if movement == null then
        state
    else {
        let [direction, amount] = movement

        let step(state) = {

            let newHeadPos = #{
                x: state.headPos.x + direction.x
            ,   y: state.headPos.y + direction.y
            }

            let newTailPos = {
                let difference = #{
                    x: newHeadPos.x - state.tailPos.x
                ,   y: newHeadPos.y - state.tailPos.y
                }
                print(state.headPos, state.tailPos, direction, difference)
                if abs(difference.x) == 2 then
                    #{ x: state.tailPos.x + (difference.x / 2)
                     , y: state.tailPos.y + difference.y
                     }
                else if abs(difference.y) == 2 then
                    #{ x: state.tailPos.x + difference.x
                     , y: state.tailPos.y + (difference.y / 2)
                     }
                else
                    state.tailPos
            }
        
            #{ visited: PointSet.insert(newTailPos, state.visited)
             , headPos: newHeadPos
             , tailPos: newTailPos
             }
        }

        let resultingState = iterateN(amount, state, step)
        solve(resultingState)
    }
}

let result = solve(#{
    visited: PointSet.empty
,   headPos: #{ x: 0, y: 0 }
,   tailPos: #{ x: 0, y: 0 }
})

print(PointSet.size(result.visited))

