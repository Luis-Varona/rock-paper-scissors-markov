module MarkovModel1
    using ElasticArrays: ElasticMatrix
    using StatsBase: Weights, sample
    
    const MAP = Dict(1 => "rock", 2 => "paper", 3 => "scissors")
    const WINNERS = ((1, 3), (2, 1), (3, 2))
    
    function main()
        history = ElasticMatrix{Int64}(undef, 2, 0)
        weights = ones(Float64, 3, 3, 3, 3)
        counts = zeros(Int64, 3, 3, 3)
        
        round = 0
        play_again = true
        
        while round < 3 && play_again
            round += 1
            computer_move = rand(1:3)
            (player_move, result, play_again) = play_with_user(computer_move)            
            append!(history, [player_move, result])
        end
        
        while play_again
            round += 1
            last_three = history[1, (end - 2):end]
            computer_move = choose_move(weights, last_three)
            (player_move, result, play_again) = play_with_user(computer_move)
            update_data!(history, weights, counts, player_move, result, last_three)
        end
        
        wins = sum(history[2, :] .== 1)
        losses = sum(history[2, :] .== 2)
        ties = round - wins - losses
        
        pct_wins = wins / round * 100
        pct_losses = losses / round * 100
        pct_ties = ties / round * 100
        
        println("\nWe played $round rounds together with the following results:")
        println("- PLAYER WINS: $wins ($pct_wins%)")
        println("- COMPUTER WINS: $losses ($pct_losses%)")
        println("- TIES: $ties ($pct_ties%)")
        println("- COMPUTER WINS / PLAYER WINS: $(losses / wins)")
        println("\nThanks for playing, and come again!")
    end
    
    function choose_move(weights::Array{Float64, 4}, last_three::AbstractVector{Int64})
        W = weights[:, last_three...]
        
        computer_move = if iszero(W)
            rand(1:3)
        else
            sample([2, 3, 1], Weights(W))
        end
        
        return computer_move
    end
    
    function update_data!(
        history::ElasticMatrix{Int64},
        weights::Array{Float64, 4},
        counts::Array{Int64, 3},
        player_move::Int64,
        result::Int64,
        last_three::AbstractVector{Int64},
    )
        append!(history, [player_move, result])
        weights[player_move, last_three...] += 1
        counts[last_three...] += 1
        
        return (history, weights, counts)
    end
    
    function play_with_user(computer_move::Int64)
        println("\nRock, paper, or scissors? (r/p/s)")
        input = lowercase(readline())
        
        while !in(input, ("r", "p", "s"))
            println("Invalid choice. Please enter one of `r`, `p`, or `s`.")
            input = lowercase(readline())
        end
        
        player_move = input == "r" ? 1 : input == "p" ? 2 : 3
        result = 1
        
        if (player_move, computer_move) in WINNERS
            println("\nI picked $(MAP[computer_move]). You win!")
        elseif player_move != computer_move
            println("\nI picked $(MAP[computer_move]). I win!")
            result = 2
        else
            println("\nI picked $(MAP[computer_move]) as well. It's a tie!")
            result = 3
        end
        
        println("Would you like to play again? (y/n)")
        play_again = lowercase(readline())
        
        while !in(play_again, ("y", "n"))
            println("Invalid choice. Please enter one of `y` or `n`.")
            play_again = lowercase(readline())
        end
        
        return (player_move, result, play_again == "y")
    end
end