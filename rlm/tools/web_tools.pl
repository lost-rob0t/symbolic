:- module(web_tools, [
              brave_search/2,
              web_fetch/2,
              wikipedia_summary/2,
              wikipedia_search/2
          ]).

:- use_module(library(http/http_open)).
:- use_module(library(http/json)).
:- use_module(library(process)).
:- use_module(library(lists)).
:- use_module(library(uri)).

brave_search(Query, Text) :-
    setup_call_cleanup(
        process_create(path(bx),
                       [context, Query, '--max-tokens', '2048'],
                       [stdout(pipe(Out)), stderr(null), process(Pid)]),
        read_string(Out, _, Text0),
        ( close(Out),
          process_wait(Pid, _Status)
        )),
    atom_string(Text, Text0).

web_fetch(URL, Text) :-
    setup_call_cleanup(
        http_open(URL, Stream,
                  [timeout(20), max_redirections(3),
                   request_header('User-Agent'='Symbolic-KB/0.1 (local-first KB)')]),
        http_text(Stream, Text),
        close(Stream)).

http_text(Stream, Text) :-
    read_string(Stream, 262144, Text0),
    (   at_end_of_stream(Stream)
    ->  Text = Text0
    ;   read_string(Stream, 262144, More),
        string_concat(Text0, More, Text)
    ).

wikipedia_summary(Title, Summary) :-
    uri_encoded(segment, Title, Encoded),
    format(atom(URL),
           'https://en.wikipedia.org/api/rest_v1/page/summary/~w',
           [Encoded]),
    web_fetch(URL, Text),
    open_string(Text, S),
    json_read_dict(S, Dict, [end_of_file(eof)]),
    close(S),
    (   get_dict(type, Dict, disambiguation)
    ->  Summary = disambiguation(Dict)
    ;   Summary = Dict
    ).

wikipedia_search(Query, Results) :-
    uri_encoded(query_value, Query, Encoded),
    format(atom(URL),
           'https://en.wikipedia.org/w/api.php?action=query&list=search&format=json&srlimit=5&srsearch=~w',
           [Encoded]),
    web_fetch(URL, Text),
    open_string(Text, S),
    json_read_dict(S, Dict, [end_of_file(eof)]),
    close(S),
    get_dict(query, Dict, Q),
    get_dict(search, Q, Results).
