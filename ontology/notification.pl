:- module(notification, [
              notification/1,
              notification_app/2,
              notification_title/2,
              notification_body/2,
              notification_arrived/2,
              notification_urgency/2,
              notification_redacted/1
          ]).

:- use_module(core).
:- use_module(provenance).

:- dynamic notification_i/2.
:- dynamic notification_app_i/2.
:- dynamic notification_title_i/2.
:- dynamic notification_body_i/2.
:- dynamic notification_arrived_i/2.
:- dynamic notification_urgency_i/2.
:- dynamic notification_redacted_i/1.

notification(N) :-
    notification_i(N, _).

notification_app(N, App) :-
    notification_app_i(N, App).

notification_title(N, T) :-
    notification_title_i(N, T).

notification_body(N, B) :-
    notification_body_i(N, B).

notification_arrived(N, T) :-
    notification_arrived_i(N, T).

notification_urgency(N, U) :-
    notification_urgency_i(N, U).

notification_redacted(N) :-
    notification_redacted_i(N).
