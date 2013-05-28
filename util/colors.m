function c = colors(state)

switch state
    case 'awake'
        c = [0 0.4 1];
    case 'anesthetized'
        c = [1 0 0];
end
