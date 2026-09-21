:- module(embeddings, [
              tokenize/2,
              token_sign/2,
              token_dim/2,
              embed_text/2,
              cosine/3,
              embedding_dim/1,
              embed_norm_sq/2
          ]).

:- use_module(library(lists)).
:- use_module(library(pairs)).
:- use_module(library(sha)).

embedding_dim(256).

tokenize(Text, Tokens) :-
    atom(Text),
    atom_chars(Text, Chars),
    tokenize_chars(Chars, Rev),
    reverse(Rev, Tokens).

tokenize_chars([], []).
tokenize_chars([C|Cs], Out) :-
    (   char_type(C, alnum)
    ->  take_word([C|Cs], WordChars, Rest),
        (   WordChars == []
        ->  Out = Out0
        ;   atom_chars(WA, WordChars),
            downcase_atom(WA, W),
            Out = [W|Out0]
        ),
        tokenize_chars(Rest, Out0)
    ;   tokenize_chars(Cs, Out)
    ).

take_word([], [], []).
take_word([C|Cs], [], [C|Cs]) :-
    \+ char_type(C, alnum),
    !.
take_word([C|Cs], [C|W], Rest) :-
    take_word(Cs, W, Rest).

token_hash(Token, B0-B1) :-
    atom(Token),
    sha_hash(Token, [B0,B1|_], [algorithm(sha1)]).

token_dim(Token, Dim) :-
    token_hash(Token, _-Dim).

token_sign(Token, Sign) :-
    token_hash(Token, B0-_),
    Bit is B0 mod 2,
    (   Bit =:= 0
    ->  Sign = 1
    ;   Sign = -1
    ).

embed_text(Text, Emb) :-
    tokenize(Text, Tokens),
    Tokens \= [],
    findall(D-Sign,
            (   member(T, Tokens),
                token_dim(T, D),
                token_sign(T, Sign)
            ),
            DS),
    keysort(DS, DSorted),
    group_pairs_by_key(DSorted, Grouped),
    findall(D-W,
            (   member(D-Signs, Grouped),
                sum_list(Signs, W)
            ),
            Raw),
    normalize(Raw, Emb).

normalize(Pairs, Emb) :-
    map_pairs_to_weights(Pairs, Ws),
    sum_squares(Ws, 0, SumSq),
    (   SumSq =:= 0
    ->  Emb = []
    ;   Norm is sqrt(SumSq),
        scale(Pairs, Norm, Emb)
    ).

map_pairs_to_weights([], []).
map_pairs_to_weights([_-W|Ps], [W|Ws]) :-
    map_pairs_to_weights(Ps, Ws).

sum_squares([], S, S).
sum_squares([W|Ws], Acc, S) :-
    Acc1 is Acc + W * W,
    sum_squares(Ws, Acc1, S).

scale([], _, []).
scale([D-W|Ps], Norm, [D-WN|Out]) :-
    WN is W / Norm,
    scale(Ps, Norm, Out).

cosine(V1, V2, Sim) :-
    dot(V1, V2, Dot),
    norm_of(V1, N1),
    norm_of(V2, N2),
    (   N1 > 0,
        N2 > 0
    ->  Sim is Dot / (N1 * N2)
    ;   Sim = 0
    ).

embed_norm_sq(Emb, Sq) :-
    map_pairs_to_weights(Emb, Ws),
    sum_squares(Ws, 0, Sq).

dot([], _, 0) :-
    !.
dot(_, [], 0) :-
    !.
dot([D1-W1|T1], [D2-W2|T2], Dot) :-
    (   D1 < D2
    ->  dot(T1, [D2-W2|T2], Dot)
    ;   D1 > D2
    ->  dot([D1-W1|T1], T2, Dot)
    ;   dot(T1, T2, Rest),
        Dot is W1 * W2 + Rest
    ).

norm_of([], 0).
norm_of(Pairs, N) :-
    map_pairs_to_weights(Pairs, Ws),
    sum_squares(Ws, 0, S),
    N is sqrt(S).
