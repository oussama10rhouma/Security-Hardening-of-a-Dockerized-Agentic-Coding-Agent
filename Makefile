# Convenience wrapper around ./run.sh (works inside WSL).
.DEFAULT_GOAL := all

.PHONY: all preflight build demo table bonus clean cleanall
all:        ; ./run.sh all
preflight:  ; ./run.sh preflight
build:      ; ./run.sh build
demo:       ; ./run.sh demo
table:      ; ./run.sh table
bonus:      ; ./run.sh bonus
clean:      ; ./run.sh clean
cleanall:   ; ./run.sh clean --all
