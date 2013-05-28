function c = colors(state)

switch state
    case 'awake'
        c = [1 0 0];
    case 'anesthetized'
        c = [0 0.4 1];
end
