let fail ppf = Fmt.(pf ppf "%a" (styled `Red string))

let pass ppf = Fmt.(pf ppf "%a" (styled `Green string))
