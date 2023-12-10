function sum_series(n)
    x = 0
    for k in 1:n
        x = x + (1/k)^2
    end
    return x
end

# function other_function(n)
#     (...)
# end