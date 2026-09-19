:- module(desktop, [
              application/1,
              window/1,
              window_app/2,
              window_title/2,
              active_window/2,
              wm/1,
              desktop_running/2
          ]).

:- use_module(core).
:- use_module(provenance).
:- use_module(computing).

:- dynamic application_i/2.
:- dynamic window_i/3.
:- dynamic window_app_i/2.
:- dynamic window_title_i/2.
:- dynamic active_window_i/3.
:- dynamic wm_i/1.
:- dynamic desktop_running_i/2.

application(A) :-
    application_i(A, _).

window(W) :-
    window_i(W, _, _).

window_app(W, App) :-
    window_app_i(W, App).

window_title(W, Title) :-
    window_title_i(W, Title).

active_window(W, Time) :-
    active_window_i(W, Time).

wm(W) :-
    wm_i(W).

desktop_running(App, Time) :-
    desktop_running_i(App, Time).
