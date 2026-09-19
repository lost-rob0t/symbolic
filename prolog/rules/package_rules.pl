:- module(package_rules, []).

:- use_module('../../ontology/core').
:- use_module('../../ontology/provenance').
:- use_module('../../ontology/computing').
:- use_module('../../ontology/filesystem').

:- declare_rule(owning_package_rule,
                owning_package(Path, Package),
                package_owns(Package, Path)).

:- declare_rule(exe_owner_rule,
                exe_owner(ExeName, Package),
                (   package_owns(Package, Path),
                    file_base_name(Path, ExeName)
                )).

:- declare_rule(package_recently_changed_rule,
                package_recently_changed(Package, Within, Now),
                (   package_version(Package, _, Installed),
                    time_before(Installed, Now),
                    interval_duration(interval(Installed, Now), D),
                    D =< Within
                )).
